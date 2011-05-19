module pspemu.hle.kd.ge.sceGe_user; // kd/ge.prx (sceGE_Manager)

import pspemu.core.gpu.Gpu;
import pspemu.core.gpu.DisplayList;
import pspemu.hle.ModuleNative;

import pspemu.hle.kd.ge.sceGe_driver; // kd/ge.prx (sceGE_Manager)

class sceGe_user : sceGe_driver {
}

static this() {
	mixin(ModuleNative.registerModule("sceGe_user"));
}