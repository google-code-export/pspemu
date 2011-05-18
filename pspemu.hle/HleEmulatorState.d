module pspemu.hle.HleEmulatorState;

import std.stdio;
import std.conv;
import std.random;
import core.thread;

import pspemu.core.EmulatorState;
import pspemu.core.ThreadState;
import pspemu.core.Memory;

import pspemu.core.exceptions.HaltException;

import pspemu.core.cpu.ISyscall;
import pspemu.core.cpu.Registers;
import pspemu.core.cpu.CpuThreadBase;

import pspemu.utils.MemoryPartition;
import pspemu.utils.UniqueIdFactory;

import pspemu.hle.Module;
import pspemu.hle.ModuleNative;
import pspemu.hle.ModuleManager;
import pspemu.hle.ModuleLoader;

class HleEmulatorState : ISyscall {
	public EmulatorState   emulatorState;
	public MemoryPartition memoryPartition;
	public ModuleManager   moduleManager;
	public ModuleLoader    moduleLoader;
	public UniqueIdFactory uniqueIdFactory;
	
	public this(EmulatorState emulatorState) {
		this.emulatorState   = emulatorState;
		this.memoryPartition = new MemoryPartition(Memory.Segments.mainMemory.low, Memory.Segments.mainMemory.high);
		this.moduleManager   = new ModuleManager();
		this.moduleLoader    = new ModuleLoader(this.emulatorState.memory, this.memoryPartition);
		this.uniqueIdFactory = new UniqueIdFactory();
		
		this.emulatorState.syscall = this;
	}
	
	public ThreadState currentThreadState() {
		throw(new Exception("Not implemented"));
	}

	public void syscall(CpuThreadBase cpuThread, int syscallNum) {
		static string szToString(char* s) { return cast(string)s[0..std.c.string.strlen(s)]; }

		void callModuleFunction(Module.Function* moduleFunction) {
			if (moduleFunction is null) throw(new Exception("Syscall.opCall.callModuleFunction: Invalid Module.Function"));
			moduleFunction.func(cpuThread);
		}

		void callLibrary(string libraryName, string functionName) {
			callModuleFunction(moduleManager[libraryName].getFunctionByName(functionName));
		}
		
		auto threadState = cpuThread.threadState;
		auto registers = threadState.registers;
		auto memory = threadState.emulatorState.memory;
		uint get_argument_int(int index) {
			return registers.R[4 + index];
		}
		string get_argument_str(int index) {
			return to!string(cast(char *)memory.getPointerOrNull(get_argument_int(index)));	
		}
		T* get_argument_ptr(T)(int index) {
			return cast(T *)memory.getPointerOrNull(get_argument_int(index));
		}
		void set_return_value(uint value) {
			registers.V0 = value;
		}
		
		//writefln("syscall(%08X)", syscallNum);
		
		switch (syscallNum) {
			case 0x206d: {
				// SceUID sceKernelCreateThread (const char *name, SceKernelThreadEntry entry, int initPriority, int stackSize, SceUInt attr, SceKernelThreadOptParam *option)
				
				string name         = get_argument_str(0);
				//void*  entry        = get_argument_ptr!void(1);
				uint   entry        = get_argument_int(1);
				int    initPriority = get_argument_int(2);
				int    stackSize    = get_argument_int(3);
				int    attr         = get_argument_int(4);
				void*  option       = get_argument_ptr!void(5);

				auto newThreadState = new ThreadState(emulatorState, new Registers());
				newThreadState.registers.copyFrom(registers);
				newThreadState.registers.pcSet = entry;
				
				set_return_value(uniqueIdFactory.add("thread", newThreadState));
				
				//writefln("%s", );
				//uint threadUid = uniqueIdFactory.newUid("thread");
				//registers
				

				//callLibrary("ThreadManForUser", "sceKernelCreateThread");
				
			} break;
			case 0x206f: {
				// int sceKernelStartThread(SceUID thid, SceSize arglen, void * argp);
				UID  thid   = get_argument_int(0);
				uint arglen = get_argument_int(1);
				uint argp   = get_argument_int(2);
				
				auto newThreadState = uniqueIdFactory.get!(ThreadState)("thread", thid);
				
				newThreadState.registers.A0 = arglen;
				newThreadState.registers.A1 = argp;
				
				auto newCpuThread = cpuThread.createCpuThread(newThreadState);
				/*
				newCpuThread.executeBefore = delegate() {
					writefln("started new thread");
				};
				*/
				
				newCpuThread.start();

				// newCpuThread could access parent's stack because it has some cycles at the start.
				newCpuThread.thisThreadWaitCyclesAtLeast(100);
				
				set_return_value(0);
				
				//callLibrary("ThreadManForUser", "sceKernelStartThread");
				//throw(new Exception("sceKernelStartThread"));
				
			} break;
			case 0x20bf: callLibrary("UtilsForUser",     "sceKernelUtilsMt19937Init"); break;
			case 0x20c0: callLibrary("UtilsForUser",     "sceKernelUtilsMt19937UInt"); break;
			case 0x2147: callLibrary("sceDisplay",       "sceDisplayWaitVblankStart"); break;
			case 0x213a: callLibrary("sceDisplay",       "sceDisplaySetMode"); break; 
			case 0x213f: callLibrary("sceDisplay",       "sceDisplaySetFrameBuf"); break;
			case 0x2150:
				//callLibrary("sceCtrl", "sceCtrlPeekBufferPositive");
				
				set_return_value(+1);
			break;
			case 0x2071:
				// callLibrary("ThreadManForUser", "sceKernelExitThread");
				throw(new HaltException("ThreadManForUser.sceKernelExitThread"));
				
			break;
			default:
				writefln("syscall(%08X)", syscallNum);
				throw(new Exception("Unknown syscall"));
			break;
		}
	}
}
