module pspemu.core.gpu.GpuState;

import std.conv;

import pspemu.core.gpu.Types;

import pspemu.core.Memory;
import pspemu.core.gpu.Types;
import pspemu.utils.MathUtils;
import pspemu.utils.StructUtils;
import pspemu.utils.String;
//import pspemu.utils.Utils;

import pspemu.hle.kd.ge.Types;

import std.bitmanip;

/*
enum TextureMapMode {
	GU_TEXTURE_COORDS  = 0,
	GU_TEXTURE_MATRIX  = 1,
	GU_ENVIRONMENT_MAP = 2,
}

enum TextureProjectionMapMode {
	GU_POSITION          = 0,
	GU_UV                = 1,
	GU_NORMALIZED_NORMAL = 2,
	GU_NORMAL            = 3,
}
*/

/* Texture Projection Map Mode */

enum TransformMode {
	Normal = 0,
	Raw    = 1,
}

struct ClutState {
	uint address;
	PixelFormats format;
	uint shift;
	uint mask;
	uint start;
	//ubyte[] data;
	ubyte* data;

	int colorEntrySize() { return PixelFormatSize(format, 1); }
	int blocksSize(int num_blocks) {
		return PixelFormatSize(format, num_blocks * 8);
	}
	string hash() {
		return cast(string)(cast(ubyte*)cast(void*)&this)[0..data.offsetof];
		//return toString;
	}
	string toString() {
		return std.string.format("ClutState(addr=%08X, format=%d, shift=%d, mask=%d, start=%d)", address, format, shift, mask, start);
	}
}

struct ScreenBuffer {
	union {
		uint _address;
		struct { mixin(bitfields!(
			uint, "lowAddress" , 24,
			uint, "highAddress", 8
		)); }
	}
	uint width = 512;
	PixelFormats format = PixelFormats.GU_PSM_8888;
	uint loadAddress, storeAddress;
	uint address(uint _address) { return this._address = _address; }
	uint address() { return (0x04_000000 | this._address); }
	uint addressEnd() { return address + width * 272 * pixelSize; }
	uint pixelSize() { return PixelFormatSizeMul[format]; }
	ubyte[] row(void* ptr, int row) {
		int rowsize = PixelFormatSize(format, width);
		return ((cast(ubyte *)ptr) + rowsize * row)[0..rowsize];
	}
	bool isAnyAddressInBuffer(uint[] ptrList) {
		foreach (ptr; ptrList) {
			if ((ptr >= address) && (ptr < addressEnd)) return true;
		}
		return false;
	}
}

struct TextureTransfer {
	enum TexelSize { BIT_16 = 0, BIT_32 = 1 }
	//enum TexelSize { BIT_32 = 0, BIT_16 = 1 }
	
	uint srcAddress, dstAddress;
	ushort srcLineWidth, dstLineWidth;
	ushort srcX, srcY, dstX, dstY;
	ushort width, height;
	TexelSize texelSize;
	
	uint bpp() { return (texelSize == TexelSize.BIT_16) ? 2 : 4; }
	
	string toString() {
		return std.string.format(
			"TextureTransfer("
			"Size(%d, %d) : "
			"SRC(addr=%08X, w=%d, XY(%d, %d))"
			"-"
			"DST(addr=%08X, w=%d, XY(%d, %d))"
			") : Bpp:%s",
			width, height,
			srcAddress, srcLineWidth, srcX, srcY,
			dstAddress, dstLineWidth, dstX, dstY,
			bpp
		);
	}
}

struct LightState {
	struct Attenuation {
		float constant, linear, quadratic;
		
		string toString() {
			return std.string.format(
				"Attenuation(constant=%f, linear=%f, quadratic=%f)",
				constant, linear, quadratic
			);
		}
	}
	bool enabled = false;
	LightType type;
	LightModel kind;
	Vector position, spotDirection;
	Attenuation attenuation;
	float spotExponent;
	float spotCutoff;
	Colorf ambientColor, diffuseColor, specularColor;
	
	string toString() {
		if (!enabled) return std.string.format("LightState(enabled = false)");
		
		return std.string.format(
			"LightState(\n"
			"    enabled       = %s\n"
			"    type          = %s\n"
			"    kind          = %s\n"
			"    position      = %s\n"
			"    spotDirection = %s\n"
			"    attenuation   = %s\n"
			"    spotExponent  = %f\n"
			"    spotCutoff    = %f\n"
			"    ambientColor  = %s\n"
			"    diffuseColor  = %s\n"
			"    specularColor = %s\n"
			")\n"
			, enabled
			, to!string(type)
			, to!string(kind)
			, position
			, spotDirection
			, attenuation
			, spotExponent
			, spotCutoff
			, ambientColor
			, diffuseColor
			, specularColor
		);
	}
}

