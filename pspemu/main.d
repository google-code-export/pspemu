module pspemu.main;

import pspemu.core.EmulatorState;
import pspemu.utils.Path;

import core.thread;

import std.stdio;
import std.c.stdlib;
import std.stream;
import std.file;
import std.path;
import std.process;

import pspemu.tests.MemoryPartitionTests;

import pspemu.Emulator;

import pspemu.hle.kd.iofilemgr.IoFileMgrForUser;
import pspemu.hle.ModuleNative;
import pspemu.hle.ModuleLoader;

void doUnittest() {
	(new MemoryPartitionTests()).test();
}

unittest {
	doUnittest();
}

int main(string[] args) {
	ApplicationPaths.initialize(args);
	
	void requireDirectory(string directory) {
		try { std.file.mkdirRecurse(ApplicationPaths.exe ~ "/" ~ directory); } catch { }
	}
	
	requireDirectory("pspfs/flash0/font");
	requireDirectory("pspfs/flash0/kd");
	requireDirectory("pspfs/flash0/vsh");
	requireDirectory("pspfs/flash1");
	requireDirectory("pspfs/ms0/PSP/GAME/virtual");
	requireDirectory("pspfs/ms0/PSP/PHOTO");
	requireDirectory("pspfs/ms0/PSP/SAVEDATA");
	
	Emulator emulator = new Emulator();
	ModuleLoader moduleLoader = emulator.hleEmulatorState.moduleLoader;
	
	uint CODE_PTR_EXIT_THREAD = 0x08000000;
	
	emulator.hleEmulatorState.memoryPartition.allocLow(1024);
	emulator.emulatorState.memory.twrite!uint(CODE_PTR_EXIT_THREAD, 0x0000000C | (0x2071 << 6));
	
	with (emulator.emulatorState) {
		memory.position = 0x08100000;
		memory.write(cast(uint)(memory.position + 4));
		memory.writeString("ms0:/PSP/GAME/virtual/EBOOT.PBP\0");
	}
	
	void loadModule(string pspModulePath) {
		moduleLoader.load(pspModulePath);
		emulator.hleEmulatorState.moduleManager.get!(IoFileMgrForUser)().setVirtualDir(std.path.dirname(pspModulePath));
	}
	


	//emulator.emulatorState.memory.twrite!uint(CODE_PTR_EXIT_THREAD + 4, CODE_PTR_EXIT_THREAD + 8);
	//emulator.emulatorState.memory.twrite(CODE_PTR_EXIT_THREAD + 8, cast(ubyte[])"ms0:/PSP/GAME/virtual/EBOOT.PBP" ~ '\0');
	

	//loadModule(r"C:\projects\pspemu31\demos\minifire.elf");
	//loadModule(r"C:\projects\pspemu31\bin\HelloJpcsp.pbp");
	//loadModule(r"C:\projects\pspemu31\bin\HelloWorldPSP.pbp");
	//loadModule(r"C:\projects\pspemu31\bin\ortho.pbp");
	//loadModule(r"C:\projects\pspemu31\bin\lines.pbp");
	//loadModule(r"C:\projects\pspemu31\bin\text.elf");
	//loadModule(r"C:\projects\pspemu31\bin\cube.pbp");
	//loadModule(r"C:\projects\pspemu31\bin\blend.pbp");
	//loadModule(r"C:\projects\pspemu31\bin\vfpu_nehe01.pbp");
	//loadModule(r"C:\projects\pspemu31\bin\vfpu_nehe02.pbp");
	//loadModule(r"C:\projects\pspemu31\bin\zbufferfog.elf");
	//loadModule(r"C:\projects\pspemu31\bin\rtctest.pbp");
	//loadModule(r"C:\projects\pspemu31\tests_ex\fpu\fputest.elf");
	//loadModule(r"C:\projects\pspemu31\tests_ex\threads\test.elf");
	//loadModule(r"C:\projects\pspemu31\tests_ex\threads\thread_start.elf");
	//loadModule(r"tests_ex\string\string.elf");
	//std.file.write("memory.dump", emulator.emulatorState.memory.mainMemory);

	//loadModule(r"C:\projects\pspemu31\demos\nehe\vfpu_nehe08.pbp");
	//loadModule(r"C:\projects\pspemu31\demos\nehe\vfpu_nehe09.pbp");
	//loadModule(r"C:\projects\pspemu31\demos\nehe\vfpu_nehe06.pbp");
	//loadModule(r"C:\projects\pspemu31\demos\nehe\vfpu_nehe07.pbp");
	//loadModule(r"C:\projects\pspemu31\demos\sound.prx");
	//loadModule(r"C:\projects\pspemu31\demos\polyphonic.elf");
	//loadModule(r"C:\projects\pspemu31\demos\cwd.elf");
	//loadModule(r"C:\projects\pspemu31\demos\threadstatus.elf");
	
	
	//loadModule(r"C:\projects\pspemu31\demos\nehe\vfpu_nehe08.pbp");
	//loadModule(r"C:\projects\pspemu31\games\TrigWars\EBOOT.PBP");
	//loadModule(r"C:\projects\pspemu31\games\cavestory\EBOOT.PBP");
	loadModule(r"C:\projects\pspemu31\demos\nehe\vfpu_nehe10.pbp");
	//loadModule(r"C:\projects\pspemu31\demos_ex\sdl\main.elf");
	
	writefln("ModuleNative.registeredModules:");
	foreach (k, moduleName; ModuleNative.registeredModules) {
		writefln(" :: '%s':'%s'", k, moduleName);
	}
	
	writefln("%08X", moduleLoader.PC);
	//auto stack = emulator.hleEmulatorState.memoryPartition.alloc(0x8000);
	// @HACK:
	auto PC = moduleLoader.PC;
	uint GP = moduleLoader.GP;
	auto SP = emulator.hleEmulatorState.memoryPartition.allocHigh(0x8000, 0x10).high;

	//auto thid = threadManForUser.sceKernelCreateThread("Main Thread", PC, 32, 0x8000, 0, null);
	with (emulator.mainCpuThread) {
		registers.pcSet = PC; 
	
		registers.GP = GP;
	
		registers.SP = SP;
		registers.K0 = registers.SP;
		registers.RA = CODE_PTR_EXIT_THREAD;
		registers.A0 = 1;
		registers.A1 = 0x08100000 + 4;
	}
	
	writefln("GP: %08X", GP);
	writefln("PC: %08X", PC);
	writefln("SP: %08X", SP);

	writefln("%s", emulator.hleEmulatorState.memoryPartition);

	emulator.emulatorState.display.onStop += delegate() {
		//std.file.write("memory.dump", emulator.emulatorState.memory.mainMemory);
	};

	// @TODO: This is a hack because some threads are not closing. I have to investigate this. 
	emulator.emulatorState.display.onStop += delegate() {
		Thread.sleep(dur!("msecs")(100));
		std.c.stdlib.exit(0);
	};
	
	emulator.startDisplay();
	emulator.startGpu();
	emulator.startMainThread();
	
	return 0;
}
