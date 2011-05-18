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
	
	public this(ThreadState threadState) {
		this.threadState = threadState;
		this.memory = this.threadState.emulatorState.memory;
		this.registers = this.threadState.registers;
		this.threadState.nativeThread = new Thread(&run);
		
		threadState.emulatorState.display.onStop += delegate() {
			running = false;
		};
	}
	
	
	public void start() {
		this.threadState.nativeThread.start();
	}
	
	public void delegate() executeBefore;
	
	abstract public CpuThreadBase createCpuThread(ThreadState threadState);
	
	public void run() {
		thisThreadCpuThreadBase = this;
		//cpuThreadBasePerThread[Thread.getThis] = this;
		writefln("nativeThread");
		if (executeBefore != null) executeBefore();
		execute();
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
	    	while (running) {
		    	this.instruction.v = memory.tread!(uint)(this.registers.PC);
		    	//writefln("  %08X", this.instruction.v);
		    	mixin(genSwitchAll());
		    	executedInstructionsCount++;
		    }
	    	writefln("!running: %s", this);
	    } catch (HaltException haltException) {
	    	writefln("halted thread: %s", this);
	    } catch (Exception exception) {
	    	writefln("%s", exception);
	    	writefln("%s", this);
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