static struct VertexState {
	float u = 0.0, v = 0.0;        // Texture coordinates.
	float r = 0.0, g = 0.0, b = 0.0, a = 0.0;  // Color components.
	float nx = 0.0, ny = 0.0, nz = 0.0;  // Normal vector.
	float px = 0.0, py = 0.0, pz = 0.0;  // Position vector.
	float weights[8] = [1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0];  // Weights for skinning
	
	float[] floatValues() {
		return (&u)[0..20];
	} 

	// Getters
	Vector p () { return Vector(px, py, pz); }
	Vector n () { return Vector(nx, ny, nz); }
	Vector uv() { return Vector(u, v); }

	// Setters
	Vector p (Vector vec) { px = vec.x; py = vec.y; pz = vec.z; return vec; }
	Vector n (Vector vec) { nx = vec.x; ny = vec.y; nz = vec.z; return vec; }
	Vector uv(Vector vec) { u  = vec.x; v  = vec.y; return vec; }

	// Aliases
	alias p position;
	alias n normal;
	
	string toString() {
		return std.string.format(
			"VertexState(UV=%f,%f)(RGBA:%02X%02X%02X%02X)(NXYZ=%f,%f,%f)(PXYZ=%f,%f,%f)",
			u, v,
			cast(uint)(r * 255), cast(uint)(g * 255), cast(uint)(b * 255), cast(uint)(a * 255),
			nx, ny, nz,
			px, py, pz
		);
	}
}

/*static struct VertexStateArrays {
	UV[]       textureArray;
	float[4][] colorArray;
	float[3][] normalArray;
	float[3][] positionArray;
	float[8][] weights;

	void reserve(int count) {
		if (textureArray.length < count) {
			textureArray.length  = count;
			colorArray.length    = count;
			normalArray.length   = count;
			positionArray.length = count;
			weights.length       = count;
		}
	}
}*/

struct Viewport {
	float px, py, pz;
	float sx, sy, sz;
	
	string toString() {
		return std.string.format("Viewport(%f, %f, %f)(%f, %f, %f)", px, py, pz, sx, sy, sz);
	}
}

struct TextureState {
	// Format of the texture data.
	bool           swizzled;              /// Is texture swizzled?
	PixelFormats   format;                /// Texture Data mode

	// Normal attributes
	TextureFilter  filterMin, filterMag;  /// TextureFilter when drawing the texture scaled
	WrapMode       wrapU, wrapV;          /// Wrap mode when specifying texture coordinates beyond texture size
	UV             scale;                 /// 
	UV             offset;                ///
	TextureMapMode mapMode;
	TextureProjectionMapMode projMapMode; 
	uint[2]        texShade;

	// Effects
	TextureEffect  effect;                /// 
	TextureColorComponent colorComponent; ///
	bool           fragment_2x;           /// ???

	// Mimaps
	struct MipmapState {
		uint address;                     /// Pointer 
		uint buffer_width;                ///
		uint width, height;               ///
	}
	int            mipmapMaxLevel;        /// Levels of mipmaps
	bool           mipmapShareClut;       /// Mipmaps share clut?
	MipmapState[8] mipmaps;               /// MipmapState list

	int mipmapRealWidth(int mipmap = 0) { return PixelFormatSize(format, mipmaps[mipmap].buffer_width); }
	int mipmapTotalSize(int mipmap = 0) { return mipmapRealWidth(mipmap) * mipmaps[mipmap].height; }

	string hash() { return cast(string)TA(this); }
	//string toString() { return std.string.format("TextureState(addr=%08X, size(%dx%d), bwidth=%d, format=%d, swizzled=%d)", address, width, height, buffer_width, format, swizzled); }

	int address() { return mipmaps[0].address; }
	int buffer_width() { return mipmaps[0].buffer_width; }
	int width() { return mipmaps[0].width; }
	int height() { return mipmaps[0].height; }
	bool hasPalette() { return (format >= PixelFormats.GU_PSM_T4 && format <= PixelFormats.GU_PSM_T32); }
	uint paletteRequiredComponents() { return hasPalette ? (1 << (4 + (format - PixelFormats.GU_PSM_T4))) : 0; }
	
	string toString() {
		return std.string.format(
			"TextureState(\n"
			"    swizzled    =%s\n"
			"    format      =%s\n"
			"    ...\n"
			")\n"
			, swizzled
			, to!string(format)
		);
	}
}

struct Patch {
	float div_s;
	float div_t;
}

struct FogState {
	bool enabled;
	Colorf color;
	float  dist, end;
	float  density; // 0.1
	int    mode;
	int    hint;
	
