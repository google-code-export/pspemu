module pspemu.core.PspExecutionState;

import pspemu.hle.SystemHle;
import pspemu.core.Memory;
import pspemu.core.cpu.Registers;

class PspExecutionState {
	public SystemHle systemHle;
	public Cpu cpu;
	public Memory memory;
	public Registers registers;
	
	this(SystemHle systemHle, Cpu cpu, Memory memory, Registers registers) {
		this.systemHle = systemHle;
		this.cpu = cpu;
		this.memory = memory;
		this.registers = registers;
	}
}