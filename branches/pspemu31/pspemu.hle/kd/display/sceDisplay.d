module pspemu.hle.kd.display.sceDisplay; // kd/display.prx (sceDisplay_Service)

import pspemu.core.cpu.CpuThreadBase;

import core.thread;
import std.c.windows.windows;

import pspemu.hle.Module;
import pspemu.hle.ModuleNative;

import pspemu.hle.kd.display.sceDisplay_driver;

class sceDisplay : sceDisplay_driver { // Flags: 0x40010000
}

static this() {
	mixin(ModuleNative.registerModule("sceDisplay"));
}
