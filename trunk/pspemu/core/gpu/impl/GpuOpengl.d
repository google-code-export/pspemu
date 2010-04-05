module pspemu.core.gpu.impl.GpuOpengl;

// http://www.opengl.org/resources/code/samples/win32_tutorial/wglinfo.c

//version = VERSION_GL_BITMAP_RENDERING;

import std.c.windows.windows;
import std.windows.syserror;
import std.stdio;

import pspemu.utils.Utils;

import std.contracts;

import pspemu.utils.OpenGL;

import pspemu.core.Memory;
import pspemu.core.gpu.Types;
import pspemu.core.gpu.GpuState;
import pspemu.core.gpu.GpuImpl;
import pspemu.utils.Math;

class GpuOpengl : GpuImplAbstract {
	mixin OpenglBase;
	mixin OpenglUtils;

	/// Previous state to check changes in the new state and perform new operations.
	GpuState prevState;
	glProgram program;

	glUniform gla_tex;
	glUniform gla_clut;
	glUniform gla_clutOffset;
	glUniform gla_clutUse;
	glUniform gla_textureUse;
	
	void init() {
		openglInit();
		openglPostInit();
		program = new glProgram();
		program.attach(new glFragmentShader(import("shader.fragment")));
		program.attach(new glVertexShader(import("shader.vertex")));
		program.link();
		//program.use();

		/*
		gla_tex          = program.getUniform("tex");
		gla_clut         = program.getUniform("clut");
		gla_clutOffset   = program.getUniform("clutOffset");
		gla_clutUse      = program.getUniform("clutUse");
		gla_textureUse   = program.getUniform("textureUse");
		*/

		//program.use(0);
	}

	void reset() {
		textureCache = null;
	}

	void startDisplayList() {
		// Here we should invalidate texture cache? and recheck hashes of the textures?
		foreach (texture; textureCache) {
			texture.markForRecheck = true;
		}
	}

	void endDisplayList() {
	}

	void clear() {
		uint flags = 0;
		if (state.clearFlags & 0x100) flags |= GL_COLOR_BUFFER_BIT; // target
		if (state.clearFlags & 0x200) flags |= GL_ACCUM_BUFFER_BIT | GL_STENCIL_BUFFER_BIT; // stencil/alpha
		if (state.clearFlags & 0x400) flags |= GL_DEPTH_BUFFER_BIT; // zbuffer
		glClear(flags);
	}

	void draw(VertexState[] vertexList, PrimitiveType type, PrimitiveFlags flags) {
		/*
		static if (1) {
			writefln("type:%d, vertexcount:%d, flags:%d", type, vertexList.length, flags);
			writefln("  %s", vertexList[0]);
			writefln("  %s", vertexList[1]);
		}
		*/
	
		void putVertex(ref VertexState vertex) {
			if (flags.hasTexture ) glTexCoord2f(vertex.u, vertex.v);
			if (flags.hasColor   ) glColor4f(vertex.r, vertex.g, vertex.b, vertex.a);
			if (flags.hasNormal  ) glNormal3f(vertex.nx, vertex.ny, vertex.nz);
			if (flags.hasPosition) glVertex3f(vertex.px, vertex.py, vertex.pz);
			//writefln("UV(%f, %f)", vertex.u, vertex.v);
			//writefln("POS(%f, %f, %f)", vertex.px, vertex.py, vertex.pz);
		}

		drawBegin();
		{
			switch (type) {
				// Special primitive that doesn't have equivalent in OpenGL.
				// With two points specify a GL_QUAD.
				// http://www.opengl.org/registry/specs/ARB/point_sprite.txt
				// http://cirl.missouri.edu/gpu/glsl_lessons/glsl_geometry_shader/index.html
				case PrimitiveType.GU_SPRITES:
					static string spriteVertexInterpolate(string vx, string vy) {
						string s;
						s ~= "vertex.px = " ~ vx ~ ".px; vertex.py = " ~ vy ~ ".py;";
						s ~= "vertex.nx = " ~ vx ~ ".px; vertex.ny = " ~ vy ~ ".py;";
						s ~= "vertex.u  = " ~ vx ~ ".u ; vertex.v  = " ~ vy ~ ".v;";
						return s;
					}

					glPushAttrib(GL_CULL_FACE);
					{
						glDisable(GL_CULL_FACE);
						glBegin(GL_QUADS);
						{
							for (int n = 0; n < vertexList.length; n += 2) {
								VertexState v1 = vertexList[n + 0], v2 = vertexList[n + 1], vertex = void;
								vertex = v1;
								
								mixin(spriteVertexInterpolate("v1", "v1")); putVertex(vertex);
								mixin(spriteVertexInterpolate("v2", "v1")); putVertex(vertex);
								mixin(spriteVertexInterpolate("v2", "v2")); putVertex(vertex);
								mixin(spriteVertexInterpolate("v1", "v2")); putVertex(vertex);
							}
						}
						glEnd();
					}
					glPopAttrib();
				break;
				// Normal primitives that have equivalent in OpenGL.
				default: {
					glBegin(PrimitiveTypeTranslate[type]);
					{
						foreach (ref vertex; vertexList) putVertex(vertex);
					}
					glEnd();
				} break;
			}
		}
		drawEnd();
	}

