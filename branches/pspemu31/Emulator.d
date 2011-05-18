module pspemu.Emulator;

import pspemu.core.ThreadState;
import pspemu.core.EmulatorState;

import pspemu.core.cpu.CpuBase;
import pspemu.core.cpu.interpreter.CpuExecuteThreadInterpreted;

import pspemu.hle.HleEmulatorState;


class Emulator {
	public EmulatorState emulatorState;
	public HleEmulatorState hleEmulatorState;
	public CpuExecuteThreadInterpreted mainCpuThread;
	
	public this() {
		emulatorState    = new EmulatorState();
		hleEmulatorState = new HleEmulatorState(emulatorState);
		mainCpuThread    = new CpuExecuteThreadInterpreted(new ThreadState(emulatorState));
	}
	
	public void startDisplay() {
		emulatorState.display.start();
	}
	
	public void startMainThread() {
		mainCpuThread.start();
	}
}