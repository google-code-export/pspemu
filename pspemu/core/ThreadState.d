module pspemu.core.ThreadState;

import core.thread;

import std.stdio;

import pspemu.core.EmulatorState;
import pspemu.core.cpu.Registers;
import pspemu.core.cpu.CpuThreadBase;

import pspemu.hle.kd.Types;
import pspemu.hle.kd.threadman.Types;
import pspemu.hle.Module;

import pspemu.utils.Logger;

import std.c.windows.windows;

public import pspemu.utils.sync.WaitEvent;

import pspemu.utils.Event;

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
	public Event onDeleteThread;
	
	static ThreadState getOneThreadState() {
		foreach (threadState; threadStatePerThread) return threadState;
		return null;
	}
	
	static void suspendAllCpuThreadsButThis() {
		HANDLE thisNativeThreadHandle = GetCurrentThread();
		foreach (threadState; threadStatePerThread) {
			//writefln("suspendAllCpuThreadsButThis: %08X %08X", thisNativeThreadHandle, threadState.nativeThreadHandle);
			if (threadState.nativeThreadHandle != thisNativeThreadHandle) {
				SuspendThread(threadState.nativeThreadHandle);
			}
		}
	}
	
	static void resumeAllCpuThreadsButThis() {
		HANDLE thisNativeThreadHandle = GetCurrentThread();
		foreach (threadState; threadStatePerThread) {
			//writefln("resumeAllCpuThreadsButThis: %08X %08X", thisNativeThreadHandle, threadState.nativeThreadHandle);
			if (threadState.nativeThreadHandle != thisNativeThreadHandle) {
				ResumeThread(threadState.nativeThreadHandle);
			}
		}
	}

	public bool sleeping() {
		synchronized (this) {
			return (wakeUpCount < 0);
		}
	}

	public bool sleeping(bool set) {
		synchronized (this) {
			int wakeUpCountPrev = wakeUpCount; 
			wakeUpCount += set ? -1 : +1;
			Logger.log(Logger.Level.INFO, "ThreadState", "  Thread.wakeUp(%s) || %d -> %d (sleeping:%s)", this, wakeUpCountPrev, wakeUpCount, sleeping);
			return sleeping;
		}
	}
	
	WaitEvent wakeUpEvent;
	
	public this(string name, EmulatorState emulatorState, Registers registers) {
		//this.onDeleteThread = new Event();
		this.name = name;
		this.emulatorState = emulatorState;
		this.registers = registers;
		wakeUpEvent = new WaitEvent("WakeUpEvent");
	}

	public this(string name, EmulatorState emulatorState) {
		this(name, emulatorState, new Registers());
	}
	
	
	public void nativeThreadSet(void delegate() run, string name = "<unknown thread>") {
		nativeThread = new Thread(delegate() {
			nativeThreadHandle = GetCurrentThread();
			
			/*
			final switch (sceKernelThreadInfo.currentPriority) {
				case 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15:
					SetThreadPriority(nativeThreadHandle, THREAD_PRIORITY_ABOVE_NORMAL);
				break;
				case 16, 17, 18, 19:
					SetThreadPriority(nativeThreadHandle, THREAD_PRIORITY_NORMAL);
				break;
				case 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32:
					SetThreadPriority(nativeThreadHandle, THREAD_PRIORITY_BELOW_NORMAL);
				break;
			}
			*/
			
			run();
		});
		nativeThread.name = name;
	}
	
	public void nativeThreadStart() {
		nativeThread.start();
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
	
	string toString() {
		return std.string.format("ThreadState(%d:'%s', PC:%08X, waiting:%s'%s')", thid, name, registers.PC, waiting, waitType);
	}
}