	void flush() {
		glFlush();
	}

	void frameLoad(void* buffer) {
		//bitmapData[0..512 * 272] = (cast(uint *)drawBufferAddress)[0..512 * 272];
		glDrawPixels(
			state.drawBuffer.width, 272,
			PixelFormats[state.drawBuffer.format].external,
			PixelFormats[state.drawBuffer.format].opengl,
			buffer
		);
	}
	
	version (VERSION_GL_BITMAP_RENDERING) {
	} else {
		ubyte[4 * 512 * 272] buffer_temp;
	}

	void frameStore(void* buffer) {
		//(cast(uint *)drawBufferAddress)[0..512 * 272] = bitmapData[0..512 * 272];
		glPixelStorei(GL_UNPACK_ALIGNMENT, cast(int)PixelFormats[state.drawBuffer.format].size);
		//writefln("%d, %d", state.drawBuffer.width, 272);
		glReadPixels(
			0, 0, // x, y
			state.drawBuffer.width, 272, // w, h
			PixelFormats[state.drawBuffer.format].external,
			PixelFormats[state.drawBuffer.format].opengl,
			&buffer_temp
		);
		for (int n = 0; n < 272; n++) {
			int m = 271 - n;
			state.drawBuffer.row(buffer, n)[] = state.drawBuffer.row(&buffer_temp, m)[];
		}

		/*
		glReadPixels(
			0, 0, // x, y
			512, 272, // w, h
			GL_RGBA,
			GL_UNSIGNED_INT_8_8_8_8,
			&buffer_temp
		);

		align(1) static struct TGA_HEADER {
			byte  identsize;          // size of ID field that follows 18 byte header (0 usually)
			byte  colourmaptype;      // type of colour map 0=none, 1=has palette
			byte  imagetype;          // type of image 0=none,1=indexed,2=rgb,3=grey,+8=rle packed

			short colourmapstart;     // first colour map entry in palette
			short colourmaplength;    // number of colours in palette
			byte  colourmapbits;      // number of bits per palette entry 15,16,24,32

			short xstart;             // image x origin
			short ystart;             // image y origin
			short width;              // image width in pixels
			short height;             // image height in pixels
			byte  bits;               // image bits per pixel 8,16,24,32
			byte  descriptor;         // image descriptor bits (vh flip bits)
		}

		TGA_HEADER header;
		with (header) {
			imagetype = 2;
			width = 512;
			height = 272;
			bits = 32;
			descriptor = (1 << 5);
		}
		
		std.file.write("temp_buf.tga", TA(header) ~ buffer_temp);
		*/
	}
}

