module pspemu.hle.kd.sceLibFont;

import pspemu.hle.ModuleNative;

class sceLibFont : ModuleNative {
	void initNids() {
		mixin(registerd!(0x67F17ED7, sceFontNewLib));
		mixin(registerd!(0x099EF33C, sceFontFindOptimumFont));
		mixin(registerd!(0x0DA7535E, sceFontGetFontInfo));
		mixin(registerd!(0x980F4895, sceFontGetCharGlyphImage));
		mixin(registerd!(0xA834319D, sceFontOpen));
		mixin(registerd!(0xDCC80C2F, sceFontGetCharInfo));
	}
	
	void sceFontNewLib() {
		unimplemented_notice();
	}

	void sceFontFindOptimumFont() {
		unimplemented_notice();
	}

	void sceFontGetFontInfo() {
		unimplemented_notice();
	}

	void sceFontGetCharGlyphImage() {
		unimplemented_notice();
	}

	void sceFontOpen() {
		unimplemented_notice();
	}

	void sceFontGetCharInfo() {
		unimplemented_notice();
	}
}

static this() {
	mixin(ModuleNative.registerModule("sceLibFont"));
}
