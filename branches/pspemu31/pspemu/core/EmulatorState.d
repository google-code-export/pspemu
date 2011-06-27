module pspemu.core.EmulatorState;

import std.stdio;

import pspemu.core.Memory;
import pspemu.core.cpu.ISyscall;
import pspemu.core.cpu.CpuThreadBase;
import pspemu.core.gpu.Gpu;
import pspemu.core.gpu.impl.gl.GpuOpengl;
import pspemu.core.display.Display;
import pspemu.core.controller.Controller;
import pspemu.core.RunningState;

import pspemu.core.ThreadState;

//import pspemu.EmulatorHelper;

import core.sync.condition;
import core.sync.mutex;
import pspemu.core.battery.Battery;

import pspemu.utils.sync.WaitEvent;

class EmulatorState {
	public Memory        memory;
	public Battery       battery;
	public Display       display;
	public Controller    controller;
	public Gpu           gpu;
	public ISyscall      syscall;
	public RunningState  runningState;
	WaitEvent            threadStartedCondition;
	WaitEvent            threadEndedCondition;
	uint                 threadsRunning = 0;
	bool[CpuThreadBase]  cpuThreads;
	bool                 unittesting = false;
	
	CpuThreadBase[] getCpuThreadsDup() {
		return cpuThreads.keys.dup;
	}
	
	this() {
		this.runningState           = new RunningState();
		this.threadStartedCondition = new WaitEvent("EmulatorState.threadStartedCondition");
		this.threadEndedCondition   = new WaitEvent("EmulatorState.threadEndedCondition");
		this.memory                 = new Memory();
		this.battery                = new Battery();
		this.display                = new Display(this.runningState, this.memory);
		this.controller             = new Controller();
		this.gpu                    = new Gpu(this, new GpuOpengl());
	}
	
	public void reset() {
		this.cpuThreads = null;
		this.memory.reset();
		this.display.reset();
		this.controller.reset();
		this.gpu.reset();
		this.runningState.reset();
		this.threadsRunning = 0;
	}
	
	public void cpuThreadRunningBlock(void delegate() callback) {
		threadStartedCondition.signal();
		threadsRunning++;
		{
			callback();
		}
		threadsRunning--;
		threadEndedCondition.signal();
	}

    public void waitSomeCpuThreadsToStart() {
    	while (this.threadsRunning == 0) {
    		this.threadStartedCondition.wait();
    	}
    }
	
    public void waitForAllCpuThreadsToTerminate() {
    	//waitSomeCpuThreadsToStart();
    	while (this.threadsRunning > 0) {
    		this.threadEndedCondition.wait();
    	}
    }
}