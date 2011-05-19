module pspemu.hle.kd.threadman.ThreadManForKernel; // kd/threadman.prx (sceThreadManager)

import pspemu.hle.ModuleNative;

import pspemu.hle.kd.threadman.ThreadManForUser;

/**
 * Library imports for the kernel threading library.
 */
class ThreadManForKernel : ThreadManForUser {
}

static this() {
	mixin(ModuleNative.registerModule("ThreadManForKernel"));
}
