module pspemu.hle.kd.sc_sascore.sceSasCore;

import pspemu.hle.ModuleNative;

class sceSasCore : ModuleNative {
	void initNids() {
		mixin(registerd!(0x42778A9F, __sceSasInit));
	}
	
	void __sceSasInit() {
		logWarning("Not implemented __sceSasInit");
	}
}

static this() {
	mixin(ModuleNative.registerModule("sceSasCore"));
}