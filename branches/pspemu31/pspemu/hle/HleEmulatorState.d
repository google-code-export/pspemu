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

class HleEmulatorState : ISyscall {
	public EmulatorState   emulatorState;
	//public MemoryPartition memoryPartition;
	public ModuleManager   moduleManager;
	public ModuleLoader    moduleLoader;
	public UniqueIdFactory uniqueIdFactory;
	public Syscall         syscallObject;
	public MemoryManager   memoryManager;
	
	public this(EmulatorState emulatorState) {
		this.emulatorState   = emulatorState;
		//this.memoryPartition = new MemoryPartition(Memory.Segments.mainMemory.low, Memory.Segments.mainMemory.high);
		this.moduleManager   = new ModuleManager(this);
		this.memoryManager   = new MemoryManager(this.emulatorState.memory, this.moduleManager);
		this.moduleLoader    = new ModuleLoader(this.emulatorState.memory, this.memoryManager, this.moduleManager);
		this.uniqueIdFactory = new UniqueIdFactory();
		this.syscallObject   = new Syscall(this);
		
		this.emulatorState.syscall = this;
	}

	public ThreadState currentThreadState() {
		throw(new Exception("Not implemented"));
	}

	public void syscall(CpuThreadBase cpuThread, int syscallNum) {
		this.syscallObject.syscall(cpuThread, syscallNum);
	}
}
