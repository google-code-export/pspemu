module pspemu.hle.Syscall;

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
import pspemu.hle.Syscall;

import pspemu.hle.HleEmulatorState;

class Syscall : ISyscall {
	HleEmulatorState hleEmulatorState;
	
	public this(HleEmulatorState hleEmulatorState) {
		this.hleEmulatorState = hleEmulatorState;
	}
	
	public void syscall(CpuThreadBase cpuThread, int syscallNum) {
		static string szToString(char* s) { return cast(string)s[0..std.c.string.strlen(s)]; }

		void callModuleFunction(Module.Function* moduleFunction, string libraryName, string functionName) {
			if (moduleFunction is null) {
				throw(new Exception(std.string.format("Syscall.opCall.callModuleFunction: Invalid Module.Function (%s::%s)", libraryName, functionName)));
			}
			moduleFunction.func(cpuThread);
		}

		void callLibrary(string libraryName, string functionName) {
			callModuleFunction(
				hleEmulatorState.moduleManager[libraryName].getFunctionByName(functionName),
				libraryName,
				functionName
			);
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
			case 0x206d: callLibrary("ThreadManForUser", "sceKernelCreateThread"); break;
			case 0x206f: callLibrary("ThreadManForUser", "sceKernelStartThread"); break;
			case 0x2071: callLibrary("ThreadManForUser", "sceKernelExitThread"); break;
			case 0x20bf: callLibrary("UtilsForUser",     "sceKernelUtilsMt19937Init"); break;
			case 0x20c0: callLibrary("UtilsForUser",     "sceKernelUtilsMt19937UInt"); break;
			case 0x2147: callLibrary("sceDisplay",       "sceDisplayWaitVblankStart"); break;
			case 0x213a: callLibrary("sceDisplay",       "sceDisplaySetMode"); break; 
			case 0x213f: callLibrary("sceDisplay",       "sceDisplaySetFrameBuf"); break;
			case 0x2150:
				//callLibrary("sceCtrl", "sceCtrlPeekBufferPositive");
				
				set_return_value(+1);
			break;
			default:
				writefln("syscall(%08X)", syscallNum);
				throw(new Exception("Unknown syscall"));
			break;
		}
	}
}