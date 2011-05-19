module pspemu.hle.kd.sysmem.sceSuspendForUser; // kd/sysmem.prx (sceSystemMemoryManager)

import pspemu.hle.kd.sysmem.sceSuspendForKernel;

import pspemu.hle.ModuleNative;

class sceSuspendForUser : sceSuspendForKernel {
}

static this() {
	mixin(ModuleNative.registerModule("sceSuspendForUser"));
}
