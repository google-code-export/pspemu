module pspemu.core.cpu.ISyscall;

import pspemu.core.ThreadState;
import pspemu.core.cpu.CpuBase;

interface ISyscall {
	public void syscall(CpuBase cpuBase, int syscallNum);
}