	string toString() {
		if (!enabled) return "FogState(enabled:false)";
		return std.string.format("FogState(enabled:%s, color:%s, dist:%f, end:%f, density:%f, mode:%d, hint:%d)", enabled, color, dist, end, density, mode, hint);
	}
}

struct DepthState {
	bool testEnabled;        // depth (Z) Test Enable (GL_DEPTH_TEST)
	TestFunction testFunc; // TestFunction.GU_ALWAYS
	float rangeNear, rangeFar; // 0.0 - 1.0
	ushort mask;
	
	string toString() {
		return std.string.format(
			"DepthState(testEnabled:%s, testFunc=%s, range(%f-%f), mask=%04X"
			, testEnabled
			, to!string(testFunc)
			, rangeNear, rangeFar
			, mask
		);
	}
}

struct BlendState {
	// Blending.
	bool enabled;       // Alpha Blend Enable (GL_BLEND)
	BlendingOp     equation;
	BlendingFactor funcSrc;
	BlendingFactor funcDst;
	Colorf fixColorSrc, fixColorDst;

	string toString() {
		if (!enabled) return std.string.format("BlendState(enabled: %s)", false);

		return std.string.format(
			"BlendState(enabled: %s, equation: %s, funcSrc: %s, funcDst: %s, fixColorSrc: %s, fixColorDst: %s)",
			enabled, to!string(equation), to!string(funcSrc), to!string(funcDst), fixColorSrc, fixColorDst
		);
	}
}

struct AlphaTestState {
	bool enabled;        // Alpha Test Enable (GL_ALPHA_TEST) glAlphaFunc(GL_GREATER, 0.03f);
	TestFunction func; // TestFunction.GU_ALWAYS
	float value;
	ubyte mask; // 0xFF
	
	string toString() {
		if (!enabled) return "AlphaTestState(enabled:false)";
		return std.string.format(
			"AlphaTestState(enabled:%s, func:%s, value:%f, mask:%02X)"
			, enabled
			, to!string(func)
			, value
			, mask
		);
	}
}

struct StencilState {
	bool testEnabled;      // Stencil Test Enable (GL_STENCIL_TEST)
	TestFunction funcFunc;
	ubyte funcRef;
	ubyte funcMask; // 0xFF
	StencilOperations operationSfail;
	StencilOperations operationDpfail;
	StencilOperations operationDppass;
	string toString() {
		if (!testEnabled) return std.string.format("StencilState(enabled: %s)", false);
		return std.string.format(
			"StencilState(enabled: %s, funcFunc:%s, funcRef:%02X, funcMask:%02X, opSfail:%s, opDpfail:%s, opDppass:%s)",
			testEnabled, to!string(funcFunc), funcRef, funcMask, to!string(operationSfail), to!string(operationDpfail), to!string(operationDppass)
		);
	}
}

struct LogicalOperationState {
	bool enabled;
	LogicalOperation operation; // LogicalOperation.GU_COPY
	string toString() {
		if (!enabled) return std.string.format("LogicalOperationState(enabled: %s)", false);
		return std.string.format(
			"LogicalOperationState(enabled: %s, operation:%s)",
			enabled, to!string(operation),
		);
	}
}

struct LightingState {
	bool enabled;         // Lighting Enable (GL_LIGHTING)
	LightModel lightModel;
	Colorf ambientLightColor;
	float  specularPower;
	LightState[4] lights;

	string toString() {
		if (!enabled) return std.string.format("LightingState(enabled: %s)", false);
		return std.string.format(
			"LightingState(\n",
			"    enabled: %s\n"
			"    lightModel: %s\n"
			"    ambientLightColor: %s\n"
			"    specularPower: %f\n"
			"    lights[0]: %s\n"
			"    lights[1]: %s\n"
			"    lights[2]: %s\n"
			"    lights[3]: %s\n"
			")\n"
			, enabled
			, to!string(lightModel)
			, ambientLightColor
			, specularPower
			, lights[0]
			, lights[1]
			, lights[2]
			, lights[3]
		);
	}
}

static struct GpuState {
	Memory memory;
	uint baseAddress, vertexAddress, indexAddress;
	ScreenBuffer drawBuffer, depthBuffer;
	TextureTransfer textureTransfer;
	
	union {
		//PspGeContext RealState;
		uint[512] RealState;
		struct {
			VertexType vertexType; // here because of transform2d
			Viewport viewport;
			uint offsetX, offsetY;
			bool toggleUpdateState;

			ClearBufferMask clearFlags;
			bool clearingMode;

			Colorf ambientModelColor, diffuseModelColor, specularModelColor, emissiveModelColor;
			Colorf textureEnviromentColor;
			LightComponents materialColorComponents;
			
