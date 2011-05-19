module pspemu.hle.kd.stdio.StdioForKernel; // kd/stdio.prx (sceStdio)

import pspemu.hle.ModuleNative;
import pspemu.hle.kd.stdio.StdioForUser;

class StdioForKernel : StdioForUser {
}

static this() {
	mixin(ModuleNative.registerModule("StdioForKernel"));
}