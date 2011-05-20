module pspemu.gui.GuiNull;

import pspemu.gui.GuiBase;

class GuiNull : GuiBase {
	this(Display display, Controller controller) {
		super(display, controller);
	}

	public void init() {
	}

	public void loopStep() {
	}
}