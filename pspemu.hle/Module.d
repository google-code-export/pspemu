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

import pspemu.hle.HleEmulatorState;

static string classInfoBaseName(ClassInfo ci) {
	auto index = ci.name.lastIndexOf('.');
	if (index == -1) index = 0; else index++;
	return ci.name[index..$];
	//return std.string.split(ci.name, ".")[$ - 1];
}

abstract class Module {
	public HleEmulatorState hleEmulatorState;
	
	static public CpuThreadBase currentCpuThread() {
		return thisThreadCpuThreadBase;
	}

	static public ThreadState currentThreadState() {
		return currentCpuThread.threadState;
	}
	
	static public EmulatorState currentEmulatorState() {
		return currentThreadState.emulatorState;
	}

	static public Registers currentRegisters() {
		return currentThreadState.registers;
	}
	
	static public void writefln(T...)(T args) {
		.writefln("PC(0x%08X) :: %s ::%s", currentRegisters.PC, Thread.getThis.name, std.string.format(args));
	}

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
			writefln("Error initializing module: '%s'", o);
			throw(o);
		}
	}

	abstract void initNids();
	
	void initModule() { }
	void shutdownModule() { }
	
	string baseName() { return classInfoBaseName(typeid(this)); }
	string toString() { return std.string.format("Module(%s)", baseName); }
}
