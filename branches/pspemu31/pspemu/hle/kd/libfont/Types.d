module pspemu.hle.kd.libfont.Types;

public import pspemu.hle.kd.Types;

alias uint FontLibraryHandle;
alias uint FontHandle;

struct FontNewLibParams {
	uint* userDataAddr;
	uint  numFonts;
	uint* cacheDataAddr;

	// Driver callbacks.
	uint* allocFuncAddr;
	uint* freeFuncAddr;
	uint* openFuncAddr;
	uint* closeFuncAddr;
	uint* readFuncAddr;
	uint* seekFuncAddr;
	uint* errorFuncAddr;
	uint* ioFinishFuncAddr;
}

struct FontStyle {
	enum Family : ushort {
		FONT_FAMILY_SANS_SERIF = 1,
		FONT_FAMILY_SERIF      = 2,
	}
	
	enum Style : ushort {
		FONT_STYLE_REGULAR     = 1,
		FONT_STYLE_ITALIC      = 2,
		FONT_STYLE_BOLD        = 5,
		FONT_STYLE_BOLD_ITALIC = 6,
		FONT_STYLE_DB          = 103, // Demi-Bold / semi-bold
	}
	
	enum Language : ushort {
		FONT_LANGUAGE_JAPANESE = 1,
		FONT_LANGUAGE_LATIN    = 2,
		FONT_LANGUAGE_KOREAN   = 3,
	}

	float    fontH;
	float    fontV;
	float    fontHRes;
	float    fontVRes;
	float    fontWeight;
	Family   fontFamily;
	Style    fontStyle;
	// Check.
	ushort   fontStyleSub;
	Language fontLanguage;
	ushort   fontRegion;
	ushort   fontCountry;
	char[64] fontName;
	char[64] fontFileName;
	uint     fontAttributes;
	uint     fontExpire;
}

struct FontInfo {
    // Glyph metrics (in 26.6 signed fixed-point).
    uint maxGlyphWidthI;
    uint maxGlyphHeightI;
    uint maxGlyphAscenderI;
    uint maxGlyphDescenderI;
    uint maxGlyphLeftXI;
    uint maxGlyphBaseYI;
    uint minGlyphCenterXI;
    uint maxGlyphTopYI;
    uint maxGlyphAdvanceXI;
    uint maxGlyphAdvanceYI;

    // Glyph metrics (replicated as float).
    float maxGlyphWidthF;
    float maxGlyphHeightF;
    float maxGlyphAscenderF;
    float maxGlyphDescenderF;
    float maxGlyphLeftXF;
    float maxGlyphBaseYF;
    float minGlyphCenterXF;
    float maxGlyphTopYF;
    float maxGlyphAdvanceXF;
    float maxGlyphAdvanceYF;
    
    // Bitmap dimensions.
    short maxGlyphWidth;
    short maxGlyphHeight;
    uint  charMapLength;   // Number of elements in the font's charmap.
    uint  shadowMapLength; // Number of elements in the font's shadow charmap.
    
    // Font style (used by font comparison functions).
    FontStyle fontStyle;
    
    ubyte BPP = 4; // Font's BPP.
    ubyte[3] pad;
}

