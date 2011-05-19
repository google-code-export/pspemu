module pspemu.hle.kd.sysmem.SysMemForKernel; // kd/sysmem.prx (sceSystemMemoryManager)

import pspemu.hle.ModuleNative;

class SysMemForKernel : ModuleNative {
}

static this() {
	mixin(ModuleNative.registerModule("SysMemForKernel"));
}
