module pspemu.main;

import pspemu.core.EmulatorState;
import pspemu.utils.Path;

import std.stdio;
import std.stream;

import pspemu.tests.MemoryPartitionTests;

import pspemu.Emulator;

import pspemu.hle.kd.iofilemgr.IoFileMgrForUser;
import pspemu.hle.ModuleNative;

void doUnittest() {
	(new MemoryPartitionTests()).test();
}

unittest {
	doUnittest();
}

int main(string[] args) {
	ApplicationPaths.initialize(args);
	
	try { std.file.mkdirRecurse(ApplicationPaths.exe ~ "/pspfs/flash0/font"); } catch { }
	try { std.file.mkdirRecurse(ApplicationPaths.exe ~ "/pspfs/flash0/kd"); } catch { }
	try { std.file.mkdirRecurse(ApplicationPaths.exe ~ "/pspfs/flash0/vsh"); } catch { }
	try { std.file.mkdirRecurse(ApplicationPaths.exe ~ "/pspfs/flash1"); } catch { }
	try { std.file.mkdirRecurse(ApplicationPaths.exe ~ "/pspfs/ms0/PSP/GAME/virtual"); } catch { }
	try { std.file.mkdirRecurse(ApplicationPaths.exe ~ "/pspfs/ms0/PSP/PHOTO"); } catch { }
	try { std.file.mkdirRecurse(ApplicationPaths.exe ~ "/pspfs/ms0/PSP/SAVEDATA"); } catch { }

	auto emulator = new Emulator();
	auto moduleLoader = emulator.hleEmulatorState.moduleLoader;
	
	uint CODE_PTR_EXIT_THREAD = 0x08000000;
	
	emulator.hleEmulatorState.memoryPartition.allocLow(1024);
	emulator.emulatorState.memory.twrite!uint(CODE_PTR_EXIT_THREAD, 0x0000000C | (0x2071 << 6));
	
	with (emulator.emulatorState) {
		memory.position = 0x08100000;
		memory.write(cast(uint)(memory.position + 4));
		memory.writeString("ms0:/PSP/GAME/virtual/EBOOT.PBP\0");
	}

	//emulator.emulatorState.memory.twrite!uint(CODE_PTR_EXIT_THREAD + 4, CODE_PTR_EXIT_THREAD + 8);
	//emulator.emulatorState.memory.twrite(CODE_PTR_EXIT_THREAD + 8, cast(ubyte[])"ms0:/PSP/GAME/virtual/EBOOT.PBP" ~ '\0');
	

	//moduleLoader.load(r"C:\projects\pspemu31\bin\minifire.elf");
	//moduleLoader.load(r"C:\projects\pspemu31\bin\HelloJpcsp.pbp");
	//moduleLoader.load(r"C:\projects\pspemu31\bin\HelloWorldPSP.pbp");
	//moduleLoader.load(r"C:\projects\pspemu31\bin\ortho.pbp");
	//moduleLoader.load(r"C:\projects\pspemu31\bin\lines.pbp");
	//moduleLoader.load(r"C:\projects\pspemu31\bin\text.elf");
	//moduleLoader.load(r"C:\projects\pspemu31\bin\cube.pbp");
	//moduleLoader.load(r"C:\projects\pspemu31\bin\blend.pbp");
	//moduleLoader.load(r"C:\projects\pspemu31\bin\vfpu_nehe01.pbp");
	//moduleLoader.load(r"C:\projects\pspemu31\bin\vfpu_nehe02.pbp");
	//moduleLoader.load(r"C:\projects\pspemu31\bin\zbufferfog.elf");
	//moduleLoader.load(r"C:\projects\pspemu31\bin\rtctest.pbp");
	//moduleLoader.load(r"C:\projects\pspemu31\tests_ex\fpu\fputest.elf");
	//moduleLoader.load(r"C:\projects\pspemu31\tests_ex\threads\test.elf");
	//moduleLoader.load(r"C:\projects\pspemu31\tests_ex\threads\thread_start.elf");
	//moduleLoader.load(r"tests_ex\string\string.elf");
	//std.file.write("memory.dump", emulator.emulatorState.memory.mainMemory);

	//moduleLoader.load(r"C:\projects\pspemu31\games\cavestory\EBOOT.PBP");
	//moduleLoader.load(r"C:\projects\pspemu31\demos\nehe\vfpu_nehe10.pbp");
	moduleLoader.load(r"C:\projects\pspemu31\demos\nehe\vfpu_nehe06.pbp");
	
	emulator.hleEmulatorState.moduleManager.get!(IoFileMgrForUser)().setVirtualDir(r"C:\projects\pspemu31\demos\nehe");
	
	writefln("ModuleNative.registeredModules:");
	foreach (k, moduleName; ModuleNative.registeredModules) {
		writefln(" :: '%s':'%s'", k, moduleName);
	}
	
	writefln("%08X", moduleLoader.PC);
	//auto stack = emulator.hleEmulatorState.memoryPartition.alloc(0x8000);
	// @HACK:
	auto PC = moduleLoader.PC;
	uint GP = moduleLoader.GP;
	auto SP = emulator.hleEmulatorState.memoryPartition.allocHigh(0x8000, 0x10).high;

	//auto thid = threadManForUser.sceKernelCreateThread("Main Thread", PC, 32, 0x8000, 0, null);
	with (emulator.mainCpuThread) {
		registers.pcSet = PC; 
	
		registers.GP = GP;
	
		registers.SP = SP;
		registers.K0 = registers.SP;
		registers.RA = CODE_PTR_EXIT_THREAD;
		registers.A0 = 1;
		registers.A1 = 0x08100000 + 4;
	}
	
	writefln("GP: %08X", GP);
	writefln("PC: %08X", PC);
	writefln("SP: %08X", SP);

	writefln("%s", emulator.hleEmulatorState.memoryPartition);

	emulator.emulatorState.display.onStop += delegate() {
		//std.file.write("memory.dump", emulator.emulatorState.memory.mainMemory);
	};
	
	emulator.startDisplay();
	emulator.startGpu();
	emulator.startMainThread();
	
	return 0;
}
