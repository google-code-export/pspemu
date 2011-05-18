module pspemu.Emulator;

import pspemu.core.ThreadState;
import pspemu.core.EmulatorState;

import pspemu.core.cpu.CpuThreadBase;
import pspemu.core.cpu.interpreter.CpuThreadInterpreted;

import pspemu.hle.HleEmulatorState;


class Emulator {
	public EmulatorState emulatorState;
	public HleEmulatorState hleEmulatorState;
	public CpuThreadInterpreted mainCpuThread;
	
	public this() {
		emulatorState    = new EmulatorState();
		hleEmulatorState = new HleEmulatorState(emulatorState);
		mainCpuThread    = new CpuThreadInterpreted(new ThreadState(emulatorState));
	}
	
	public void startDisplay() {
		emulatorState.display.start();
	}
	
	public void startMainThread() {
		mainCpuThread.start();
	}
}