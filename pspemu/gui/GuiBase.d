module pspemu.gui.GuiBase;

import std.stdio;
import core.thread;
import pspemu.utils.WaitReady;

public import pspemu.core.controller.Controller;
public import pspemu.core.display.Display;

abstract class GuiBase {
	Display display;
	Controller controller;
	Thread thread;
	WaitReady initialized;
	
	this(Display display, Controller controller) {
		this.display    = display;
		this.controller = controller;
		this.initialized = new WaitReady();
	}
	
	public void start() {
		this.thread = new Thread(&loop);
		this.thread.name = "GuiBaseThread";
		this.thread.start();
		this.initialized.waitReady();
	}
	
	protected void loop() {
		this.init();
		this.initialized.setReady();
		while (display.runningState.running) {
			this.display.drawRow0Condition.wait();
			this.loopStep();
		}
	}

	abstract protected void init();
	abstract protected void loopStep();
}