template OpenglUtils() {
	static const uint[] PrimitiveTypeTranslate    = [GL_POINTS, GL_LINES, GL_LINE_STRIP, GL_TRIANGLES, GL_TRIANGLE_STRIP, GL_TRIANGLE_FAN, GL_QUADS/*GU_SPRITE*/];
	static const uint[] TextureEnvModeTranslate   = [GL_MODULATE, GL_DECAL, GL_BLEND, GL_REPLACE, GL_ADD];	
	static const uint[] TestTranslate             = [GL_NEVER, GL_ALWAYS, GL_EQUAL, GL_NOTEQUAL, GL_LESS, GL_LEQUAL, GL_GREATER, GL_GEQUAL];
	static const uint[] StencilOperationTranslate = [GL_KEEP, GL_ZERO, GL_REPLACE, GL_INVERT, GL_INCR, GL_DECR];
	static const uint[] BlendEquationTranslate    = [GL_FUNC_ADD, GL_FUNC_SUBTRACT, GL_FUNC_REVERSE_SUBTRACT, GL_MIN, GL_MAX, GL_FUNC_ADD ];
	static const uint[] BlendFuncSrcTranslate     = [GL_SRC_COLOR, GL_ONE_MINUS_SRC_COLOR, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA, GL_DST_ALPHA, GL_ONE_MINUS_DST_ALPHA, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA, GL_DST_ALPHA, GL_ONE_MINUS_DST_ALPHA, GL_SRC_ALPHA ];
	static const uint[] BlendFuncDstTranslate     = [GL_DST_COLOR, GL_ONE_MINUS_DST_COLOR, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA, GL_DST_ALPHA, GL_ONE_MINUS_DST_ALPHA, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA, GL_DST_ALPHA, GL_ONE_MINUS_DST_ALPHA, GL_ONE_MINUS_SRC_ALPHA ];	
	static const uint[] LogicalOperationTranslate = [GL_CLEAR, GL_AND, GL_AND_REVERSE, GL_COPY, GL_AND_INVERTED, GL_NOOP, GL_XOR, GL_OR, GL_NOR, GL_EQUIV, GL_INVERT, GL_OR_REVERSE, GL_COPY_INVERTED, GL_OR_INVERTED, GL_NAND, GL_SET];

	Texture[uint] textureCache;
	//Clut[uint] clutCache;
	
	void glEnableDisable(int type, bool enable) {
		if (enable) glEnable(type); else glDisable(type);
	}

	Texture getTexture(TextureState textureState, ClutState clutState) {
		Texture texture = void;
		if ((textureState.address in textureCache) is null) {
			texture = new Texture();
			textureCache[textureState.address] = texture;
		} else {
			texture = textureCache[textureState.address];
		}
		texture.update(state.memory, textureState, clutState);
		return texture;
	}

	void drawBegin() {
		void prepareMatrix() {
			if (state.vertexType.transform2D) {
				glMatrixMode(GL_PROJECTION); glLoadIdentity();
				glOrtho(0.0f, 512.0f, 272.0f, 0.0f, -1.0f, 1.0f);
				glMatrixMode(GL_MODELVIEW); glLoadIdentity();
				//writefln("transform");
			} else {
				//writefln("no transform");
				glMatrixMode(GL_PROJECTION); glLoadIdentity();
				glMultMatrixf(state.projectionMatrix.pointer);

				glMatrixMode(GL_MODELVIEW); glLoadIdentity();
				glMultMatrixf(state.viewMatrix.pointer);
				glMultMatrixf(state.worldMatrix.pointer);
			}
			/*
			writefln("Projection:\n%s", state.projectionMatrix);
			writefln("View:\n%s", state.viewMatrix);
			writefln("World:\n%s", state.worldMatrix);
			*/
		}

		void prepareTexture() {
			glEnableDisable(GL_TEXTURE_2D, state.textureMappingEnabled);
			if (!state.textureMappingEnabled) return;

			//glEnable(GL_BLEND);
			glActiveTexture(GL_TEXTURE0);
			glMatrixMode(GL_TEXTURE);
			glLoadIdentity();
			
			if (state.vertexType.transform2D && (state.textureScale.u == 1 && state.textureScale.v == 1)) {
				glScalef(1.0f / state.textures[0].width, 1.0f / state.textures[0].height, 1);
			} else {
				glScalef(state.textureScale.u, state.textureScale.v, 1);
			}
			glTranslatef(state.textureOffset.u, state.textureOffset.v, 0);
			
			if (state.textureMappingEnabled) {
				glEnable(GL_TEXTURE_2D);
				getTexture(state.textures[0], state.clut).bind();
				//writefln("tex0:%s", state.textures[0]);

				glEnable(GL_CLAMP_TO_EDGE);
				glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, state.textureFilterMin ? GL_LINEAR : GL_NEAREST);
				glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, state.textureFilterMag ? GL_LINEAR : GL_NEAREST);
				glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, state.textureWrapS);
				glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, state.textureWrapT);

				glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, TextureEnvModeTranslate[state.textureEnvMode]);

			} else {
				glDisable(GL_TEXTURE_2D);
			}
		}
		
		void prepareStencil() {
			glEnableDisable(GL_STENCIL_TEST, state.stencilTestEnabled);
			if (!state.stencilTestEnabled) return;

			//writefln("%d, %d, %d", state.stencilFuncFunc, state.stencilFuncRef, state.stencilFuncMask);
			glStencilFunc(
				TestTranslate[state.stencilFuncFunc],
				state.stencilFuncRef,
				state.stencilFuncMask
			);
			//glCheckError();

			glStencilOp(
				StencilOperationTranslate[state.stencilOperationSfail ],
				StencilOperationTranslate[state.stencilOperationDpfail],
				StencilOperationTranslate[state.stencilOperationDppass]
			);
			//glCheckError();
		}

		void prepareBlend() {
			glEnableDisable(GL_BLEND, state.alphaBlendEnabled);
			if (!state.alphaBlendEnabled) return;

			glBlendEquation(BlendEquationTranslate[state.blendEquation]);
			glBlendFunc(BlendFuncSrcTranslate[state.blendFuncSrc], BlendFuncDstTranslate[state.blendFuncDst]);
			glShadeModel(state.shadeModel ? GL_SMOOTH : GL_FLAT);
		}

		void prepareColors() {
			glEnableDisable(GL_COLOR_LOGIC_OP, state.logicalOperationEnabled);
			glColor4fv(state.ambientModelColor.ptr);
		}

		void prepareCulling() {
			glEnableDisable(GL_CULL_FACE, state.backfaceCullingEnabled);
			if (!state.backfaceCullingEnabled) return;

			glFrontFace(state.faceCullingOrder ? GL_CW : GL_CCW);
		}

		void prepareScissor() {
			if ((state.scissor.x1 <= 0 && state.scissor.y1 <= 0) && (state.scissor.x2 >= 480 && state.scissor.y2 >= 272)) {
				glDisable(GL_SCISSOR_TEST);
				return;
			}

			glEnable(GL_SCISSOR_TEST);
			glScissor(
				state.scissor.x1,
				272 - state.scissor.y2,
				state.scissor.x2 - state.scissor.x1,
				state.scissor.y2 - state.scissor.y1
			);
		}

		void prepareLogicOp() {
			glLogicOp(LogicalOperationTranslate[state.logicalOperation]);
		}

		// http://jerome.jouvie.free.fr/OpenGl/Tutorials/Tutorial13.php
		void prepareLighting() {
			return; // @TODO. Temporary disabled.

			glEnableDisable(GL_LIGHTING, state.lightingEnabled);
			if (!state.lightingEnabled) return;

			for (int n = 0; n < 4; n++) {
				LightState* light = &state.lights[n];
				glEnableDisable(GL_LIGHT0 + n, light.enabled);

				glLightfv(GL_LIGHT0 + n, GL_POSITION , light.position.pointer);

				glLightfv(GL_LIGHT0 + n, GL_AMBIENT  , light.ambientLightColor.pointer);
				glLightfv(GL_LIGHT0 + n, GL_DIFFUSE  , light.diffuseLightColor.pointer);
				glLightfv(GL_LIGHT0 + n, GL_SPECULAR , light.specularLightColor.pointer);

				// Spot.
				glLightfv(GL_LIGHT0 + n, GL_SPOT_DIRECTION, light.spotDirection.pointer);
				glLightfv(GL_LIGHT0 + n, GL_SPOT_EXPONENT , &light.spotLightExponent);
				glLightfv(GL_LIGHT0 + n, GL_SPOT_CUTOFF   , &light.spotLightCutoff);
			}
		}
		
		prepareMatrix();
		prepareStencil();
		prepareScissor();
		prepareBlend();
		prepareCulling();
		prepareColors();
		prepareTexture();
		prepareLighting();
		prepareLogicOp();
		
		glDepthFunc(TestTranslate[state.depthFunc]);
	}
	
	void drawEnd() {
		prevState = *state;
	}

	struct PixelFormat {
		float size;
		uint  internal;
		uint  external;
		uint  opengl;
	}

	static const auto PixelFormats = [
		PixelFormat(  2, 3, GL_RGB,  GL_UNSIGNED_SHORT_5_6_5_REV),
		PixelFormat(  2, 4, GL_RGBA, GL_UNSIGNED_SHORT_1_5_5_5_REV),
		PixelFormat(  2, 4, GL_RGBA, GL_UNSIGNED_SHORT_4_4_4_4_REV),
		PixelFormat(  4, 4, GL_RGBA, GL_UNSIGNED_INT_8_8_8_8_REV),
		PixelFormat(0.5, 1, GL_COLOR_INDEX, GL_COLOR_INDEX4_EXT),
		PixelFormat(  1, 1, GL_COLOR_INDEX, GL_COLOR_INDEX8_EXT),
		PixelFormat(  2, 4, GL_COLOR_INDEX, GL_COLOR_INDEX16_EXT),
		//PixelFormat(  4, 4, COLOR_INDEX, GL_COLOR_INDEX32_EXT), // Not defined.
		PixelFormat(  4, 4, GL_RGBA, GL_UNSIGNED_INT),
		PixelFormat(  4, 4, GL_RGBA, GL_COMPRESSED_RGBA_S3TC_DXT1_EXT),
		PixelFormat(  4, 4, GL_RGBA, GL_COMPRESSED_RGBA_S3TC_DXT3_EXT),
		PixelFormat(  4, 4, GL_RGBA, GL_COMPRESSED_RGBA_S3TC_DXT5_EXT),
	];
}

