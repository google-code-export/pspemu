module pspemu.core.EmulatorState;

import std.stdio;

import pspemu.core.Memory;
import pspemu.core.cpu.ISyscall;
import pspemu.core.cpu.CpuThreadBase;
import pspemu.core.gpu.Gpu;
import pspemu.core.gpu.impl.GpuOpengl;
import pspemu.core.display.Display;
import pspemu.core.controller.Controller;
import pspemu.core.RunningState;

import pspemu.core.ThreadState;

//import pspemu.EmulatorHelper;

import core.sync.condition;
import core.sync.mutex;

class EmulatorState {
	public Memory        memory;
	public Display       display;
	public Controller    controller;
	public Gpu           gpu;
	public ISyscall      syscall;
	public RunningState  runningState;
	Condition            threadStartedCondition;
	Condition            threadEndedCondition;
	uint                 threadsRunning = 0;
	bool[CpuThreadBase]  cpuThreads;
	
	this() {
		this.runningState           = new RunningState();
		this.threadStartedCondition = new Condition(new Mutex());
		this.threadEndedCondition   = new Condition(new Mutex());
		this.memory                 = new Memory();
		this.display                = new Display(this.runningState, this.memory);
		this.controller             = new Controller();
		this.gpu                    = new Gpu(this, new GpuOpengl());
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