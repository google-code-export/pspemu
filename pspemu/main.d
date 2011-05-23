module pspemu.main;

import pspemu.core.EmulatorState;
import pspemu.utils.Path;

import core.thread;
import std.stdio;
import std.conv;
import std.c.stdlib;
import std.stream;
import std.file;
import std.path;
import std.process;
import std.string;
import std.array;
import std.regex;

import pspemu.tests.MemoryPartitionTests;

import pspemu.Emulator;
import pspemu.EmulatorHelper;

import std.getopt;

import pspemu.gui.GuiNull;
import pspemu.gui.GuiSdl;

import pspemu.utils.Logger;

import pspemu.hle.kd.sysmem.KDebugForKernel;

import pspemu.hle.vfs.MountableVirtualFileSystem;
import pspemu.hle.vfs.LocalFileSystem;

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
	auto root = new MountableVirtualFileSystem(new VirtualFileSystem());
	root.mount("ms0:", new LocalFileSystem(r"C:\temp\SDL-1.2.14"));

	auto f = root.open("ms0:/../SDL.spec", octal!777, FileOpenMode.In);
	ubyte[] data;
	data.length = 100;
	root.read(f, data);
	writefln("%s", data);
	root.close(f);
	return 0;
	*/
	
	bool doTestsEx;
	bool showHelp;
	bool nolog, log, trace;
	
	void disableLogComponent(string opt, string component) {
		Logger.disableLogComponent(component);
	}
	
	void enableLogComponent(string opt, string component) {
		Logger.enableLogComponent(component);
	}
	
	getopt(
		args,
		"help|h|?", &showHelp,
		"tests", &doTestsEx,
		"nolog", &nolog,
		"trace", &trace,
		"log", &log,
		"nologmod", &disableLogComponent,
		"enlogmod", &enableLogComponent
	);
	
	void displayHelp() {
		writefln("DPspEmulator 0.3.1.0");
		writefln("");
		writefln("pspemu.exe [<args>] [<file>]");
		writefln("");
		writefln("Arguments:");
		writefln("  --help         - Show this help");
		writefln("  --tests        - Run tests on 'tests_ex' folder");
		writefln("  --trace        - Enables cpu tracing at start");
		writefln("  --log          - Enables logging");
		writefln("  --nolog        - Disables logging");
		writefln("  --nologmod=MOD - Disables logging of a module");
		writefln("  --enlogmod=MOD - Enables logging of a module");
		writefln("");
		writefln("Examples:");
		writefln("  pspemu.exe --help");
		writefln("  pspemu.exe --test");
		writefln("  pspemu.exe game/EBOOT.PBP");
		writefln("");
	}
	
	if (showHelp) {
		displayHelp();
		return -1;
	}

	if (doTestsEx) {
		EmulatorHelper emulatorHelper = new EmulatorHelper(new Emulator());
		emulatorHelper.initComponents();
		if (log) {
			Logger.setLevel(Logger.Level.TRACE);
		} else {
			Logger.setLevel(Logger.Level.CRITICAL);			
		}
		foreach (std.file.DirEntry dirEntry; dirEntries(r"tests_ex", SpanMode.depth, true)) {
			if (std.string.indexOf(dirEntry.name, ".svn") != -1) continue;
			if (std.path.getExt(dirEntry.name) != "expected") continue;
			
			emulatorHelper.loadAndRunTest(dirEntry.name);
			emulatorHelper.reset();
		}
		emulatorHelper.stop();
		return 0;
	}
	
	if (args.length > 1) {
		if (nolog) {
			Logger.setLevel(Logger.Level.WARNING);
		} else {
			if (log) {
				Logger.setLevel(Logger.Level.TRACE);
			} else {
				Logger.setLevel(Logger.Level.INFO);
			}
		}
		EmulatorHelper emulatorHelper = new EmulatorHelper(new Emulator());
		if (nolog) {
			emulatorHelper.emulator.hleEmulatorState.kPrint.outputKprint = true;
		}
		emulatorHelper.initComponents();
		GuiSdl gui = new GuiSdl(emulatorHelper.emulator.hleEmulatorState);
		gui.start();
		emulatorHelper.loadModule(args[1]);
		emulatorHelper.emulator.mainCpuThread.trace = trace;
		emulatorHelper.start();
		return 0;
	}
	
	displayHelp();
	writefln("No specified file to execute");
	return -1;
}
