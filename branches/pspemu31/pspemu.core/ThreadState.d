module pspemu.core.ThreadState;

import core.thread;

import std.stdio;

import pspemu.core.EmulatorState;
import pspemu.core.cpu.Registers;
import pspemu.core.cpu.CpuThreadBase;

class ThreadState {
	public EmulatorState emulatorState;
	public Registers registers;
	public Thread nativeThread;
	public string name;
	
	public this(EmulatorState emulatorState, Registers registers) {
		this.emulatorState = emulatorState;
		this.registers = registers;
	}

	public this(EmulatorState emulatorState) {
		this(emulatorState, new Registers());
	}
}