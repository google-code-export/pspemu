//#pragma compile, "%PSPSDK%/bin/psp-gcc" -I. -I"%PSPSDK%/psp/sdk/include" -L. -L"%PSPSDK%/psp/sdk/lib" -D_PSP_FW_VERSION=150 -Wall -g -O0 test.c ../common/emits.c -lpspsdk -lc -lpspuser -lpspkernel -o test.elf
//#pragma compile, "%PSPSDK%/bin/psp-fixup-imports" test.elf

#include <pspkernel.h>
#include <pspthreadman.h>

PSP_MODULE_INFO("THREAD TEST", 0, 1, 1);
PSP_MAIN_THREAD_ATTR(THREAD_ATTR_USER | THREAD_ATTR_VFPU);

int pointer;

SceUID sema;

void vblankCallback(void *value) {
	Kprintf("vblankCallback(%d)\n", *(int *)value);
	sceKernelSignalSema(sema, 1);
}

int main(int argc, char** argv) {
	int value = 7;
	//int cb = sceKernelCreateCallback("vblankCallback", vblankCallback, NULL);
	sceKernelRegisterSubIntrHandler(PSP_DISPLAY_SUBINT, 0, vblankCallback, &value);
	Kprintf("beforeEnableVblankCallback\n");
	sceKernelEnableSubIntr(PSP_DISPLAY_SUBINT, 0);
	Kprintf("afterEnableVblankCallback\n");
	
	sema = sceKernelCreateSema("semaphore", 0, 0, 255, NULL);
	sceKernelWaitSemaCB(sema, 1, NULL);
	
	Kprintf("ended\n");
	
	sceKernelExitGame();
	return 0;
}