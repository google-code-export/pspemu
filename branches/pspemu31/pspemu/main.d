module pspemu.main;

import pspemu.core.EmulatorState;
import pspemu.utils.Path;

import std.c.windows.windows;

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

import pspemu.gui.GuiBase;
import pspemu.gui.GuiNull;
import pspemu.gui.GuiSdl;
import pspemu.gui.GuiDfl;

import pspemu.utils.Logger;

import pspemu.hle.kd.sysmem.KDebug;

import pspemu.hle.vfs.VirtualFileSystem;
import pspemu.hle.vfs.MountableVirtualFileSystem;
import pspemu.hle.vfs.LocalFileSystem;
import pspemu.hle.vfs.IsoFileSystem;

import pspemu.formats.Pgf;
import pspemu.formats.iso.Iso;
import pspemu.formats.iso.IsoFactory;
import pspemu.formats.DetectFormat;
import pspemu.core.gpu.GpuState;
import pspemu.core.gpu.Types;

import pspemu.hle.kd.all;

import pspemu.utils.Diff;

void executeSandboxTests(string[] args) {
	/*
	MountableVirtualFileSystem vfs = new MountableVirtualFileSystem(new VirtualFileSystem());
	writefln("Format: %s", DetectFormat.detect(args[1]));
	if (args.length >= 2) {
		vfs.mount("disc0:", new IsoFileSystem(IsoFactory.getIsoFromStream(args[1])));
	}
	vfs.mount("flash0:", new LocalFileSystem(r"bin\pspfs\flash0"));
	Pgf pgf = new Pgf();
	pgf.load(vfs.open("flash0:/font/ltn0.pgf", FileOpenMode.In, FileAccessMode.All));
	writefln("%s", pgf);
	foreach (entry; vfs.dopen("disc0:/PSP_GAME")) {
		writefln("%s", entry);
	}
	foreach (entry; vfs.dopen("flash0:/font")) {
		writefln("%s", entry);
	}
	*/
	
	/*
	Command command;
	command.v = 0xFFFFFFFF;
	LightModel value = command.extractEnum!(LightModel);
	writefln("LightModel: %d", value);
	*/
	
	writefln("[");
	
	string[] listA = ["a", "b", "c"];
	string[] listB = ["a", "c", "b"];
	
	writefln("%s", listA);
	writefln("%s", listB);
	
	
	Diff.diffTextProcessed(listA, listB).print();

	/*	
	auto diff = new Diff();
	int lastpos = 0;
	foreach (v; diff.diffText(listA, listB)) {
		foreach (i; lastpos..v.startA) {
			writefln(" %s", listA[i]);
		}

		writefln("lastpos(%d) : %s", lastpos, v);

		foreach (i; 0..v.deletedA) {
			writefln("-%s", listA[v.startA + i]);
		}
		foreach (i; 0..v.insertedB) {
			writefln("+%s", listB[v.startB + i]);
		}
		lastpos = v.startA;
	}
	*/
	writefln("]");
}

void executeIsoListing(string[] args) {
	Iso iso = IsoFactory.getIsoFromStream(args[1]);
	writefln("%s", iso);
	foreach (node; iso.descendency) {
		writefln("%s", node);
	}
	
	if (args.length >= 3) {
		writefln("Extracting '%s'...", args[2]);
		auto nodeToExtract = iso.locate(args[2]); 
		writefln("     '%s'...", nodeToExtract);
		nodeToExtract.saveTo();
	}
}

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


import pspemu.utils.SvnVersion;
import pspemu.extra.Cheats;

import pspemu.core.gpu.impl.gl.GpuOpengl;
import pspemu.core.gpu.Commands;


