#include <pspkernel.h>
#include <pspdisplay.h>
#include <pspdebug.h>
#include <stdlib.h>
#include <stdio.h>
#include <math.h>
#include <string.h>
#include <time.h>

#include <pspgu.h>
#include <pspdisplay.h>

PSP_MODULE_INFO("ge test", 0, 1, 1);
PSP_MAIN_THREAD_ATTR(THREAD_ATTR_USER);

static unsigned int __attribute__((aligned(16))) list[262144];

typedef struct {
	char u, v;
	unsigned int color;
	char x, y, z;
} VertexType1;

typedef struct {
	char u, v;
	char x, y, z;
} VertexType2;

#define BUILD_COL(COLOR) 0xFF##COLOR

unsigned int clut16[16] = {
	BUILD_COL(000000),
	BUILD_COL(111111),
	BUILD_COL(222222),
	BUILD_COL(333333),
	BUILD_COL(444444),
	BUILD_COL(555555),
	BUILD_COL(666666),
	BUILD_COL(777777),
	BUILD_COL(888888),
	BUILD_COL(999999),
	BUILD_COL(AAAAAA),
	BUILD_COL(BBBBBB),
	BUILD_COL(CCCCCC),
	BUILD_COL(DDDDDD),
	BUILD_COL(EEEEEE),
	BUILD_COL(FFFFFF),
};

unsigned char tex4_4[4 * 4] = {
	 0,  1,  2,  3,
	 4,  5,  6,  7,
	 8,  9, 10, 11,
	12, 13, 14, 15
};

void dumpPixels(int dx, int dy, int w, int h) {
	int x, y;
	unsigned int *pixels;
	int bufferWidth;
	int pixelformat;
	sceDisplayGetFrameBuf((void **)&pixels, &bufferWidth, &pixelformat, PSP_DISPLAY_SETBUF_IMMEDIATE);
	
	for (x = 0; x < w; x++) {
		for (y = 0; y < h; y++) {
			Kprintf("%04X,", pixels[(bufferWidth * (y + dy)) + (x + dx)]);
		}
		Kprintf("\n");
	}
}

VertexType1 buildVertexType1(unsigned int color, char u, char v, char x, char y, char z) {
	VertexType1 vt;
	vt.color = color;
	vt.u = u; vt.v = v;
	vt.x = x; vt.y = y; vt.z = z;
	return vt;
}

VertexType2 buildVertexType2(char u, char v, char x, char y, char z) {
	VertexType2 vt;
	vt.u = u; vt.v = v;
	vt.x = x; vt.y = y; vt.z = z;
	return vt;
}

// Every vertex has to be aligned to the maxium size of all of its component.
/**
 * Checks that engine is considering the vertex alignment.
 * Try to avoid regressions since the fix of the alignment at revision 252.
 */
void testVertexAlignment() {
	int vertexCount = 2;
	VertexType1* vertices = (VertexType1 *)sceGuGetMemory(vertexCount * sizeof(VertexType1));
	vertices[0] = buildVertexType1(0xFF0000FF, 0, 0, 0, 0, 0);
	vertices[1] = buildVertexType1(0xFF0000FF, 4, 4, 4, 4, 0);

	Kprintf("testVertexAlignment\n");
	Kprintf("Struct Size: %d\n", sizeof(VertexType1)); // 12

	sceGuStart(GU_DIRECT,list);
	sceGuClear(GU_COLOR_BUFFER_BIT | GU_DEPTH_BUFFER_BIT);
	{
		sceGuEnable(GU_TEXTURE_2D);
		sceGuClutMode(GU_PSM_8888, 0, 0xFF, 0); // 32-bit palette
		sceGuClutLoad((16 / 8), clut16); // upload 32*8 entries (256)
		sceGuTexMode(GU_PSM_T8, 0, 0, 0); // 8-bit image
		sceGuTexImage(0, 4, 4, 4, tex4_4);
		sceGuTexFunc(GU_TFX_REPLACE, GU_TCC_RGB);
		sceGuTexFilter(GU_LINEAR, GU_LINEAR);
		sceGuTexScale(1.0f, 1.0f);
		sceGuTexOffset(0.0f, 0.0f);
		//sceGuAmbientColor(0xffffffff);
	
		sceGuDrawArray(GU_SPRITES, GU_TEXTURE_8BIT | GU_COLOR_8888 | GU_VERTEX_8BIT | GU_TRANSFORM_2D, vertexCount, 0, vertices);
	}
	sceGuFinish();
	sceGuSync(0, 0);
	sceGuSwapBuffers();
	
	dumpPixels(0, 0, 4, 4);
}

