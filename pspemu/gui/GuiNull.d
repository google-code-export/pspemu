module pspemu.gui.GuiNull;

import pspemu.gui.GuiBase;

class GuiNull : GuiBase {
	this(EmulatorState emulatorState) {
		super(emulatorState);
	}

	public void init() {
	}

	public void loopStep() {
	}
}