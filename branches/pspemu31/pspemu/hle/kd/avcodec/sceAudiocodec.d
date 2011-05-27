module pspemu.hle.kd.avcodec.sceAudiocodec;

import pspemu.hle.ModuleNative;

enum PspAudioCodec {
	PSP_CODEC_AT3PLUS	= (0x00001000),
	PSP_CODEC_AT3		= (0x00001001),
	PSP_CODEC_MP3		= (0x00001002),
	PSP_CODEC_AAC		= (0x00001003),
}

class sceAudiocodec : ModuleNative {
	void initNids() {
		mixin(registerd!(0x9D3F790C, sceAudiocodecCheckNeedMem));
		mixin(registerd!(0x5B37EB1D, sceAudiocodecInit));
		mixin(registerd!(0x70A703F8, sceAudiocodecDecode));
		mixin(registerd!(0x3A20A200, sceAudiocodecGetEDRAM));
		mixin(registerd!(0x29681260, sceAudiocodecReleaseEDRAM));
	}
	
	int sceAudiocodecCheckNeedMem(uint *Buffer, int Type) {
		unimplemented_notice();
		return 0;
	}

	int sceAudiocodecInit(uint *Buffer, int Type) {
		unimplemented_notice();
		return 0;
	}

	int sceAudiocodecDecode(uint *Buffer, int Type) {
		unimplemented_notice();
		return 0;
	}

	int sceAudiocodecGetEDRAM(uint *Buffer, int Type) {
		unimplemented_notice();
		return 0;
	}

	int sceAudiocodecReleaseEDRAM(uint *Buffer) {
		unimplemented_notice();
		return 0;
	}
}

static this() {
	mixin(ModuleNative.registerModule("sceAudiocodec"));
}
