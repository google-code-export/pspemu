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
import pspemu.EmulatorHelper;

import std.getopt;

void doUnittest() {
	(new MemoryPartitionTests()).test();
}

unittest {
	doUnittest();
}

void init(string[] args) {
	Thread.getThis.name = "MainThread";
	
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
}

int main(string[] args) {
	init(args);
	
	/*
	*/
	bool doTestsEx;
	bool showHelp;
	
	getopt(
		args,
		"help|h|?", &showHelp,
		"tests", &doTestsEx 
	);
	
	if (showHelp) {
		writefln("DPspEmulator 0.3.1.0");
		writefln("  --help   - Show this help");
		writefln("  --tests  - Run tests on 'tests_ex' folder");
		return -1;
	}

	if (doTestsEx) {
		EmulatorHelper emulatorHelper = new EmulatorHelper(new Emulator());
		emulatorHelper.initComponents();
		emulatorHelper.loadAndRunTest(r"C:\projects\pspemu31\tests_ex\fpu\fputest.elf");
		emulatorHelper.loadAndRunTest(r"C:\projects\pspemu31\tests_ex\string\string.elf");
		
		return 0;
	}
	
	{
		EmulatorHelper emulatorHelper = new EmulatorHelper(new Emulator());
		emulatorHelper.initComponents();
		emulatorHelper.loadModule(r"C:\projects\pspemu31\demos\cube.pbp");
		emulatorHelper.start();
	}
	
	return 0;
}
