module pspemu.gui.GuiBase;

import std.stdio;
import core.thread;
import pspemu.utils.WaitReady;

public import pspemu.EmulatorHelper;
public import pspemu.core.Memory;
public import pspemu.core.controller.Controller;
public import pspemu.core.display.Display;
public import pspemu.core.EmulatorState;
public import pspemu.hle.HleEmulatorState;
public import pspemu.core.cpu.CpuThreadBase;
public import pspemu.hle.vfs.devices.MemoryStickDevice;

import pspemu.utils.Logger;

abstract class GuiBase {
	HleEmulatorState hleEmulatorState;
	EmulatorState emulatorState;
	Display display;
	Controller controller;
	Thread thread;
	WaitReady initialized;
	
	EmulatorHelper emulatorHelper;
	
	this(EmulatorHelper emulatorHelper) {
		this.emulatorHelper = emulatorHelper;
		this(emulatorHelper.emulator.hleEmulatorState);
	}
	
	this(HleEmulatorState hleEmulatorState) {
		this.hleEmulatorState = hleEmulatorState;
		this.emulatorState = hleEmulatorState.emulatorState;
		this.display    = emulatorState.display;
		this.controller = emulatorState.controller;
		this.initialized = new WaitReady();
	}
	
	public void start() {
		this.thread = new Thread(&loop);
		this.thread.name = "GuiBaseThread";
		this.thread.start();
		//this.initialized.waitReady();
	}
	
	protected void loop() {
		this.init();
		this.initialized.setReady();
		while (display.runningState.running) {
			try {
				this.display.drawRow0ConditionEvent.wait();
				this.loopStep();
			} catch (Throwable o) {
				Logger.log(Logger.Level.ERROR, "Gui", "Error: " ~ o.toString);
			}
		}
	}
	
	void dumpMemory() {
		Memory memory = hleEmulatorState.emulatorState.memory;
		std.file.write("memory.dump", memory.mainMemory);
	}
	
	void dumpThreads() {
		try {
			writefln("Threads(%d):", Thread.getAll.length);
			foreach (thread; Thread.getAll) {
				writefln("  - Thread: '%s', running:%d, priority:%d", thread.name, thread.isRunning, thread.priority);
			}
			auto cpuThreadList = emulatorState.getCpuThreadsDup;
			writefln("CpuThreads(%d):", cpuThreadList.length);
			foreach (CpuThreadBase cpuThread; cpuThreadList) {
				writef("  - CpuThread:");
				try {
					writef("%s", cpuThread);
				} catch {
					
				}
				writefln("");
				//int callStackPosEnd   = min(cast(int)cpuThread.threadState.registers.CallStackPos, cast(int)cpuThread.threadState.registers.CallStack.length);
				//int callStackPosStart = max(0, callStackPosEnd - 10);

				try {								
					//foreach (k, pc; cpuThread.threadState.registers.CallStack[callStackPosStart..callStackPosEnd])
					foreach (k, pc; cpuThread.threadState.registers.CallStack[0..cpuThread.threadState.registers.CallStackPos]) {
						writefln("    - %d - 0x%08X", k, pc);
					}
				} catch (Throwable o) {
					
				}
			}
		} catch (Throwable o) {
			
		}
	}

	abstract protected void init();
	abstract protected void loopStep();
}