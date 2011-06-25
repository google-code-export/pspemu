#include <pspsdk.h>
#include <pspkernel.h>
#include <stdio.h>
#include <stdlib.h>
#include "libfont.h"

PSP_MODULE_INFO("font test", 0, 1, 1);
PSP_MAIN_THREAD_ATTR(THREAD_ATTR_USER);

static void *Font_Alloc(void *data, u32 size) {
	return malloc(size);
}

static void Font_Free(void *data, void *p){
	free(p);
}

int main(int argc, char *argv[]) {
	FontLibraryHandle libHandle;
	u32 errorCode;
	FontNewLibParams params = { NULL, 4, NULL, Font_Alloc, Font_Free, NULL, NULL, NULL, NULL, NULL, NULL };
	libHandle = sceFontNewLib(&params, &errorCode);
	
	pspDebugScreenInit();
	pspDebugScreenPrintf("sceFontNewLib: %08X, %08X\n", libHandle, errorCode);
	Kprintf("sceFontNewLib: %08X, %08X\n", libHandle, errorCode);

	return 0;
}