template OpenglBase() {
	HWND hwnd;
	HDC hdc;
	HGLRC hrc;
	uint* bitmapData;

	version (VERSION_GL_BITMAP_RENDERING) {
		void openglInit() {
			// http://nehe.gamedev.net/data/lessons/lesson.asp?lesson=41
			// http://msdn.microsoft.com/en-us/library/ms970768.aspx
			// http://www.codeguru.com/cpp/g-m/opengl/article.php/c5587
			// PFD_DRAW_TO_BITMAP
			HBITMAP hbmpTemp;
			PIXELFORMATDESCRIPTOR pfd;
			BITMAPINFO bi;
			
			hdc = CreateCompatibleDC(GetDC(null));

			with (bi.bmiHeader) {
				biSize        = BITMAPINFOHEADER.sizeof;
				biBitCount    = 32;
				biWidth       = 512;
				biHeight      = 272;
				biCompression = BI_RGB;
				biPlanes      = 1;
			}

			hbmpTemp = enforce(CreateDIBSection(hdc, &bi, DIB_RGB_COLORS, cast(void **)&bitmapData, null, 0));
			enforce(SelectObject(hdc, hbmpTemp));

			with (pfd) {
				nSize      = pfd.sizeof;
				nVersion   = 1;
				dwFlags    = PFD_DRAW_TO_BITMAP | PFD_SUPPORT_OPENGL | PFD_SUPPORT_GDI;
				iPixelType = PFD_TYPE_RGBA;
				cDepthBits = pfd.cColorBits = 32;
				iLayerType = PFD_MAIN_PLANE;
			}

			enforce(SetPixelFormat(hdc, enforce(ChoosePixelFormat(hdc, &pfd)), &pfd));

			hrc = enforce(wglCreateContext(hdc));
			openglMakeCurrent();
			glInit();
		}
	} else {
		// http://www.opengl.org/resources/code/samples/win32_tutorial/wglinfo.c
		void openglInit() {
			hwnd = CreateOpenGLWindow(512, 272, PFD_TYPE_RGBA, 0);
			if (hwnd == null) throw(new Exception("Invalid window handle"));

			hdc = GetDC(hwnd);
			hrc = wglCreateContext(hdc);
			openglMakeCurrent();

			glInit();
			//assert(glActiveTexture !is null);

			ShowWindow(hwnd, SW_HIDE);
			//ShowWindow(hwnd, SW_SHOW);
		}
	}

	void openglMakeCurrent() {
		wglMakeCurrent(null, null);
		wglMakeCurrent(hdc, hrc);
		assert(wglGetCurrentDC() == hdc);
		assert(wglGetCurrentContext() == hrc);
	}

	void openglPostInit() {
		glMatrixMode(GL_MODELVIEW ); glLoadIdentity();
		glMatrixMode(GL_PROJECTION); glLoadIdentity();
		glPixelZoom(1, 1);
		glRasterPos2f(-1, 1);
	}

	static HWND CreateOpenGLWindow(int width, int height, BYTE type, DWORD flags) {
		int         pf;
		HDC         hDC;
		HWND        hWnd;
		WNDCLASS    wc;
		PIXELFORMATDESCRIPTOR pfd;
		static HINSTANCE hInstance = null;

		if (!hInstance) {
			hInstance        = GetModuleHandleA(null);
			wc.style         = CS_OWNDC;
			wc.lpfnWndProc   = cast(WNDPROC)&DefWindowProcA;
			wc.cbClsExtra    = 0;
			wc.cbWndExtra    = 0;
			wc.hInstance     = hInstance;
			wc.hIcon         = LoadIconA(null, cast(char*)32517);
			wc.hCursor       = LoadCursorA(null, cast(char*)0);
			wc.hbrBackground = null;
			wc.lpszMenuName  = null;
			wc.lpszClassName = "PSPGE";

			if (!RegisterClassA(&wc)) throw(new Exception("RegisterClass() failed:  Cannot register window class."));
		}

		int dwStyle = WS_OVERLAPPEDWINDOW | WS_CLIPSIBLINGS | WS_CLIPCHILDREN;
		RECT rc;
		rc.top = rc.left = 0;
		rc.right = width;
		rc.bottom = height;
		AdjustWindowRect( &rc, dwStyle, FALSE );  
		hWnd = CreateWindowA("PSPGE", null, dwStyle, rc.left, rc.top, rc.right - rc.left, rc.bottom - rc.top, null, null, hInstance, null);
		if (hWnd is null) throw(new Exception("CreateWindow() failed:  Cannot create a window. : " ~ sysErrorString(GetLastError())));

		hDC = GetDC(hWnd);

		pfd.nSize        = pfd.sizeof;
		pfd.nVersion     = 1;
		pfd.dwFlags      = PFD_DRAW_TO_WINDOW | PFD_SUPPORT_OPENGL | flags;
		pfd.iPixelType   = type;
		pfd.cColorBits   = 32;

		pf = ChoosePixelFormat(hDC, &pfd);

		if (pf == 0) throw(new Exception("ChoosePixelFormat() failed:  Cannot find a suitable pixel format."));

		if (SetPixelFormat(hDC, pf, &pfd) == FALSE) throw(new Exception("SetPixelFormat() failed:  Cannot set format specified."));

		DescribePixelFormat(hDC, pf, PIXELFORMATDESCRIPTOR.sizeof, &pfd);
		ReleaseDC(hDC, hWnd);

		return hWnd;
	}
}

