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

string genSwitchAll() {
	static if (false) {
		const string str = q{
			genSwitch(
				PspInstructions_ALU ~
				PspInstructions_BCU ~
				PspInstructions_LSU ~
				PspInstructions_FPU ~
				PspInstructions_COP0 ~
				PspInstructions_VFPU_IMP ~
				//PspInstructions_VFPU ~
				PspInstructions_SPECIAL
			)
		};
		pragma(msg, mixin(str));
		return mixin(str);
	} else {
		return import("cached_switch_all.dcode");
	} 
}

public CpuThreadBase thisThreadCpuThreadBase;

abstract class CpuThreadBase {
	ThreadState threadState;
	Memory memory;
	Registers registers;
	Instruction instruction;
	bool running = true;
	//static CpuThreadBase[Thread] cpuThreadBasePerThread;
	
	ulong executedInstructionsCount;
	__gshared long lastThreadId = 0;
	
	public this(ThreadState threadState) {
		this.threadState = threadState;
		this.memory = this.threadState.emulatorState.memory;
		this.registers = this.threadState.registers;
		this.threadState.nativeThread = new Thread(&run);
		this.threadState.nativeThread.name = std.string.format("PSP_CPU_THREAD#%d('%s')", lastThreadId++, threadState.name);
		
		threadState.emulatorState.display.onStop += delegate() {
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
		execute();
	}
	
	public void thisThreadWaitCyclesAtLeast(int count = 100) {
		while (true) {
			Thread.yield();
			if (this.executedInstructionsCount >= count) break;
		}
	}

	
	/*
	void opDispatch(string name)() {
		
	}
	*/

	void OP_DISPATCH(string name) {
		writefln("OP_DISPATCH(%s)", name);
		throw(new Exception("Invalid operation: " ~ name));
	}
	
	mixin(DummyGenUnk());
    mixin(DummyGen(PspInstructions_ALU));
    mixin(DummyGen(PspInstructions_BCU));
    mixin(DummyGen(PspInstructions_LSU));
    mixin(DummyGen(PspInstructions_FPU));
    mixin(DummyGen(PspInstructions_COP0));
    mixin(DummyGen(PspInstructions_VFPU_IMP));
    //mixin(DummyGen(PspInstructions_VFPU));
    mixin(DummyGen(PspInstructions_SPECIAL));
    
    void execute() {
    	try {
    		writefln("NATIVE_THREAD: START (%s)", Thread.getThis().name);
    		
	    	while (running) {
	    		//if (this.registers.PC <= 0x08800100) throw(new Exception("Invalid address for executing"));
	    		//writefln("PC: %08X", this.registers.PC);

		    	this.instruction.v = memory.tread!(uint)(this.registers.PC);
		    	//writefln("  %08X", this.instruction.v);
		    	mixin(genSwitchAll());
		    	executedInstructionsCount++;
		    }
	    	writefln("!running: %s", this);
	    } catch (HaltException haltException) {
	    	writefln("halted thread: %s", this);
	    } catch (Exception exception) {
	    	writefln("at 0x%08X", this.registers.PC);
	    	writefln("%s", exception);
	    	writefln("%s", this);
	    } finally {
			writefln("NATIVE_THREAD: END (%s)", Thread.getThis().name);
	    }
    }
    

	/*    
    void execute() {
    }
    */

    string toString() {
    	return "CpuBase(" ~ threadState.toString() ~ ")";
    }
}