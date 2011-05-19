module pspemu.hle.kd.modulemgr.ModuleMgrForKernel; // kd/modulemgr.prx (sceModuleManager)

import pspemu.hle.ModuleNative;

import pspemu.hle.kd.modulemgr.ModuleMgrForUser;

class ModuleMgrForKernel : ModuleMgrForUser {
}

static this() {
	mixin(ModuleNative.registerModule("ModuleMgrForKernel"));
}