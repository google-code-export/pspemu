module pspemu.hle.kd.loadexec.LoadExecForKernel; // kd/loadexec.prx (sceLoadExec)

import pspemu.hle.ModuleNative;

import pspemu.hle.kd.loadexec.LoadExecForUser; // kd/loadexec.prx (sceLoadExec)

class LoadExecForKernel : LoadExecForUser {
}

static this() {
	mixin(ModuleNative.registerModule("LoadExecForKernel"));
}