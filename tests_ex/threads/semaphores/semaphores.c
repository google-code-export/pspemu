#include <pspsdk.h>
#include <pspkernel.h>
#include <pspthreadman.h>
#include <psploadexec.h>

#define eprintf(...) pspDebugScreenPrintf(__VA_ARGS__); Kprintf(__VA_ARGS__);

PSP_MODULE_INFO("THREAD SEMAPHORES TEST", 0, 1, 1);
PSP_MAIN_THREAD_ATTR(THREAD_ATTR_USER | THREAD_ATTR_VFPU);

SceUID sema;

int main(int argc, char **argv) {
	int result;
	SceKernelSemaInfo info;

	pspDebugScreenInit();
	
	sema = sceKernelCreateSema("sema1", 0, 2, 2, NULL);
	
	sceKernelReferSemaStatus(sema, &info);
	
	eprintf("Size          : %d\n", info.size);
	eprintf("Name          : %s\n", info.name);
	eprintf("Attr          : %d\n", info.attr);
	eprintf("initCount     : %d\n", info.initCount);
	eprintf("currentCount  : %d\n", info.currentCount);
	eprintf("maxCount      : %d\n", info.maxCount);
	eprintf("numWaitThreads: %d\n", info.numWaitThreads);
	
	result = sceKernelDeleteSema(sema);
	eprintf("%08X\n", result);
	result = sceKernelDeleteSema(sema);
	eprintf("%08X\n", result);
	
	return 0;
}