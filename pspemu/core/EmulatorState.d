module pspemu.core.EmulatorState;

import std.stdio;

import pspemu.core.Memory;
import pspemu.core.cpu.ISyscall;
import pspemu.core.gpu.Gpu;
import pspemu.core.gpu.impl.GpuOpengl;
import pspemu.core.display.Display;

import core.sync.condition;
import core.sync.mutex;

class EmulatorState {
	public Memory   memory;
	public Display  display;
	public Gpu      gpu;
	public ISyscall syscall;
	public bool     running = true;
	Condition       threadStartedCondition;
	Condition       threadEndedCondition;
	uint            threadsRunning = 0;
	
	this() {
		this.threadStartedCondition = new Condition(new Mutex());
		this.threadEndedCondition = new Condition(new Mutex());
		this.memory  = new Memory();
		this.display = new Display(memory);
		this.gpu     = new Gpu(this, new GpuOpengl());
		this.display.onStop += delegate() {
			running = false;
		};
	}
	
	public void reset() {
		this.memory.reset();
	}
	
	public void cpuThreadRunningBlock(void delegate() callback) {
		threadStartedCondition.notifyAll();
		threadsRunning++;
		{
			callback();
		}
		threadsRunning--;
		threadEndedCondition.notifyAll();
	}
	
    public void waitForAllCpuThreadsToTerminate() {
    	while (this.threadsRunning == 0) {
    		this.threadStartedCondition.wait();
    	}
    	while (this.threadsRunning > 0) {
    		this.threadEndedCondition.wait();
    	}
    }
}