class Texture {
	GLuint gltex;
	bool markForRecheck;
	bool refreshAnyway;
	uint textureHash, clutHash;
	alias GpuOpengl.PixelFormat PixelFormat;
	
	this() {
		glGenTextures(1, &gltex);
		markForRecheck = true;
		refreshAnyway = true;
	}

	~this() {
		glDeleteTextures(1, &gltex);
	}

	void bind() {
		glEnable(GL_TEXTURE_2D);
		glBindTexture(GL_TEXTURE_2D, gltex);
	}

	void update(Memory memory, ref TextureState textureState, ref ClutState clutState) {
		if (markForRecheck || refreshAnyway) {
			ubyte[] emptyBuffer;

			auto textureData = textureState.address ? (cast(ubyte*)memory.getPointer(textureState.address))[0..textureState.totalSize] : emptyBuffer;
			auto clutData    = clutState.address    ? (cast(ubyte*)memory.getPointer(clutState.address))[0..textureState.paletteRequiredComponents] : emptyBuffer;
		
			if (markForRecheck) {
				markForRecheck = false;

				auto currentTextureHash = std.zlib.crc32(textureState.address, textureData);
				if (currentTextureHash != textureHash) {
					textureHash = currentTextureHash;
					refreshAnyway = true;
				}

				auto currentClutHash = std.zlib.crc32(clutState.address, clutData);
				if (currentClutHash != clutHash) {
					clutHash = currentClutHash;
					refreshAnyway = true;
				}
			}
			
			if (refreshAnyway) {
				refreshAnyway = false;
				updateActually(textureData, clutData, textureState, clutState);
				//writefln("texture updated");
			} else {
				//writefln("texture reuse");
			}
		}
	}

