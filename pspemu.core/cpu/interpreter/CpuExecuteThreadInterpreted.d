module pspemu.core.cpu.interpreter.CpuExecuteThreadInterpreted;

import std.stdio;
import std.math;

import pspemu.core.ThreadState;

import pspemu.core.cpu.CpuBase;
import pspemu.core.cpu.Registers;

import pspemu.core.exceptions.HaltException;

import pspemu.core.cpu.interpreted.ops.Alu;
import pspemu.core.cpu.interpreted.ops.Memory;
import pspemu.core.cpu.interpreted.ops.Branch;
import pspemu.core.cpu.interpreted.ops.Special;
import pspemu.core.cpu.interpreted.ops.Jump;
import pspemu.core.cpu.interpreted.ops.Fpu;

import pspemu.core.cpu.tables.Table;
import pspemu.core.cpu.tables.SwitchGen;
import pspemu.core.cpu.tables.DummyGen;
import pspemu.core.cpu.interpreter.Utils;

//import pspemu.utils.Utils;

class CpuExecuteThreadInterpreted : CpuBase {
	public this(ThreadState threadState) {
		super(threadState);
	}
	
	public CpuBase createCpuThread(ThreadState threadState) {
		return new CpuExecuteThreadInterpreted(threadState);
	}
	
	mixin TemplateCpu_ALU;
	mixin TemplateCpu_MEMORY;
	mixin TemplateCpu_BRANCH;
	mixin TemplateCpu_JUMP;
	mixin TemplateCpu_SPECIAL;
	mixin TemplateCpu_FPU;
    //void OP_UNK() { writefln("Unknown!!!"); }
    
    
    /*
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
	*/
}