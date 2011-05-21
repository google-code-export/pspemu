module pspemu.gui.GuiBase;

import std.stdio;
import core.thread;
import pspemu.utils.WaitReady;

public import pspemu.core.controller.Controller;
public import pspemu.core.display.Display;
public import pspemu.core.EmulatorState;
public import pspemu.hle.HleEmulatorState;

import pspemu.utils.Logger;

abstract class GuiBase {
	HleEmulatorState hleEmulatorState;
	EmulatorState emulatorState;
	Display display;
	Controller controller;
	Thread thread;
	WaitReady initialized;
	
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
				this.display.drawRow0Condition.wait();
				this.loopStep();
			} catch (Throwable o) {
				Logger.log(Logger.Level.ERROR, "Gui", "Error: " ~ o.toString);
			}
		}
	}

	abstract protected void init();
	abstract protected void loopStep();
}