void testColorAdd() {
	int vertexCount = 2;
	VertexType2* vertices = (VertexType2 *)sceGuGetMemory(vertexCount * sizeof(VertexType2));
	vertices[0] = buildVertexType2(0, 0, 0, 0, 0);
	vertices[1] = buildVertexType2(4, 4, 4, 4, 0);

	Kprintf("testColorAdd\n");
	
	sceGuStart(GU_DIRECT,list);
	sceGuClear(GU_COLOR_BUFFER_BIT | GU_DEPTH_BUFFER_BIT);
	{
		sceGuDisable(GU_TEXTURE_2D);
		sceGuColor(0xff0000ff);
		sceGuDrawArray(GU_SPRITES, GU_TEXTURE_8BIT | GU_VERTEX_8BIT | GU_TRANSFORM_2D, vertexCount, 0, vertices);
	}
	sceGuFinish();
	sceGuSync(0, 0);

	sceGuStart(GU_DIRECT,list);
	{
		//sceGuColor(0x00000000);

		sceGuEnable(GU_TEXTURE_2D);
		sceGuClutMode(GU_PSM_8888, 0, 0xFF, 0); // 32-bit palette
		sceGuClutLoad((16 / 8), clut16); // upload 32*8 entries (256)
		sceGuTexMode(GU_PSM_T8, 0, 0, 0); // 8-bit image
		sceGuTexImage(0, 4, 4, 4, tex4_4);
		sceGuBlendFunc(GU_ADD, GU_SRC_ALPHA, GU_ONE_MINUS_SRC_ALPHA, 0, 0);
		sceGuTexFunc(GU_TFX_MODULATE, GU_TCC_RGB);
		sceGuTexFilter(GU_LINEAR, GU_LINEAR);
		sceGuTexScale(1.0f, 1.0f);
		sceGuTexOffset(0.0f, 0.0f);
		//sceGuAmbientColor(0xffffffff);
		//sceGuColor(0xffffffff);

		sceGuDrawArray(GU_SPRITES, GU_TEXTURE_8BIT | GU_VERTEX_8BIT | GU_TRANSFORM_2D, vertexCount, 0, vertices);
	}
	sceGuFinish();
	sceGuSync(0, 0);
	sceGuSwapBuffers();
	
	dumpPixels(0, 0, 4, 4);
}

#define BUF_WIDTH (512)
#define SCR_WIDTH (480)
#define SCR_HEIGHT (272)
#define PIXEL_SIZE (4) /* change this if you change to another screenmode */
#define FRAME_SIZE (BUF_WIDTH * SCR_HEIGHT * PIXEL_SIZE)
#define ZBUF_SIZE (BUF_WIDTH * SCR_HEIGHT * 2) /* zbuffer seems to be 16-bit? */

void init() {
	sceKernelDcacheWritebackAll();

	sceGuInit();
	sceGuStart(GU_DIRECT, list);

	sceGuDrawBuffer (GU_PSM_8888, (void*)0, BUF_WIDTH);
	sceGuDispBuffer (SCR_WIDTH, SCR_HEIGHT, (void*)FRAME_SIZE,BUF_WIDTH);
	sceGuDepthBuffer((void *)(FRAME_SIZE * 2), BUF_WIDTH);
	sceGuOffset     (2048 - (SCR_WIDTH / 2),2048 - (SCR_HEIGHT / 2));
	sceGuViewport   (2048, 2048, SCR_WIDTH, SCR_HEIGHT);
	sceGuDepthRange (0xc350, 0x2710);
	sceGuScissor    (0, 0, SCR_WIDTH, SCR_HEIGHT);
	sceGuEnable     (GU_SCISSOR_TEST);
	sceGuFrontFace  (GU_CW);
	sceGuClear      (GU_COLOR_BUFFER_BIT | GU_DEPTH_BUFFER_BIT);
	sceGuFinish     ();
	sceGuSync       (0, 0);

	sceDisplayWaitVblankStart();
	sceGuDisplay(GU_TRUE);
}

int main(int argc, char *argv[]) {
	init();
	testVertexAlignment();
	testColorAdd();
	return 0;
}