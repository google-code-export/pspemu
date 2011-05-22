module pspemu.core.ThreadState;

import core.thread;

import std.stdio;

import pspemu.core.EmulatorState;
import pspemu.core.cpu.Registers;
import pspemu.core.cpu.CpuThreadBase;

import pspemu.hle.kd.Types;
import pspemu.hle.kd.threadman.Types;
import pspemu.hle.Module;

class ThreadState {
	public bool waiting;
	public EmulatorState emulatorState;
	public Registers registers;
	public Thread nativeThread;
	public string name;
	public SceUID thid;
	public SceKernelThreadInfo sceKernelThreadInfo;
	public Module threadModule;
	
	ThreadState clone() {
		ThreadState threadState = new ThreadState(name, emulatorState, new Registers());
		{
			threadState.waiting = waiting;
			threadState.registers.copyFrom(registers);
			threadState.nativeThread = Thread.getThis;
			threadState.thid = -1;
			threadState.threadModule = threadModule;
			threadState.sceKernelThreadInfo = sceKernelThreadInfo;
		}
		return threadState;
	}
	
	public void waitingBlock(void delegate() callback) {
		waiting = true;
		try {
			callback();
		} finally {
			waiting = false;
		}
	}
	
	public this(string name, EmulatorState emulatorState, Registers registers) {
		this.name = name;
		this.emulatorState = emulatorState;
		this.registers = registers;
	}

	public this(string name, EmulatorState emulatorState) {
		this(name, emulatorState, new Registers());
	}
	
	string toString() {
		return std.string.format("ThreadState(%d:'%s', PC:%08X)", thid, name, registers.PC);
	}
}