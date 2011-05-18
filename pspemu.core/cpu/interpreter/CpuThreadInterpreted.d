module pspemu.core.cpu.interpreter.CpuThreadInterpreted;

import std.stdio;
import std.math;

import pspemu.core.ThreadState;

import pspemu.core.cpu.CpuThreadBase;
import pspemu.core.cpu.Registers;

import pspemu.core.exceptions.HaltException;
import pspemu.core.exceptions.NotImplementedException;

import pspemu.core.cpu.interpreted.ops.Alu;
import pspemu.core.cpu.interpreted.ops.Memory;
import pspemu.core.cpu.interpreted.ops.Branch;
import pspemu.core.cpu.interpreted.ops.Special;
import pspemu.core.cpu.interpreted.ops.Jump;
import pspemu.core.cpu.interpreted.ops.Fpu;
import pspemu.core.cpu.interpreted.ops.VFpu;

import pspemu.core.cpu.tables.Table;
import pspemu.core.cpu.tables.SwitchGen;
import pspemu.core.cpu.tables.DummyGen;
import pspemu.core.cpu.interpreter.Utils;

//import pspemu.utils.Utils;

class CpuThreadInterpreted : CpuThreadBase {
	public this(ThreadState threadState) {
		super(threadState);
	}
	
	public CpuThreadBase createCpuThread(ThreadState threadState) {
		return new CpuThreadInterpreted(threadState);
	}

	mixin TemplateCpu_ALU;
	mixin TemplateCpu_MEMORY;
	mixin TemplateCpu_BRANCH;
	mixin TemplateCpu_JUMP;
	mixin TemplateCpu_SPECIAL;
	mixin TemplateCpu_FPU;
	mixin TemplateCpu_VFPU;
    //void OP_UNK() { writefln("Unknown!!!"); }
    
    /+
	mixin(DummyGenUnk());
    //mixin(DummyGen(PspInstructions_ALU));
    //mixin(DummyGen(PspInstructions_BCU));
    //mixin(DummyGen(PspInstructions_LSU));
    //mixin(DummyGen(PspInstructions_FPU));
    mixin(DummyGen(PspInstructions_COP0));
    mixin(DummyGen(PspInstructions_VFPU_IMP));
    //mixin(DummyGen(PspInstructions_VFPU));
    //mixin(DummyGen(PspInstructions_SPECIAL));
    
    
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
    +/
}
