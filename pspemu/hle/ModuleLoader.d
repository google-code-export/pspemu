module pspemu.hle.ModuleLoader;

//version = ALLOW_UNIMPLEMENTED_NIDS;
//version = LOAD_DWARF_INFORMATION;

import std.stdio;
import std.stream;
import std.file;
import std.path;

import pspemu.formats.elf.Elf;
import pspemu.formats.elf.ElfDwarf;
import pspemu.formats.Pbp;

import pspemu.utils.StructUtils;
import pspemu.utils.StreamUtils;
import pspemu.utils.ExceptionUtils;
import pspemu.utils.Logger;

import pspemu.hle.Module;
import pspemu.hle.ModulePsp;
import pspemu.hle.ModuleManager;
import pspemu.hle.MemoryManager;
import pspemu.hle.Syscall;

import pspemu.core.cpu.Instruction;
import pspemu.core.cpu.InstructionHandler;

import pspemu.hle.kd.loadcore.Types;

import pspemu.hle.HleEmulatorState;

class InstructionCounter : InstructionHandler {
	uint[string] counts;

	void OP_DISPATCH(string name) {
		if (name !in counts) counts[name] = 0;
		counts[name]++;
	}
	
	void count(Stream stream) {
		Instruction instruction;
		while (!stream.eof) {
			stream.read(instruction.v);
			processSingle(instruction);
		}
	}
	
	void dump() {
		writefln("InstructionCounter {");
		foreach (name; counts.keys.sort) {
			writefln("  %s=%d", name, counts[name]);
		}
		writefln("}");
	}
}

class ModuleLoader {
	enum ModuleFlags : ushort {
		User   = 0x0000,
		Kernel = 0x1000,
	}

	enum LibFlags : ushort {
		DirectJump = 0x0001,
		Syscall    = 0x4000,
		SysLib     = 0x8000,
	}

	static struct ModuleExport {
		uint   name;         /// Address to a stringz with the module.
		ushort _version;     ///
		ushort flags;        ///
		byte   entry_size;   ///
		byte   var_count;    ///
		ushort func_count;   ///
		uint   exports;      ///
		
		string toString() {
			return std.string.format(
				"ModuleExport(name=%08X, version=%04X, flags=%04X, entry_size=%02X, var_count=%02X, func_count=%04X, exports=%08X)",
				name, _version, flags, entry_size, var_count, func_count, exports
			);
		}

		// Check the size of the struct.
		static assert(this.sizeof == 16);
	}

	static struct ModuleImport {
		uint   name;           /// Address to a stringz with the module.
		ushort _version;       /// Version of the module?
		ushort flags;          /// Flags for the module.
		byte   entry_size;     /// ???
		byte   var_count;      /// 
		ushort func_count;     /// 
		uint   nidAddress;     /// Address to the nid pointer. (Read)
		uint   callAddress;    /// Address to the function table. (Write 16 bits. jump/syscall)

		// Check the size of the struct.
		static assert(this.sizeof == 20);
	}
	
	static struct ModuleInfo {
		uint flags;         ///
		char[28] name;      /// Name of the module.
		uint gp;            /// Global Pointer initial value.
		uint exportsStart;  ///
		uint exportsEnd;    ///
		uint importsStart;  ///
		uint importsEnd;    ///

		// Check the size of the struct.
		static assert(this.sizeof == 52);
	}

	Stream memoryStream;
	MemoryManager memoryManager;
	ModuleManager moduleManager;
	Elf elf;
	ElfDwarf dwarf;
	ModuleInfo moduleInfo;
	Stream importsStream;
	Stream exportsStream;
	ModuleImport[] moduleImports;
	ModuleExport[] moduleExports;
	ModulePsp modulePsp;
	HleEmulatorState hleEmulatorState;
	
	public this(HleEmulatorState hleEmulatorState) {
		this.hleEmulatorState = hleEmulatorState;
		this.memoryStream  = hleEmulatorState.emulatorState.memory;
		this.memoryManager = hleEmulatorState.memoryManager;
		this.moduleManager = hleEmulatorState.moduleManager;
	}
	
	/*
	public this(Stream memoryStream, MemoryManager memoryManager, ModuleManager moduleManager) {
		this.memoryStream  = memoryStream;
		this.memoryManager = memoryManager;
		this.moduleManager = moduleManager;
	}
	*/
	
	public ModulePsp load(string fullPath) {
		return load(new BufferedFile(fullPath), std.path.basename(fullPath));
	}
	