	void updateActually(ubyte[] textureData, ubyte[] clutData, ref TextureState textureState, ref ClutState clutState) {
		auto texturePixelFormat = GpuOpengl.PixelFormats[textureState.format];
		auto clutPixelFormat    = GpuOpengl.PixelFormats[clutState.format];
		PixelFormat* pixelFormat;
		static ubyte[] textureDataUnswizzled, textureDataWithPaletteApplied;

		glActiveTexture(GL_TEXTURE0);
		bind();

		// Unswizzle texture.
		if (textureState.swizzled) {
			//writefln("swizzled: %d, %d", textureDataUnswizzled.length, textureData.length);
			if (textureDataUnswizzled.length < textureData.length) textureDataUnswizzled.length = textureData.length;

			unswizzle(textureData, textureDataUnswizzled[0..textureData.length], textureState);
			textureData = textureDataUnswizzled[0..textureData.length];
		}

		if (textureState.hasPalette) {
			int textureSizeWithPaletteApplied = PixelFormatSize(clutState.format, textureState.width * textureState.height);
			//writefln("palette: %d, %d", textureDataWithPaletteApplied.length, textureSizeWithPaletteApplied);
			if (textureDataWithPaletteApplied.length < textureSizeWithPaletteApplied) textureDataWithPaletteApplied.length = textureSizeWithPaletteApplied;
			applyPalette(textureData, clutData, textureDataWithPaletteApplied.ptr, textureState, clutState);
			textureData = textureDataWithPaletteApplied[0..textureSizeWithPaletteApplied];
			pixelFormat = cast(PixelFormat *)&clutPixelFormat;
		} else {
			pixelFormat = cast(PixelFormat *)&texturePixelFormat;
		}

		// @TODO: Check this!
		glPixelStorei(GL_UNPACK_ALIGNMENT, cast(int)pixelFormat.size);
		switch (textureState.format) {
			case PixelFormats.GU_PSM_5650:
				glPixelStorei(GL_UNPACK_ROW_LENGTH, cast(int)(pixelFormat.size * textureState.width));
			break;
			default:
			case PixelFormats.GU_PSM_5551:
			case PixelFormats.GU_PSM_4444:
			case PixelFormats.GU_PSM_8888:
				glPixelStorei(GL_UNPACK_ROW_LENGTH, 0);
			break;
		}

		glTexImage2D(
			GL_TEXTURE_2D,
			0,
			pixelFormat.internal,
			textureState.width,
			textureState.height,
			0,
			pixelFormat.external,
			pixelFormat.opengl,
			textureData.ptr
		);

		//writefln("update(%d) :: %08X, %s, %d", gltex, textureData.ptr, textureState, textureState.totalSize);
	}

