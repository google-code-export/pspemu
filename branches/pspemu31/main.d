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
	moduleLoader.load(new BufferedFile(r"C:\projects\pspemu31\bin\minifire.elf", FileMode.In), "minifire.elf");
	
	writefln("%08X", moduleLoader.PC);
	//auto stack = emulator.hleEmulatorState.memoryPartition.alloc(0x8000);
	// @HACK:
	auto SP = emulator.hleEmulatorState.memoryPartition.high - 4;
	uint GP = emulator.hleEmulatorState.memoryPartition.high - 0x10000;
	//auto thid = threadManForUser.sceKernelCreateThread("Main Thread", PC, 32, 0x8000, 0, null);
	with (emulator.mainCpuThread) {
		registers.pcSet = moduleLoader.PC; 
	
		registers.GP = GP;
	
		registers.SP = SP;
		registers.K0 = registers.SP;
		registers.RA = 0x08000000;
	}	
	
	emulator.startDisplay();
	emulator.startMainThread();
	
	return 0;
}