			// Matrix.
			Matrix projectionMatrix, worldMatrix, viewMatrix, textureMatrix;
			Matrix[8] boneMatrix;
			uint boneMatrixIndex;
			Patch patch;
			
			// Textures.
			// Temporal values.
			TransformMode transformMode;
			
			TextureState texture;
			ClutState uploadedClut;
			ClutState clut;

			Rect scissor;
			FrontFaceDirection frontFaceDirection;
			ShadingModel shadeModel;

			float[8] morphWeights;

			// State.
			bool textureMappingEnabled;   // Texture Mapping Enable (GL_TEXTURE_2D)
			bool clipPlaneEnabled;        // Clip Plane Enable (GL_CLIP_PLANE0)
			bool backfaceCullingEnabled;  // Backface Culling Enable (GL_CULL_FACE)
			bool ditheringEnabled;
			bool lineSmoothEnabled;
			bool colorTestEnabled;
			bool patchCullEnabled;

			LightingState   lighting;
			FogState        fog;
			BlendState      blend;
			DepthState      depth;
			AlphaTestState  alphaTest;
			StencilState    stencil;
			LogicalOperationState logicalOperation;
			
			ubyte[4] colorMask; // [0xFF, 0xFF, 0xFF, 0xFF];
		}
	}
	
	// Size of the inner state if less than PspGeContext.sizeof
	static assert((colorMask.offsetof + colorMask.sizeof - vertexType.offsetof) <= PspGeContext.sizeof);
	
	// RealState ends the struct
	static assert (this.RealState.offsetof + this.RealState.sizeof == this.sizeof);
	
	string toString() {
		return std.string.format(
			"GpuState(\n"
			"    baseAddress      =%08X;\n"
			"    vertexAddress    =%08X;\n"
			"    indexAddress     =%08X;\n"
			"    textureTransfer  =%s\n"
			"    viewport         =%s\n"
			"    offset           =(%d, %d)\n"
			"    clearFlags       =(%s)\n"
			"    ambientModelColor=(%s)\n"
			"    diffuseModelColor=(%s)\n"
			"    specularModelColor=(%s)\n"
			"    emissiveModelColor=(%s)\n"
			"    textureEnviromentColor=(%s)\n"
			"    materialColorComponents=(%s)\n"
			"    fog               =%s\n"
			"    projectionMatrix  =%s\n"
			"    worldMatrix       =%s\n"
			"    viewMatrix        =%s\n"
			"    textureMatrix     =%s\n"
			"    transformMode     =%s\n"
			"    texture           =%s\n"
			"    uploadedClut      =%s\n"
			"    clut              =%s\n"
			"    scissor           =%s\n"
			"    frontFaceDirection=%s\n"
			"    shadeModel        =%s\n"
			"    textureMappingEnabled   = %s\n"
			"    clipPlaneEnabled        = %s\n"
			"    backfaceCullingEnabled  = %s\n"
			"    ditheringEnabled        = %s\n"
			"    lineSmoothEnabled       = %s\n"
			"    colorTestEnabled        = %s\n"
			"    patchCullEnabled        = %s\n"
			"    lighting                = %s\n"
			"    blend                   = %s\n"
			"    depth                   = %s\n"
			"    alphaTest               = %s\n"
			"    stencil                 = %s\n"
			"    logicalOperation        = %s\n"
			"    colorMask               = %s\n"
			")"
			, baseAddress
			, vertexAddress
			, indexAddress
			, textureTransfer
			, viewport
			, offsetX, offsetY
			, toSet(clearFlags)
			, ambientModelColor
			, diffuseModelColor
			, specularModelColor
			, emissiveModelColor
			, textureEnviromentColor
			, toSet(materialColorComponents)
			, fog
			, projectionMatrix, worldMatrix, viewMatrix, textureMatrix
			, to!string(transformMode)
			, texture
			, uploadedClut
			, clut
			, scissor
			, to!string(frontFaceDirection)
			, shadeModel
			, textureMappingEnabled
			, clipPlaneEnabled
			, backfaceCullingEnabled
			, ditheringEnabled
			, lineSmoothEnabled
			, colorTestEnabled
			, patchCullEnabled
			, lighting
			, blend
			, depth
			, alphaTest
			, stencil
			, logicalOperation
			, colorMask
		);
	}
}

struct PrimitiveFlags {
	bool hasWeights;
	bool hasTexture;
	bool hasColor;
	bool hasNormal;
	bool hasPosition;
	int  numWeights;
	
	string toString() {
		return std.string.format(
			"PrimitiveFlags(hasWeights=%d,hasTexture=%d,hasColor=%d,hasNormal=%d,hasPosition=%d,numWeights=%d)",
			hasWeights,
			hasTexture,
			hasColor,
			hasNormal,
			hasPosition,
			numWeights
		);
	}
}