	static void unswizzle(ubyte[] inData, ubyte[] outData, ref TextureState textureState) {
		int rowWidth = textureState.rwidth;
		int pitch    = (rowWidth - 16) / 4;
		int bxc      = rowWidth / 16;
		int byc      = textureState.height / 8;

		uint* src = cast(uint*)inData.ptr;
		
		auto ydest = outData.ptr;
		for (int by = 0; by < byc; by++) {
			auto xdest = ydest;
			for (int bx = 0; bx < bxc; bx++) {
				auto dest = cast(uint*)xdest;
				for (int n = 0; n < 8; n++, dest += pitch) {
					*(dest++) = *(src++);
					*(dest++) = *(src++);
					*(dest++) = *(src++);
					*(dest++) = *(src++);
				}
				xdest += 16;
			}
			ydest += rowWidth * 8;
		}
	}

	static void applyPalette(ubyte[] textureData, ubyte[] clutData, ubyte* textureDataWithPaletteApplied, ref TextureState textureState, ref ClutState clutState) {
		uint clutEntrySize = clutState.colorEntrySize;
		void writeValue(uint index) {
			textureDataWithPaletteApplied[0..clutEntrySize] = (clutData.ptr + index * clutEntrySize)[0..clutEntrySize];
			textureDataWithPaletteApplied += clutEntrySize;
		}
		switch (textureState.format) {
			case PixelFormats.GU_PSM_T4:
				foreach (indexes; textureData) {
					writeValue((indexes >> 0) & 0xF);
					writeValue((indexes >> 4) & 0xF);
				}
			break;
			case PixelFormats.GU_PSM_T8: foreach (index; textureData) writeValue(index); break;
			case PixelFormats.GU_PSM_T16: foreach (index; cast(ushort[])textureData) writeValue(index); break;
			case PixelFormats.GU_PSM_T32: foreach (index; cast(uint[])textureData) writeValue(index); break;
		}
	}
}

