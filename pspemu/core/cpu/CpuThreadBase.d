module pspemu.core.cpu.CpuThreadBase;

import std.stdio;
import core.thread;

import pspemu.core.ThreadState;
import pspemu.core.Memory;
import pspemu.core.exceptions.HaltException;

import pspemu.core.cpu.tables.Table;
import pspemu.core.cpu.tables.SwitchGen;
import pspemu.core.cpu.tables.DummyGen;
import pspemu.core.cpu.Instruction;
import pspemu.core.cpu.Registers;

import pspemu.utils.Logger;

import pspemu.core.cpu.InstructionHandler;
import pspemu.hle.kd.threadman.Types;

public CpuThreadBase thisThreadCpuThreadBase;

abstract class CpuThreadBase : InstructionHandler {
	CpuThreadBase cpuThread;
	Instruction instruction;
	ThreadState threadState;
	Memory memory;
	Registers registers;
	bool running = true;
	//static CpuThreadBase[Thread] cpuThreadBasePerThread;
	
	ulong executedInstructionsCount;
	__gshared long lastThreadId = 0;
	
	public this(ThreadState threadState) {
		this.cpuThread = this;
		this.threadState = threadState;
		this.memory = this.threadState.emulatorState.memory;
		this.registers = this.threadState.registers;
		this.threadState.nativeThread = new Thread(&run);
		this.threadState.nativeThread.name = std.string.format("PspCpuThread#%d('%s')", lastThreadId++, threadState.name);
		
		threadState.emulatorState.runningState.onStop += delegate(...) {
			running = false;
		};
	}

	public void start() {
		this.threadState.nativeThread.start();
	}
	
	public void delegate() executeBefore;
	
	abstract public CpuThreadBase createCpuThread(ThreadState threadState);
	
	protected void run() {
		thisThreadCpuThreadBase = this;
		//cpuThreadBasePerThread[Thread.getThis] = this;
		if (executeBefore != null) executeBefore();
		
		threadState.emulatorState.cpuThreads[this] = true;
		{
			threadState.emulatorState.cpuThreadRunningBlock({
				execute();
			});
		}
		
		threadState.emulatorState.cpuThreads.remove(this);
		running = false;
		threadState.sceKernelThreadInfo.status = PspThreadStatus.PSP_THREAD_STOPPED;
	}
	
	public void thisThreadWaitCyclesAtLeast(int count = 100) {
		while (true) {
			Thread.yield();
			// Not running.
			if (!this.threadState.nativeThread.isRunning) break;
			
			if (this.threadState.waiting) break;
			
			if (this.executedInstructionsCount >= count) break;
		}
	}
	
    void execute(bool trace = false) {
    	try {
			Logger.log(Logger.Level.TRACE, "CpuThreadBase", "NATIVE_THREAD: START (%s)", Thread.getThis().name);
    		
	    	while (running) {
	    		//if (registers.PC <= 0x08800100) throw(new Exception("Invalid address for executing"));
	    		if (trace) {
	    			writefln("THREAD(%s) : PC: %08X", Thread.getThis().name, registers.PC);
	    		}

		    	instruction.v = memory.tread!(uint)(registers.PC);
		    	
				/*
		    	if (registers.PC == 0x089020DC) {
		    		writefln("a0=%d", registers.A0);
		    		writefln("a1=%d", registers.A1);
		    		writefln("a2=%d", registers.A2);
		    	}
				*/
		    	
		    	processSingle(instruction);
		    	//writefln("  %08X", instruction.v);
		    	executedInstructionsCount++;
		    }
			Logger.log(Logger.Level.TRACE, "CpuThreadBase", "!running: %s", this);
	    } catch (HaltException haltException) {
			Logger.log(Logger.Level.TRACE, "CpuThreadBase", "halted thread: %s", this);
	    } catch (Exception exception) {
	    	.writefln("at 0x%08X", registers.PC);
	    	.writefln("%s", exception);
	    	.writefln("%s", this);
	    } finally {
			Logger.log(Logger.Level.TRACE, "CpuThreadBase", "NATIVE_THREAD: END (%s)", Thread.getThis().name);
	    }
    }

    string toString() {
    	return "CpuBase(" ~ threadState.toString() ~ ")";
    }
}