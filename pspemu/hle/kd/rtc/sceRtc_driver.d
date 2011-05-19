module pspemu.hle.kd.rtc.sceRtc_driver; // kd/rtc.prx (sceRTC_Service)

import pspemu.hle.ModuleNative;

import pspemu.hle.kd.rtc.sceRtc;

class sceRtc_driver : sceRtc {
}

static this() {
	mixin(ModuleNative.registerModule("sceRtc_driver"));
}