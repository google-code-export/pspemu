module pspemu.core.ThreadState;

import core.thread;

import std.stdio;

import pspemu.core.EmulatorState;
import pspemu.core.cpu.Registers;
import pspemu.core.cpu.CpuThreadBase;

import pspemu.hle.kd.Types;
import pspemu.hle.kd.threadman.Types;
import pspemu.hle.Module;

import std.c.windows.windows;

class ThreadState {
	protected __gshared ThreadState[Thread] threadStatePerThread;
	
	public string waitType;
	public bool waiting;
	public EmulatorState emulatorState;
	public Registers registers;
	protected Thread nativeThread;
	protected HANDLE nativeThreadHandle;
	public string name;
	public SceUID thid;
	public SceKernelThreadInfo sceKernelThreadInfo;
	public Module threadModule;
	public int wakeUpCount;
	
	public void nativeThreadSet(void delegate() run, string name = "<unknown thread>") {
		nativeThread = new Thread(delegate() {
			nativeThreadHandle = GetCurrentThread();
			run();
		});
		nativeThread.name = name;
	}
	
	public void nativeThreadStart() {
		nativeThread.start();
	}
	
	public void nativeThreadSuspend() {
		SuspendThread(nativeThreadHandle);
	}

	public void nativeThreadWakeup() {
		ResumeThread(nativeThreadHandle);
	}
	
	@property public bool nativeThreadIsRunning() {
		return nativeThread.isRunning();
	}
	
	public bool isSleeping() {
		return !nativeThreadIsRunning;
		//if (nativeThread.sleep)
	}
	
	static ThreadState getFromThread(Thread thread = null) {
		if (thread is null) thread = Thread.getThis();
		return threadStatePerThread[thread];
	}
	
	void setInCurrentThread(Thread thread = null) {
		if (thread is null) thread = Thread.getThis();
		threadStatePerThread[thread] = this;
	}
	
	ThreadState clone() {
		ThreadState threadState = new ThreadState(name, emulatorState, new Registers());
		{
			threadState.waiting = waiting;
			threadState.registers.copyFrom(registers);
			threadState.nativeThread = Thread.getThis;
			threadState.thid = -1;
			threadState.threadModule = threadModule;
			threadState.sceKernelThreadInfo = sceKernelThreadInfo;
		}
		return threadState;
	}
	
	public void waitingBlock(string waitType, void delegate() callback) {
		this.waitType = waitType;
		this.waiting = true;

		scope (exit) {
			this.waitType = "";
			this.waiting = false;
		}

		callback();
	}
	
	public this(string name, EmulatorState emulatorState, Registers registers) {
		this.name = name;
		this.emulatorState = emulatorState;
		this.registers = registers;
	}

	public this(string name, EmulatorState emulatorState) {
		this(name, emulatorState, new Registers());
	}
	
	string toString() {
		return std.string.format("ThreadState(%d:'%s', PC:%08X, waiting:%s'%s')", thid, name, registers.PC, waiting, waitType);
	}
}