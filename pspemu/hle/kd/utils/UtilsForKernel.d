module pspemu.hle.kd.utils.UtilsForKernel; // kd/utils.prx (sceKernelUtils)

//debug = DEBUG_SYSCALL;

import pspemu.hle.ModuleNative;
import pspemu.hle.kd.utils.UtilsForUser;

class UtilsForKernel : UtilsForUser {
}

static this() {
	mixin(ModuleNative.registerModule("UtilsForKernel"));
}
