module pspemu.hle.kd.ctrl.sceCtrl; // kd/ctrl.prx (sceController_Service)

import pspemu.hle.ModuleNative;
import pspemu.hle.kd.ctrl.Types;

import pspemu.hle.kd.ctrl.sceCtrl_driver; // kd/ctrl.prx (sceController_Service)

class sceCtrl : sceCtrl_driver {
}

static this() {
	mixin(ModuleNative.registerModule("sceCtrl"));
}