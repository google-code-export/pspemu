module pspemu.hle.kd.sc_sascore.sceSasCore;

import pspemu.hle.ModuleNative;

class sceSasCore : ModuleNative {
	void initNids() {
		mixin(registerd!(0x42778A9F, __sceSasInit));
		
		/*
	    mixin(registerd!(0x019B25EB, __sceSasSetADSR));
	    mixin(registerd!(0x267A6DD2, __sceSasRevParam));
	    mixin(registerd!(0x2C8E6AB3, __sceSasGetPauseFlag));
	    mixin(registerd!(0x33D4AB37, __sceSasRevType));
	    mixin(registerd!(0x440CA7D8, __sceSasSetVolume));
	    mixin(registerd!(0x50A14DFC, __sceSasCoreWithMix));
	    mixin(registerd!(0x5F9529F6, __sceSasSetSL));
	    mixin(registerd!(0x68A46B95, __sceSasGetEndFlag));
	    mixin(registerd!(0x74AE582A, __sceSasGetEnvelopeHeight));
	    mixin(registerd!(0x76F01ACA, __sceSasSetKeyOn));
	    mixin(registerd!(0x787D04D5, __sceSasSetPause));
	    mixin(registerd!(0x99944089, __sceSasSetVoice));
	    mixin(registerd!(0x9EC3676A, __sceSasSetADSRmode));
	    mixin(registerd!(0xA0CF2FA4, __sceSasSetKeyOff));
	    mixin(registerd!(0xA3589D81, __sceSasCore));
	    mixin(registerd!(0xAD84D37F, __sceSasSetPitch));
	    mixin(registerd!(0xB7660A23, __sceSasSetNoise));
	    mixin(registerd!(0xCBCD4F79, __sceSasSetSimpleADSR));
	    mixin(registerd!(0xD5A229C9, __sceSasRevEVOL));
	    mixin(registerd!(0xF983B186, __sceSasRevVON));
	    */
	}
	
	void __sceSasInit() {
		logWarning("Not implemented __sceSasInit");
	}
}

static this() {
	mixin(ModuleNative.registerModule("sceSasCore"));
}