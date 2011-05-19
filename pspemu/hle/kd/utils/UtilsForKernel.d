module pspemu.hle.kd.utils.UtilsForKernel; // kd/utils.prx (sceKernelUtils)

//debug = DEBUG_SYSCALL;

import pspemu.core.cpu.CpuThreadBase;

import pspemu.hle.Module;
import pspemu.hle.ModuleNative;

import pspemu.hle.kd.Types;

import std.random;
import std.c.time;
import std.c.stdio;
import std.c.stdlib;
import std.c.time;
import std.md5;
import std.c.windows.windows;

import pspemu.hle.kd.utils.UtilsForUser;

class UtilsForKernel : UtilsForUser {
}

static this() {
	mixin(ModuleNative.registerModule("UtilsForKernel"));
}
