module pspemu.hle.Module;

//public import pspemu.All;
debug = DEBUG_SYSCALL;
//debug = DEBUG_ALL_SYSCALLS;

import std.stdio;
import std.string;
import core.thread;

import pspemu.core.cpu.CpuThreadBase;
import pspemu.core.cpu.Registers;
import pspemu.core.ThreadState;
import pspemu.core.EmulatorState;

import pspemu.utils.Logger;

import pspemu.hle.HleEmulatorState;

import pspemu.hle.kd.loadcore.Types;

static string classInfoBaseName(ClassInfo ci) {
	auto index = ci.name.lastIndexOf('.');
	if (index == -1) index = 0; else index++;
	return ci.name[index..$];
	//return std.string.split(ci.name, ".")[$ - 1];
}

abstract class Module {
	public HleEmulatorState hleEmulatorState;

	public SceModule *sceModule;
	
	@property static public CpuThreadBase currentCpuThread() {
		return thisThreadCpuThreadBase;
	}

	@property static public ThreadState currentThreadState() {
		return currentCpuThread.threadState;
	}
	
	@property public EmulatorState currentEmulatorState() {
		//return currentThreadState.emulatorState;
		return hleEmulatorState.emulatorState;
	}

	@property static public Registers currentRegisters() {
		return currentThreadState.registers;
	}
	
	void logInfo(T...)(T args) {
		if (currentThreadState().thid == 5) return;
		try {
			Logger.log(Logger.Level.INFO, this.baseName, "nPC(%08X) :: Thread(%d:%s) :: %s", currentThreadState().registers.RA, currentThreadState().thid, currentThreadState().name, std.string.format(args));
		} catch (Throwable o) {
			Logger.log(Logger.Level.ERROR, "FORMAT_ERROR", "There was an error formating a logInfo");
		}
	}
	
	/*
	static public void writefln(T...)(T args) {
		Logger.log(Logger.Level.TRACE, "Module", std.string.format("PC(0x%08X) :: %s ::%s", currentRegisters.PC, Thread.getThis.name, std.string.format(args)));
	}
	*/

	/*
	public HleEmulatorState currentHleEmulatorState() {
		return currentEmulatorState;
	}
	*/
	
	static struct Function {
		Module pspModule;
		uint nid;
		string name;
		void delegate(CpuThreadBase cpuThread) func;
		string toString() {
			return std.string.format("0x%08X:'%s.%s'", nid, pspModule.baseName, name);
		}
	}
	alias uint Nid;
	Function[Nid] nids;
	Function[string] names;
	bool setReturnValue;
	
	Function* getFunctionByName(string functionName) {
		return functionName in names;
	}
	
	final void init() {
		try {
			initNids();
			initModule();
		} catch (Throwable o) {
			.writefln("Error initializing module: '%s'", o);
			throw(o);
		}
	}

	abstract void initNids();
	
	void initModule() { }
	void shutdownModule() { }
	
	string baseName() { return classInfoBaseName(typeid(this)); }
	string toString() { return std.string.format("Module(%s)", baseName); }
}
