module pspemu.hle.kd.sysmem.sceSysEventForKernel; // kd/sysmem.prx (sceSystemMemoryManager)

import pspemu.hle.ModuleNative;

class sceSysEventForKernel : ModuleNative {
}

static this() {
	mixin(ModuleNative.registerModule("sceSysEventForKernel"));
}
