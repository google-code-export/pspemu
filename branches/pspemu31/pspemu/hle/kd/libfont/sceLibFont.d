module pspemu.hle.kd.libfont.sceLibFont;

import pspemu.hle.ModuleNative;
import pspemu.hle.kd.libfont.Types;

class sceLibFont : ModuleNative {
	void initNids() {
        mixin(registerd!(0x67F17ED7, sceFontNewLib));
        mixin(registerd!(0x574B6FBC, sceFontDoneLib));

        mixin(registerd!(0xA834319D, sceFontOpen));
        mixin(registerd!(0xBB8E7FE6, sceFontOpenUserMemory));
        mixin(registerd!(0x57FCB733, sceFontOpenUserFile));
        mixin(registerd!(0x3AEA8CB6, sceFontClose));

        mixin(registerd!(0x27F6E642, sceFontGetNumFontList));
		mixin(registerd!(0x099EF33C, sceFontFindOptimumFont));
        mixin(registerd!(0x681E61A7, sceFontFindFont));

		mixin(registerd!(0x0DA7535E, sceFontGetFontInfo));
        mixin(registerd!(0x5333322D, sceFontGetFontInfoByIndexNumber));

        mixin(registerd!(0xDCC80C2F, sceFontGetCharInfo));
		mixin(registerd!(0x980F4895, sceFontGetCharGlyphImage));
        mixin(registerd!(0xCA1E6945, sceFontGetCharGlyphImage_Clip));
        mixin(registerd!(0xBC75D85B, sceFontGetFontList));
        mixin(registerd!(0xEE232411, sceFontSetAltCharacterCode));
        mixin(registerd!(0x5C3E4A9E, sceFontGetCharImageRect));
        mixin(registerd!(0x472694CD, sceFontPointToPixelH));
        mixin(registerd!(0x48293280, sceFontSetResolution));
        mixin(registerd!(0x3C4B7E82, sceFontPointToPixelV));
        mixin(registerd!(0x74B21701, sceFontPixelToPointH));
        mixin(registerd!(0xF8F0752E, sceFontPixelToPointV));
        mixin(registerd!(0x2F67356A, sceFontCalcMemorySize));
        mixin(registerd!(0x48B06520, sceFontGetShadowImageRect));
        mixin(registerd!(0x568BE516, sceFontGetShadowGlyphImage));
        mixin(registerd!(0x5DCF6858, sceFontGetShadowGlyphImage_Clip));
        mixin(registerd!(0xAA3DE7B5, sceFontGetShadowInfo));
        mixin(registerd!(0x02D7F94B, sceFontFlush));
	}
	
	class FontLibrary {
		this(FontNewLibParams* params) {
			
		}
	}
	
	class Font {
		FontLibrary fontLibrary;
		
		this(FontLibrary fontLibrary) {
			this.fontLibrary = fontLibrary;
		}
		
		Font setByIndex(int index) {
			return this;
		}
		
		Font setByData(ubyte[] data) {
			return this;
		}
		
		Font setByFileName(string fileName) {
			return this;
		}
	}
	
	/**
	 * Creates a new font library.
	 *
	 * @param  params     Parameters of the new library.
	 * @param  errorCode  Pointer to store any error code.
	 *
	 * @return FontLibraryHandle
	 */
	FontLibraryHandle sceFontNewLib(FontNewLibParams* params, uint* errorCode) {
		unimplemented_notice();

		*errorCode = 0;
		
		return uniqueIdFactory.add(new FontLibrary(params));
	}

	/**
	 * Releases the font library.
	 *
	 * @param  libHandle  Handle of the library.
	 *
	 * @return 0 on success
	 */
	int sceFontDoneLib(FontLibraryHandle libHandle) {
		unimplemented();

		return 0;
	}
	
	/**
	 * Opens a new font.
	 *
	 * @param  libHandle  Handle of the library.
	 * @param  index      Index of the font.
	 * @param  mode       Mode for opening the font.
	 * @param  errorCode  Pointer to store any error code.
	 *
	 * @return FontHandle
	 */
	FontHandle sceFontOpen(FontLibraryHandle libHandle, int index, int mode, uint* errorCode) {
		unimplemented_notice();

		*errorCode = 0;
		
		return uniqueIdFactory.add(
			(new Font(uniqueIdFactory.get!FontLibrary(libHandle)))
				.setByIndex(index)
		);
	}

