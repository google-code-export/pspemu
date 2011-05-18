module pspemu.core.ThreadState;

import core.thread;

import std.stdio;

import pspemu.core.EmulatorState;
import pspemu.core.cpu.Registers;
import pspemu.core.cpu.CpuBase;

class ThreadState {
	public EmulatorState emulatorState;
	public Registers registers;
	public Thread nativeThread;
	
	public this(EmulatorState emulatorState, Registers registers) {
		this.emulatorState = emulatorState;
		this.registers = registers;
	}

	public this(EmulatorState emulatorState) {
		this(emulatorState, new Registers());
	}
}