	public ModulePsp load(Stream stream, string name = "<unknown>") {
		modulePsp = new ModulePsp();
		modulePsp.hleEmulatorState = hleEmulatorState;
		
		while (true) {
			auto magics = new SliceStream(stream, 0, 4);
			auto magic_data = cast(ubyte[])magics.readString(4);
			switch (cast(string)magic_data) {
				case "\x7FELF":
				break;
				case "~PSP":
					throw(new Exception("Not support compressed/encrypted elf files yet"));
				break;
				case "\0PBP":
					stream = (new Pbp(stream))["psp.data"];
					continue;
				break;
				default:
					throw(new Exception(std.string.format("Unknown file type '%s' : [%s]", name, magic_data)));
				break;
			}
			break;
		}
		
		this.elf = new Elf(stream);
		this.elf.allocateMemory(memoryManager);
		this.elf.writeToMemory(memoryStream);

		readInplace(moduleInfo, this.elf.SectionStream(".rodata.sceModuleInfo"));
		
		this.importsStream = getMemorySliceRelocated(moduleInfo.importsStart, moduleInfo.importsEnd);
		this.exportsStream = getMemorySliceRelocated(moduleInfo.exportsStart, moduleInfo.exportsEnd);
		
		Logger.log(Logger.Level.TRACE, "ModuleLoader", "@EXPORTS-START: %08X-%08X", moduleInfo.exportsStart, moduleInfo.exportsEnd);
		
		processImports();
		processExports();
		
		countInstructions();
		
		//memoryManager
		//SceModule
		//this.memoryManager.
		//memoryManager.
		modulePsp.sceModule = cast(SceModule*)memoryManager.memory.getPointer(memoryManager.allocHeap(PspPartition.Kernel0, "ModuleInfo", SceModule.sizeof));
		//modulePsp.sceModule.
		modulePsp.sceModule.modname[0..27] = moduleInfo.name[0..27];
		modulePsp.sceModule.gp_value = moduleInfo.gp;
		modulePsp.sceModule.entry_addr = PC;
		
		return modulePsp;
	}
	
	Syscall.Function[] funcs;
	
	public void processImports() {
		// Load Imports.
		Logger.log(Logger.Level.TRACE, "ModuleLoader", "Imports (0x%08X-0x%08X):", moduleInfo.importsStart, moduleInfo.importsEnd);

		uint[][string] unimplementedNids;
	
		while (!importsStream.eof) {
			auto moduleImport     = read!(ModuleImport)(importsStream);
			//writefln("%08X", moduleImport.name);
			auto moduleImportName = moduleImport.name ? readStringz(memoryStream, moduleImport.name) : "<null>";
			//assert(moduleImport.entry_size == moduleImport.sizeof);
			version (DEBUG_LOADER) {
				writefln("  '%s'", moduleImportName);
				writefln("  {");
			}
			try {
				moduleImports ~= moduleImport;
				auto nidStream  = getMemorySlice(moduleImport.nidAddress , moduleImport.nidAddress  + moduleImport.func_count * 4);
				auto callStream = getMemorySlice(moduleImport.callAddress, moduleImport.callAddress + moduleImport.func_count * 8);
				//writefln("%08X", moduleImport.callAddress);
				
				Module pspModule;
				try {
					pspModule = moduleManager[moduleImportName];
				} catch (Throwable o) {
					writefln("ERROR LOADING MODULE '%s': %s", moduleImportName, o);
				}
				
				if (pspModule is null) {
					writefln("MODULE '%s' NOT FOUND", moduleImportName);
				}
				
				Module.ImportLibrary moduleImportLibrary = modulePsp.addImportLibrary(moduleImportName);
				//moduleImportLibrary
				
				uint stubStartAddr = moduleImport.callAddress;
				uint stubAddr = stubStartAddr; 
				while (!nidStream.eof) {
					uint nid = read!(uint)(nidStream);
					
					moduleImportLibrary.funcImports[nid] = stubAddr;
					
					if ((pspModule !is null) && (nid in pspModule.nids)) {
						Logger.log(Logger.Level.TRACE, "ModuleLoader", "    %s", pspModule.nids[nid]);
						//auto Instruction syscallInstruction;
						callStream.write(cast(uint)(0x0000000C | (0x1000 << 6))); // syscall 0x2307
						callStream.write(cast(uint)cast(void *)&pspModule.nids[nid]);
					} else {
						Logger.log(Logger.Level.TRACE, "ModuleLoader", "    0x%08X:<unimplemented>", nid);
						callStream.write(cast(uint)(0x0000000C | (0x1001 << 6))); // syscall 0x2307
						auto func = new Syscall.Function(delegate(Syscall.Function func) {
							.writefln("trying to call %s", func.info);
						}, std.string.format("'%s':%08X", moduleImportName, nid));
						funcs ~= func;
						callStream.write(cast(uint)cast(void *)func);
						
						Logger.log(Logger.Level.TRACE, "ModuleLoader", "@FUNC: %08X", cast(uint)cast(void *)func);

						//callStream.write(cast(uint)(0x70000000));
						//callStream.write(cast(uint)0);
						unimplementedNids[moduleImportName] ~= nid;
					}
					//writefln("++");
					//writefln("--");
					
					stubAddr += 4;
				}
			} catch (Throwable o) {
				writefln("  ERRROR!: %s", o);
				throw(o);
			}
			version (DEBUG_LOADER) {
				writefln("  }");
			}
		}
	}
	
