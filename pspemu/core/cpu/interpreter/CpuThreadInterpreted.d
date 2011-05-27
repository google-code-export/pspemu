module pspemu.core.cpu.interpreter.CpuThreadInterpreted;

version = FASTER_INTERPRETED_CPU;

import std.stdio;
import std.math;

import pspemu.core.ThreadState;

import pspemu.core.cpu.CpuThreadBase;
import pspemu.core.cpu.Registers;

import pspemu.core.exceptions.HaltException;
import pspemu.core.exceptions.NotImplementedException;

import pspemu.core.cpu.interpreter.ops.Alu;
import pspemu.core.cpu.interpreter.ops.Memory;
import pspemu.core.cpu.interpreter.ops.Branch;
import pspemu.core.cpu.interpreter.ops.Special;
import pspemu.core.cpu.interpreter.ops.Jump;
import pspemu.core.cpu.interpreter.ops.Fpu;
import pspemu.core.cpu.interpreter.ops.VFpu;

import pspemu.core.cpu.tables.Table;
import pspemu.core.cpu.tables.SwitchGen;
import pspemu.core.cpu.tables.DummyGen;
import pspemu.core.cpu.interpreter.Utils;
import pspemu.core.cpu.Instruction;
import pspemu.core.ThreadState;
import pspemu.core.Memory;

import pspemu.utils.Logger;
import core.thread;

import pspemu.core.cpu.InstructionHandler;

//version = VERSION_SHIFT_ASM;

//import pspemu.utils.Utils;

class CpuThreadInterpreted : CpuThreadBase {
	public this(ThreadState threadState) {
		super(threadState);
	}
	
	public CpuThreadBase createCpuThread(ThreadState threadState) {
		auto cpuThreadBase = new CpuThreadInterpreted(threadState);
		cpuThreadBase.trace = this.trace;
		return cpuThreadBase;
	}
	
	version (FASTER_INTERPRETED_CPU) {
		void execute(bool trace = false) {
			CpuThreadBase cpuThread = this.cpuThread;
    		Instruction instruction;
    		ThreadState threadState = this.threadState;
    		Registers registers = this.registers;
    		Memory memory = this.memory;
	    		
			void OP_UNK() {
				registers.pcAdvance(4);
				Logger.log(Logger.Level.CRITICAL, "CpuThreadInterpreted", "Thread(%d): OP_UNK", threadState.thid);
			}

			mixin TemplateCpu_ALU;
			mixin TemplateCpu_MEMORY;
			mixin TemplateCpu_BRANCH;
			mixin TemplateCpu_JUMP;
			mixin TemplateCpu_SPECIAL;
			mixin TemplateCpu_FPU;
			mixin TemplateCpu_VFPU;
			
			threadState.setInCurrentThread();
			
	    	try {
				Logger.log(Logger.Level.TRACE, "CpuThreadBase", "NATIVE_THREAD: START (%s)", Thread.getThis().name);
				
				if (threadState.name == "mainCpuThread") {
					//trace = true;
					//threadState.registers.dump();
				}
				
				//trace = true;
	    		
		    	while (running) {
			    	instruction.v = memory.tread!(uint)(registers.PC);
			    	
			    	if (trace) {
			    		writefln("%s :: nPC:%08X: INSTRUCTION:%08X : RA:%08X", threadState, registers.nPC, instruction.v, registers.RA);
			    	}
			    	
			    	mixin(genSwitchAll());
			    	//executedInstructionsCount++;
			    	registers.EXECUTED_INSTRUCTION_COUNT_THIS_THREAD++;
			    }
				Logger.log(Logger.Level.TRACE, "CpuThreadBase", "!running: %s", this);
		    } catch (HaltException haltException) {
				Logger.log(Logger.Level.TRACE, "CpuThreadBase", "halted thread: %s", this);
		    } catch (Exception exception) {
		    	synchronized {
			    	.writefln("at 0x%08X : %s", registers.PC, threadState);
			    	.writefln("THREADSTATE: %s", threadState);
			    	.writefln("MODULE: %s", threadState.threadModule);
			    	
			    	//.,writefln();
			    	.writefln("CALLSTACK:");
			    	scope uint[] callStack = registers.RealCallStack.dup;
			    	callStack ~= registers.PC;
			    	foreach (callPC; callStack) {
			    		//.writef("   ");
			    		.writef("   %08X", callPC);
			    		bool printed = false;
			    		if (threadState.threadModule !is null) {
			    			if (threadState.threadModule.dwarf !is null) {
			    				auto state = threadState.threadModule.dwarf.find(callPC);
			    				if (state !is null) {
			    					writef(":%s", (*state).toString);
			    					printed = true;
			    				}
			    			}
			    		}
			    		if (!printed) {
			    			//.writef("%08X", callPC);
			    		}
			    		.writefln("");
			    	}
			    	.writefln("REGISTERS:");
			    	foreach (k, value; registers.R) {
			    		//.writef("   r%2d: %08X", k, value);
			    		.writef("   %s: %08X", Registers.aliasesInv[k], value);
			    		if ((k % 4) == 3) .writefln("");
			    	}
			    	.writefln("%s", exception);
			    	.writefln("%s", this);
			    	
			    	//cpuThread.threadState.emulatorState.runningState.stop();
			    }
		    } finally {
				Logger.log(Logger.Level.TRACE, "CpuThreadBase", "NATIVE_THREAD: END (%s)", Thread.getThis().name);
		    }
	    }
	} else {
		void OP_UNK() {
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
}
