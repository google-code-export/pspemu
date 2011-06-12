module pspemu.hle.kd.libfont.sceLibFont;

import pspemu.hle.ModuleNative;
import pspemu.hle.kd.libfont.Types;

class sceLibFont : ModuleNative {
	void initNids() {
		mixin(registerd!(0x67F17ED7, sceFontNewLib));
		mixin(registerd!(0x099EF33C, sceFontFindOptimumFont));
		mixin(registerd!(0x0DA7535E, sceFontGetFontInfo));
		mixin(registerd!(0x980F4895, sceFontGetCharGlyphImage));
		mixin(registerd!(0xA834319D, sceFontOpen));
		mixin(registerd!(0xDCC80C2F, sceFontGetCharInfo));
		mixin(registerd!(0x27F6E642, sceFontGetNumFontList));
		mixin(registerd!(0xBC75D85B, sceFontGetFontList));
		/*
	    0x574B6FBC:<Not found!>
	    0xBC75D85B:<Not found!>
	    0x3AEA8CB6:<Not found!>
	    0xCA1E6945:<Not found!>
	    */
	}
	
	/**
	 * Creates a new font library.
	 *
	 * @return FontLibraryHandle
	 */
	FontLibraryHandle sceFontNewLib(FontNewLibParams* params, uint* errorCode) {
		FontLibraryHandle fontLibraryHandle = 0;
		*errorCode = 0;
		unimplemented_notice();
		return fontLibraryHandle;
	}

	/**
	 *
	 *
	 * @return Font index
	 */
	int sceFontFindOptimumFont(FontLibraryHandle libHandle, FontStyle* fontStyle, uint* errorCode) {
		*errorCode = 0;
		return 0;
	}

	void sceFontGetFontInfo(FontHandle fontHandle, void* fontInfoAddr) {
		unimplemented_notice();
	}

	void sceFontGetCharGlyphImage() {
		unimplemented_notice();
	}

	/**
	 * Opens a new font
	 *
	 * @return FontHandle
	 */
	FontHandle sceFontOpen(FontLibraryHandle libHandle, int index, int mode, uint* errorCode) {
		uint fontHandle = 0;
		*errorCode = 0;
		unimplemented_notice();
		return fontHandle;
	}

	void sceFontGetCharInfo() {
		unimplemented_notice();
	}
	
	void sceFontGetNumFontList() {
		unimplemented_notice();
	}
	
	void sceFontGetFontList() {
		unimplemented_notice();
	}
}

static this() {
	mixin(ModuleNative.registerModule("sceLibFont"));
}
