module pspemu.core.EmulatorState;

import pspemu.core.Memory;
import pspemu.core.cpu.ISyscall;
import pspemu.core.display.Display;

class EmulatorState {
	public Memory memory;
	public Display display;
	public ISyscall syscall;
	
	this() {
		this.memory = new Memory();
		this.display = new Display(memory);
	}
}