	public void processExports() {
		// Load Exports.
		while (!exportsStream.eof) {
			ModuleExport moduleExport = read!(ModuleExport)(exportsStream);
			string moduleExportName = moduleExport.name ? readStringz(memoryStream, moduleExport.name) : "<null>";
			
			Module.ExportLibrary moduleExportLibrary = modulePsp.addExportLibrary(moduleExportName);
			Logger.log(Logger.Level.TRACE, "ModuleLoader", "@EXPORT: %s:'%s'", moduleExport, moduleExportName);
			
			uint[] func_nids;
			uint[] var_nids;
			memoryStream.position = moduleExport.exports;
			for (int n = 0; n < moduleExport.func_count; n++) func_nids ~= read!uint(memoryStream);
			for (int n = 0; n < moduleExport.var_count ; n++) var_nids ~= read!uint(memoryStream);
			for (int n = 0; n < moduleExport.func_count; n++) {
				uint nid  = func_nids[n];
				uint addr = read!uint(memoryStream);  
				moduleExportLibrary.funcExports[nid] = addr; 
				Logger.log(Logger.Level.TRACE, "ModuleLoader", "  FUNC:%08X:%08X", nid, addr);
			}
			for (int n = 0; n < moduleExport.var_count ; n++) {
				uint nid  = var_nids[n];
				uint addr = read!uint(memoryStream);  
				moduleExportLibrary.varExports[nid] = addr;
				Logger.log(Logger.Level.TRACE, "ModuleLoader", "  VAR:%08X:%08X", nid, addr);
			}
			
			moduleExports ~= moduleExport;
		}
	}
	
	uint PC() {
		return getRelocatedAddress(elf.header.entryPoint);
	}

	uint GP() {
		return getRelocatedAddress(moduleInfo.gp);
	}
	
	uint getRelocatedAddress(uint addr) {
		if (addr >= elf.relocationAddress) {
			if (elf.relocationAddress > 0) {
				//Logger.log(Logger.Level.WARNING, "Loader", "Trying to get an already relocated address:%08X", addr);
			}
			return addr;
		} else {
			return addr + elf.relocationAddress;
		}
	}
	
	Stream getMemorySlice(uint from, uint to) {
		return new SliceStream(memoryStream, (from), (to));
	}

	Stream getMemorySliceRelocated(uint from, uint to) {
		return new SliceStream(memoryStream, getRelocatedAddress(from), getRelocatedAddress(to));
	}

	void countInstructions() {
		try {
			auto counter = new InstructionCounter;
			counter.count(elf.SectionStream(".text"));
			//counter.dump();
		} catch (Throwable o) {
			.writefln("Can't count instructions: '%s'", o.toString);
		}
	}

	/+
	void loadDwarfInformation() {
		try {
			dwarf = new ElfDwarf;
			dwarf.parseDebugLine(elf.SectionStream(".debug_line"));
			dwarf.find(0x089004C8);
			//executionState.debugSource = this;
			writefln("Loaded debug information");
		} catch (Object o) {
			writefln("Can't find debug information: '%s'", o);
		}
	}
	
	bool lookupDebugSourceLine(ref DebugSourceLine debugSourceLine, uint address) {
		if (dwarf is null) return false;
		auto state = dwarf.find(address);
		if (state is null) return false;
		debugSourceLine.file    = state.file_full_path;
		debugSourceLine.address = state.address;
		debugSourceLine.line    = state.line;
		return true;
	}

	bool lookupDebugSymbol(ref DebugSymbol debugSymbol, uint address) {
		return false;
	}


	+/
}

//public import pspemu.All;
/+
class Loader {
	ExecutionState executionState;
	ModuleManager moduleManager;
	AllegrexAssembler assembler, assemblerExe;
	Memory memory() { return executionState.memory; }

