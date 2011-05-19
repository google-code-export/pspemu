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

//version = VERSION_SHIFT_ASM;

//import pspemu.utils.Utils;

class CpuThreadInterpreted : CpuThreadBase {
	public this(ThreadState threadState) {
		super(threadState);
	}
	
	public CpuThreadBase createCpuThread(ThreadState threadState) {
		return new CpuThreadInterpreted(threadState);
	}
	
	public void OP_UNK() {
		registers.pcAdvance(4);
		writefln("Thread(%d): OP_UNK", threadState.thid);
	}

	mixin TemplateCpu_ALU;
	mixin TemplateCpu_MEMORY;
	mixin TemplateCpu_BRANCH;
	mixin TemplateCpu_JUMP;
	mixin TemplateCpu_SPECIAL;
	mixin TemplateCpu_FPU;
	mixin TemplateCpu_VFPU;
}