extern (Windows) {
	bool  SetPixelFormat(HDC, int, PIXELFORMATDESCRIPTOR*);
	bool  SwapBuffers(HDC);
	int   ChoosePixelFormat(HDC, PIXELFORMATDESCRIPTOR*);
	HBITMAP CreateDIBSection(HDC hdc, const BITMAPINFO *pbmi, UINT iUsage, VOID **ppvBits, HANDLE hSection, DWORD dwOffset);
	const uint BI_RGB = 0;
	const uint DIB_RGB_COLORS = 0;
	int DescribePixelFormat(HDC hdc, int iPixelFormat, UINT nBytes, LPPIXELFORMATDESCRIPTOR ppfd);
	LRESULT DefWindowProcA(HWND hWnd, UINT Msg, WPARAM wParam, LPARAM lParam);
	BOOL PostMessageA(HWND hWnd, UINT Msg, WPARAM wParam, LPARAM lParam);
}

pragma(lib, "gdi32.lib");

/*
version (unittest) {
	import core.thread;
}

// cls && dmd ..\..\..\utils\opengl.d ..\types.d -version=TEST_GPUOPENGL -unittest -run GpuOpengl.d
unittest {
	auto gpuImpl = new GpuOpengl;
	(new Thread({
		gpuImpl.init();
	})).start();
}
version (TEST_GPUOPENGL) static void main() {}
*/