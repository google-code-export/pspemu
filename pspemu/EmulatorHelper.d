module pspemu.EmulatorHelper;

import core.thread;
import std.stdio;
import std.c.stdlib;
import std.stream;
import std.file;
import std.path;
import std.string;
import std.array;
import std.process;

import pspemu.Emulator;

import pspemu.core.ThreadState;
import pspemu.core.EmulatorState;

import pspemu.core.cpu.CpuThreadBase;
import pspemu.core.cpu.interpreter.CpuThreadInterpreted;

import pspemu.hle.HleEmulatorState;

import pspemu.hle.ModuleNative;
import pspemu.hle.ModuleLoader;

import pspemu.gui.GuiBase;

import pspemu.hle.kd.iofilemgr.IoFileMgrForUser;
import pspemu.hle.kd.sysmem.KDebugForKernel; 

import pspemu.hle.MemoryManager;

class EmulatorHelper {
	const uint CODE_PTR_EXIT_THREAD = 0x08000000;
	const uint CODE_PTR_END_CALLBACK = 0x08000004;
	
	Emulator emulator;
	
	this(Emulator emulator) {
		this.emulator = emulator;
		this.init();
	}
	
	public void init() {
		emulator.hleEmulatorState.memoryManager.allocHeap(PspPartition.Kernel0, "KernelFunctions", 1024);
		emulator.emulatorState.memory.twrite!uint(CODE_PTR_EXIT_THREAD, 0x0000000C | (0x2071 << 6));
		emulator.emulatorState.memory.twrite!uint(CODE_PTR_END_CALLBACK, 0x0000000C | (0x1002 << 6));
		
		with (emulator.emulatorState) {
			memory.position = 0x08000100;
			memory.write(cast(uint)(memory.position + 4));
			memory.writeString("ms0:/PSP/GAME/virtual/EBOOT.PBP\0");
			//memory.writeString("umd0:/PSP_GAME/SYSDIR/BOOT.BIN\0");
		}
		
		// @TODO: hack because not all threads are stopping.
		emulator.emulatorState.runningState.onStop += delegate() {
			Thread.sleep(dur!("msecs")(100));
			std.c.stdlib.exit(0);
		};
	}
	
	public void reset() {
		emulator.reset();
	}
	
	public void stop() {
		emulator.emulatorState.runningState.stop();
	}
	
	public void loadModule(string pspModulePath) {
		//reset();
		
		Logger.log(Logger.Level.INFO, "EmulatorHelper", "Loading module ('%s')...", pspModulePath);

		emulator.mainCpuThread.threadState.threadModule = emulator.hleEmulatorState.moduleLoader.load(pspModulePath);
		
		emulator.hleEmulatorState.rootFileSystem.setVirtualDir(std.path.dirname(pspModulePath));
		
		with (emulator.mainCpuThread) {
			registers.pcSet = emulator.hleEmulatorState.moduleLoader.PC; 
		
			registers.GP = emulator.hleEmulatorState.moduleLoader.GP;
			registers.SP = emulator.hleEmulatorState.memoryManager.allocStack(PspPartition.User, "Stack for main thread", 0x8000) - 0x10;
			registers.K0 = registers.SP;
			registers.RA = CODE_PTR_EXIT_THREAD;
			registers.A0 = 1;
			registers.A1 = 0x08100000 + 4;
		}
		
		Logger.log(Logger.Level.INFO, "EmulatorHelper", "Module loaded successfully");
	}
	
	public void initComponents() {
		emulator.startDisplay();
		emulator.startGpu();
	}
	
	public void start() {
		emulator.startMainThread();
		
		emulator.emulatorState.waitForAllCpuThreadsToTerminate();
	}
	
	public void loadAndRunTest(string pspTestExpectedPath) {
		auto pspTestBasePath     = std.path.getName(pspTestExpectedPath);
		auto pspTestElfPath = std.string.format("%s.elf", pspTestBasePath);
		stdout.writef("%s...", pspTestBasePath); stdout.flush();
		{
			loadModule(pspTestElfPath);
			start();
		}
		string expected = std.string.strip(cast(string)std.file.read(pspTestExpectedPath));
		string returned = std.string.strip(emulator.hleEmulatorState.moduleManager.get!(KDebugForKernel)().outputBuffer);
		stdout.writefln("%s", (expected == returned) ? "OK" : "FAIL");
		if (expected != returned) {
			stdout.writefln("    returned:'%s'", std.array.replace(returned, "\n", "|"));
			stdout.writefln("    expected:'%s'", std.array.replace(expected, "\n", "|"));
		}
	}
}