	void allocatePartitionBlock() {
		// Not a Memory supplied.
		if (cast(Memory)this.memory is null) return;

		uint allocateAddress;
		uint allocateSize    = this.elf.requiredBlockSize;
		if (this.elf.relocationAddress) {
			allocateAddress = this.elf.relocationAddress;
		} else {
			allocateAddress = getRelocatedAddress(this.elf.suggestedBlockAddress);
		}

		auto sysMemUserForUser = moduleManager.get!(SysMemUserForUser);
		
		auto blockid = sysMemUserForUser.sceKernelAllocPartitionMemory(2, "Main Program", PspSysMemBlockTypes.PSP_SMEM_Addr, allocateSize, allocateAddress);
		uint blockaddress = sysMemUserForUser.sceKernelGetBlockHeadAddr(blockid);

		Logger.log(Logger.Level.DEBUG, "Loader", "relocationAddress:%08X", this.elf.relocationAddress);
		Logger.log(Logger.Level.DEBUG, "Loader", "suggestedBlockAddress(no reloc):%08X", this.elf.suggestedBlockAddress);
		Logger.log(Logger.Level.DEBUG, "Loader", "allocateAddress:%08X", allocateAddress);
		Logger.log(Logger.Level.DEBUG, "Loader", "allocateSize:%08X", allocateSize);
		Logger.log(Logger.Level.DEBUG, "Loader", "allocatedIn:%08X", blockaddress);
		
		if (this.elf.relocationAddress != 0) {
			this.elf.relocationAddress = blockaddress;
		}
	}

	void load() {
		this.elf.preWriteToMemory(memory);
		{
			allocatePartitionBlock();
		}
		try {
			this.elf.writeToMemory(memory);
		} catch (Object o) {
			Logger.log(Logger.Level.CRITICAL, "Loader", "Failed this.elf.writeToMemory : %s", o);
			throw(o);
		}
		readInplace(moduleInfo, elf.SectionStream(".rodata.sceModuleInfo"));

		auto importsStream = getMemorySliceRelocated(moduleInfo.importsStart, moduleInfo.importsEnd);
		auto exportsStream = getMemorySliceRelocated(moduleInfo.exportsStart, moduleInfo.exportsEnd);
		
	
		
		if (unimplementedNids.length > 0) {
			int count = 0;
			writefln("unimplementedNids {");
			foreach (moduleName, nids; unimplementedNids) {
				writefln("  %s // %s:", moduleName, DPspLibdoc.singleton.getPrxInfo(moduleName));
				foreach (nid; nids) {
					if (auto symbol = DPspLibdoc.singleton.locate(nid, moduleName)) {
						writefln("    mixin(registerd!(0x%08X, %s));", nid, symbol.name);
					} else {
						writefln("    0x%08X:<Not found!>", nid);
					}
				}
				count += nids.length;
			}
			writefln("}");
			//writefln("%s", DPspLibdoc.singleton.prxs);
			version (ALLOW_UNIMPLEMENTED_NIDS) {
			} else {
				throw(new Exception(std.string.format("Several unimplemented NIds. (%d)", count)));
			}
		}

	}

	void setRegisters() {
		auto threadManForUser = moduleManager.get!(ThreadManForUser);

		assembler.assembleBlock(import("KernelUtils.asm"));

		auto thid = threadManForUser.sceKernelCreateThread("Main Thread", PC, 32, 0x8000, 0, null);
		auto pspThread = threadManForUser.getThreadFromId(thid);
		with (pspThread) {
			registers.pcSet = PC;
			registers.GP = GP;

			registers.SP -= 4;
			registers.K0 = registers.SP;
			registers.RA = 0x08000000;
		}

		// Write arguments.
		memory.position = 0x08100000;
		memory.write(cast(uint)(memory.position + 4));
		memory.writeString("ms0:/PSP/GAME/virtual/EBOOT.PBP\0");

		threadManForUser.sceKernelStartThread(thid, 1, memory.getPointerOrNull(0x08100004));
		pspThread.switchToThisThread();

		//cpu.traceStep = true; cpu.checkBreakpoints = true;
		Logger.log(Logger.Level.DEBUG, "Loader", "PC: %08X", executionState.registers.PC);
		Logger.log(Logger.Level.DEBUG, "Loader", "GP: %08X", executionState.registers.GP);
		Logger.log(Logger.Level.DEBUG, "Loader", "SP: %08X", executionState.registers.SP);
	}
}
+/