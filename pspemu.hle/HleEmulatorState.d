module pspemu.hle.HleEmulatorState;

import std.stdio;
import std.conv;
import std.random;

import pspemu.core.EmulatorState;
import pspemu.core.ThreadState;
import pspemu.core.Memory;

import pspemu.core.exceptions.HaltException;

import pspemu.core.cpu.ISyscall;
import pspemu.core.cpu.Registers;
import pspemu.core.cpu.CpuBase;

import pspemu.utils.MemoryPartition;
import pspemu.utils.UniqueIdFactory;

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

	public void syscall(CpuBase cpuThread, int syscallNum) {
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
				newCpuThread.executeBefore = delegate() {
					/*
					while (true) {
						writefln("%d", threadState.);
					}
					*/
					writefln("started new thread");
				};
				newCpuThread.run();
				
				set_return_value(0);
				
				//callLibrary("ThreadManForUser", "sceKernelStartThread");
				//throw(new Exception("sceKernelStartThread"));
				
			} break;
			case 0x20bf:
				// int sceKernelUtilsMt19937Init (SceKernelUtilsMt19937Context *ctx, u32 seed)
				
				void* ctx  = get_argument_ptr!void(0);
				uint  seed = get_argument_int(1);
				
				Mt19937 gen;
				gen.seed(seed);
				*(cast(Mt19937 *)ctx) = gen;
				
			break;
			case 0x20c0:
				Mt19937* ctx  = get_argument_ptr!Mt19937(0);
				set_return_value(ctx.front);
				ctx.popFront();
				
			
				// u32 sceKernelUtilsMt19937UInt (SceKernelUtilsMt19937Context *ctx)
				// callLibrary("UtilsForUser",     "sceKernelUtilsMt19937UInt"); break;
			break;
			case 0x213a:
				// int sceDisplaySetMode (int mode, int width, int height)
				//callLibrary("sceDisplay",       "sceDisplaySetMode");
				int mode   = get_argument_int(0);
				int width  = get_argument_int(1);
				int height = get_argument_int(2);
				writefln("sceDisplaySetMode(%d, %d, %d)", get_argument_int(0), get_argument_int(1), get_argument_int(2));
				emulatorState.display.sceDisplaySetMode(mode, width, height);
			break;
			case 0x2147:
				// callLibrary("sceDisplay",       "sceDisplayWaitVblankStart");
				emulatorState.display.vblankStartCondition.wait();
				//writefln("sceDisplayWaitVblankStart");
			break;
			case 0x213f:
				//callLibrary("sceDisplay",       "sceDisplaySetFrameBuf");
				// int sceDisplaySetFrameBuf(void * topaddr, int bufferwidth, int pixelformat, int sync)
				int topaddr      = get_argument_int(0);
				int bufferwidth  = get_argument_int(1);
				int pixelformat  = get_argument_int(2);
				int sync         = get_argument_int(3);
				emulatorState.display.sceDisplaySetFrameBuf(topaddr, bufferwidth, pixelformat, sync);
			break;
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
