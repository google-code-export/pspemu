module pspemu.hle.kd.audio.sceAudio; // kd/audio.prx (sceAudio_Driver)

import pspemu.hle.kd.audio.sceAudio_driver;

import pspemu.hle.ModuleNative;

class sceAudio : sceAudio_driver {
}

static this() {
	mixin(ModuleNative.registerModule("sceAudio"));
}