	/**
	 * Opens a new font from memory.
	 *
	 * @param  libHandle         Handle of the library.
	 * @param  memoryFontAddr    Index of the font.
	 * @param  memoryFontLength  Mode for opening the font.
	 * @param  errorCode         Pointer to store any error code.
	 *
	 * @return FontHandle
	 */
	FontHandle sceFontOpenUserMemory(FontLibraryHandle libHandle, void* memoryFontAddr, int memoryFontLength, uint* errorCode) {
		unimplemented_notice();

		*errorCode = 0;
		
		return uniqueIdFactory.add(
			(new Font(uniqueIdFactory.get!FontLibrary(libHandle)))
				.setByData((cast(ubyte *)memoryFontAddr)[0..memoryFontLength])
		);
	}
	
	/**
	 * Opens a new font from a file.
	 *
	 * @param  libHandle  Handle of the library.
	 * @param  fileName   Path to the font file to open.
	 * @param  mode       Mode for opening the font.
	 * @param  errorCode  Pointer to store any error code.
	 *
	 * @return FontHandle
	 */
	FontHandle sceFontOpenUserFile(FontLibraryHandle libHandle, string fileName, int mode, uint* errorCode) {
		unimplemented_notice();
		
		*errorCode = 0;

		return uniqueIdFactory.add(
			(new Font(uniqueIdFactory.get!FontLibrary(libHandle)))
				.setByFileName(fileName)
		);
	}

	/**
	 * Closes the specified font file.
	 *
	 * @param  fontHandle  Handle of the font.
	 *
	 * @return 0 on success.
	 */
	int sceFontClose(FontHandle fontHandle) {
		unimplemented();

		return 0;
	}

	/**
	 * Returns the number of available fonts.
	 *
	 * @param  libHandle  Handle of the library.
	 * @param  errorCode  Pointer to store any error code.
	 *
	 * @return Number of fonts
	 */
	int sceFontGetNumFontList(FontLibraryHandle libHandle, uint* errorCode) {
		unimplemented();

		return 0;		
	}

	/**
	 * Returns a font index that best matches the specified FontStyle.
	 *
	 * @param  libHandle  Handle of the library.
	 * @param  fontStyle  Family, style and 
	 * @param  errorCode  Pointer to store any error code.
	 *
	 * @return Font index
	 */
	int sceFontFindOptimumFont(FontLibraryHandle libHandle, FontStyle* fontStyle, uint* errorCode) {
		unimplemented();

		*errorCode = 0;
		return 0;
	}

	/**
	 * Returns a font index that best matches the specified FontStyle.
	 *
	 * @param  libHandle  Handle of the library.
	 * @param  fontStyle  Family, style and language.
	 * @param  errorCode  Pointer to store any error code.
	 *
	 * @return Font index
	 */
	int sceFontFindFont(FontLibraryHandle libHandle, FontStyle* fontStyle, uint* errorCode) {
		unimplemented();

		*errorCode = 0;
		return 0;
	}

	/**
	 * Obtains the FontInfo of a FontHandle.
	 *
	 * @param  fontHandle  Font Handle to get the information from.
	 * @param  fontInfo    Pointer to a FontInfo structure that will hold the information.
	 *
	 * @return 0 on success
	 */
	int sceFontGetFontInfo(FontHandle fontHandle, FontInfo* fontInfo) {
		unimplemented_notice();

		return 0;
	}
	
	/**
	 * Obtains the FontInfo of a Font with its index.
	 *
	 * @param  libHandle  Handle of the library.
	 * @param  fontInfo   Pointer to a FontInfo structure that will hold the information.
	 * @param  unknown    ???
	 * @param  fontIndex  Index of the font to get the information from.
	 *
	 * @return 0 on success
	 */
	int sceFontGetFontInfoByIndexNumber(FontLibraryHandle libHandle, FontInfo* fontInfo, int unknown, int fontIndex) {
		unimplemented();

		return 0;
	}
	
    void sceFontGetCharInfo() { unimplemented(); }
	void sceFontGetCharGlyphImage() { unimplemented(); }
    void sceFontGetCharGlyphImage_Clip() { unimplemented(); }
    void sceFontGetFontList() { unimplemented(); }
    void sceFontSetAltCharacterCode() { unimplemented(); }
    void sceFontGetCharImageRect() { unimplemented(); }
    void sceFontPointToPixelH() { unimplemented(); }
    void sceFontSetResolution() { unimplemented(); }
    void sceFontPointToPixelV() { unimplemented(); }
    void sceFontPixelToPointH() { unimplemented(); }
    void sceFontPixelToPointV() { unimplemented(); }
    void sceFontCalcMemorySize() { unimplemented(); }
    void sceFontGetShadowImageRect() { unimplemented(); }
    void sceFontGetShadowGlyphImage() { unimplemented(); }
    void sceFontGetShadowGlyphImage_Clip() { unimplemented(); }
    void sceFontGetShadowInfo() { unimplemented(); }
    void sceFontFlush() { unimplemented(); }

}

static this() {
	mixin(ModuleNative.registerModule("sceLibFont"));
}
