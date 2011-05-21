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

import pspemu.utils.UniqueIdFactory;

import pspemu.hle.Module;
import pspemu.hle.ModuleNative;
import pspemu.hle.ModuleManager;
import pspemu.hle.MemoryManager;
import pspemu.hle.ModuleLoader;
import pspemu.hle.Syscall;
import pspemu.hle.RootFileSystem;
import pspemu.hle.Callbacks;

import pspemu.core.exceptions.NotImplementedException;

import pspemu.core.cpu.interpreter.CpuThreadInterpreted;

class HleEmulatorState : ISyscall {
	public EmulatorState    emulatorState;
	public ModuleManager    moduleManager;
	public ModuleLoader     moduleLoader;
	public UniqueIdFactory  uniqueIdFactory;
	public Syscall          syscallObject;
	public MemoryManager    memoryManager;
	public RootFileSystem   rootFileSystem;
	public CallbacksHandler callbacksHandler;
	
	public this(EmulatorState emulatorState) {
		this.emulatorState = emulatorState;
		reset();
	}
	
	public void reset() {
		this.moduleManager    = new ModuleManager(this);
		this.memoryManager    = new MemoryManager(this.emulatorState.memory, this.moduleManager);
		this.moduleLoader     = new ModuleLoader(this);
		this.uniqueIdFactory  = new UniqueIdFactory();
		this.syscallObject    = new Syscall(this);
		this.rootFileSystem   = new RootFileSystem(this);
		this.callbacksHandler = new CallbacksHandler(this);
		this.emulatorState.syscall = this;
	}

	public ThreadState currentThreadState() {
		throw(new Exception("Not implemented"));
	}
	
	public uint delegate() createExecuteGuestCode(ThreadState threadState, uint pointer) {
		return delegate() {
			return executeGuestCode(threadState, pointer);
		};
	}
	
	public uint executeGuestCode(ThreadState threadState, uint pointer) {
		//new CpuThreadBase();
		CpuThreadBase tempCpuThread = new CpuThreadInterpreted(threadState);
		
		Registers backRegisters = new Registers();
		backRegisters.copyFrom(tempCpuThread.threadState.registers);

		scope (exit) {
			tempCpuThread.threadState.registers.copyFrom(backRegisters);
		} 

		tempCpuThread.threadState.registers.pcSet = pointer;
		//tempCpuThread.threadState.registers.RA = EmulatorHelper.CODE_PTR_END_CALLBACK;
		tempCpuThread.threadState.registers.RA = 0x08000004;
		//writefln("[1]");
		tempCpuThread.execute(false);
		//writefln("[2]");
		return tempCpuThread.threadState.registers.V0;
	}

	public void syscall(CpuThreadBase cpuThread, int syscallNum) {
		this.syscallObject.syscall(cpuThread, syscallNum);
	}
}