int main(string[] args) {
	init(args);
	
	//writefln("%d, %d", getLastOnlineVersion, SvnVersion.revision);
	
	/*
	writefln("[1]");
	auto handle = curl_easy_init();
	curl_easy_setopt(handle, CurlOption.url, "http://pspemu.googlecode.com/svn/");
	curl_easy_perform(handle);
	writefln("[2]");
	curl_easy_cleanup(handle);
	*/
	
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
	
	bool isolist;
	bool doSandboxTests;
	bool doUnitTests;
	bool doTestsEx;
	bool showHelp;
	bool nolog, log, trace;
	
	void disableLogComponent(string opt, string component) {
		Logger.disableLogComponent(component);
	}
	
	void enableLogComponent(string opt, string component) {
		Logger.enableLogComponent(component);
	}
	
	void addCheat32(string opt, string component) {
		globalCheats.addCheatString(component, 32);
	}
	
	void addTraceThread(string opt, string name) {
		globalCheats.addTraceThread(name);
	}
	
	void loadgpuDump(string opt, string component) {
		//GpuState gpuState; writefln("emptyGpuState: %s", gpuState);
		for (int n = 0; ; n++) {
			string dumpFilename = std.string.format("%s/%d.bin", component, n);
			if (!std.file.exists(dumpFilename)) break;
			GpuOpengl.DumpStruct dumpStruct = GpuOpengl.loadDump(cast(ubyte[])std.file.read(dumpFilename));
			dumpStruct.dump();
		}
		std.c.stdlib.exit(0);
	}
	
	getopt(
		args,
		"help|h|?", &showHelp,
		"sandbox_tests", &doSandboxTests,
		"unit_tests", &doTestsEx,
		"extended_tests", &doTestsEx,
		"nolog", &nolog,
		"isolist", &isolist,
		"trace", &trace,
		"log", &log,
		"nologmod", &disableLogComponent,
		"enlogmod", &enableLogComponent,
		"loadgpu", &loadgpuDump,
		"cheat32", &addCheat32,
		"trace_thread", &addTraceThread
	);
	
	void displayHelp() {
		writefln("DPspEmulator 0.3.1.0 r%d", SvnVersion.revision);
		writefln("");
		writefln("pspemu.exe [<args>] [<file>]");
		writefln("");
		writefln("Arguments:");
		writefln("  --help              - Show this help");
		writefln("  --sandbox_tests     - Run test sandbox code (only for developers)");
		writefln("  --unit_tests        - Run unittests (only for developers)");
		writefln("  --extended_tests    - Run tests on 'tests_ex' folder (only for developers)");
		writefln("  --trace             - Enables cpu tracing at start");
		writefln("  --log               - Enables logging");
		writefln("  --nolog             - Disables logging");
		writefln("  --nologmod=MOD      - Disables logging of a module");
		writefln("  --enlogmod=MOD      - Enables logging of a module");
		writefln("  --trace_thread=NAME - Starts tracing a thread by name");
		writefln("  --cheat32=ADDR:VAL  - Adds a memory write every frame (addresses are relative to 0x08000000, the memory.dump start).");
		writefln("  --isolist           - Allow to list an iso file and (optionally) to extract a single file");
		writefln("  --loadgpu=folder    - Loads a gpu dump and displays it");
		writefln("");
		writefln("Examples:");
		writefln("  pspemu.exe --help");
		writefln("  pspemu.exe --test");
		writefln("  pspemu.exe --isolist mygame.iso");
		writefln("  pspemu.exe --isolist mygame.iso /UMD_DATA.BIN");
		writefln("  pspemu.exe --cheat32=0xB98320:3");
		writefln("  pspemu.exe --trace_thread=\"BGM thread\"");
		writefln("  pspemu.exe \"isos/My Game.cso\"");
		writefln("  pspemu.exe game/EBOOT.PBP");
		writefln("");
	}
	
	if (showHelp) {
		displayHelp();
		return -1;
	}
	
	if (isolist) {
		executeIsoListing(args);
		return 0;
	}

	if (doSandboxTests) {
		executeSandboxTests(args);
		return 0;
	}

	if (doUnitTests) {
		doUnittest();
		return 0;
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
	
	/*if (args.length == 1) {
		OPENFILENAMEW openfl;
		GetOpenFileNameW(&openfl);
	}*/
	
	
	if (nolog) {
		//Logger.setLevel(Logger.Level.WARNING);
		Logger.setLevel(Logger.Level.NONE);
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
	//GuiBase gui = new GuiSdl(emulatorHelper.emulator.hleEmulatorState);
	GuiBase gui = new GuiDfl(emulatorHelper);
	gui.start();
	emulatorHelper.emulator.mainCpuThread.trace = trace;
	if (args.length > 1) {
		emulatorHelper.loadModule(args[1]);
		emulatorHelper.start();
		return 0;
	}
	
	//displayHelp();
	writefln("No specified file to execute");
	return -1;
}

