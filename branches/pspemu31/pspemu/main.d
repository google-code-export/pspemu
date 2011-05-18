module pspemu.main;

import pspemu.core.EmulatorState;

import std.stdio;
import std.stream;

import pspemu.tests.MemoryPartitionTests;

import pspemu.Emulator;

void doUnittest() {
	(new MemoryPartitionTests()).test();
}

unittest {
	doUnittest();
}

int main() {
	auto emulator = new Emulator();
	auto moduleLoader = emulator.hleEmulatorState.moduleLoader; 
	//moduleLoader.load(new BufferedFile(r"C:\projects\pspemu31\bin\minifire.elf", FileMode.In), "minifire.elf");
	//moduleLoader.load(new BufferedFile(r"C:\projects\pspemu31\bin\HelloJpcsp.pbp", FileMode.In), "HelloJpcsp.pbp");
	moduleLoader.load(new BufferedFile(r"C:\projects\pspemu31\bin\HelloWorldPSP.pbp", FileMode.In), "HelloWorldPSP.pbp");
	//moduleLoader.load(new BufferedFile(r"C:\projects\pspemu31\bin\ortho.pbp", FileMode.In), "ortho.pbp");
	
	
	writefln("%08X", moduleLoader.PC);
	//auto stack = emulator.hleEmulatorState.memoryPartition.alloc(0x8000);
	// @HACK:
	auto PC = moduleLoader.PC;
	uint GP = moduleLoader.GP;
	auto SP = emulator.hleEmulatorState.memoryPartition.allocHigh(0x8000).high - 4;

	//auto thid = threadManForUser.sceKernelCreateThread("Main Thread", PC, 32, 0x8000, 0, null);
	with (emulator.mainCpuThread) {
		registers.pcSet = PC; 
	
		registers.GP = GP;
	
		registers.SP = SP;
		registers.K0 = registers.SP;
		registers.RA = 0x08000000;
		registers.A0 = 1;
		registers.A1 = emulator.hleEmulatorState.allocBytes(cast(ubyte[])"EBOOT.PBP" ~ '\0');
	}
	
	writefln("GP: %08X", GP);
	writefln("PC: %08X", PC);
	writefln("SP: %08X", SP);

	writefln("%s", emulator.hleEmulatorState.memoryPartition);
	
	emulator.startDisplay();
	emulator.startGpu();
	emulator.startMainThread();
	
	return 0;
}
