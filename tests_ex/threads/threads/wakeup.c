/**
 * This feature is used in pspaudio library and probably in a lot of games.
 *
 * It checks also the correct behaviour of semaphores: sceKernelCreateSema, sceKernelSignalSema and sceKernelWaitSema.
 *
 * If new threads are not executed immediately, it would output: 2, 2, -1.
 * It's expected to output 0, 1, -1.
 */
//#pragma compile, "%PSPSDK%/bin/psp-gcc" -I. -I"%PSPSDK%/psp/sdk/include" -L. -L"%PSPSDK%/psp/sdk/lib" -D_PSP_FW_VERSION=150 -Wall -g thread_start.c ../common/emits.c -lpspsdk -lc -lpspuser -lpspkernel -o thread_start.elf
//#pragma compile, "%PSPSDK%/bin/psp-fixup-imports" thread_start.elf

#include <pspsdk.h>
#include <pspkernel.h>
#include <pspthreadman.h>
#include <psploadexec.h>

#define eprintf(...) pspDebugScreenPrintf(__VA_ARGS__); Kprintf(__VA_ARGS__);
//#define eprintf(...) pspDebugScreenPrintf(__VA_ARGS__);

PSP_MODULE_INFO("T.WAKEUP CONCURRENCY TEST", 0, 1, 1);
PSP_MAIN_THREAD_ATTR(THREAD_ATTR_USER | THREAD_ATTR_VFPU);

int sema;
int thid;

static int threadFunction(int args, void* argp) {
	int n;
	for (n = 0; n < 100; n++) {
		sceKernelSleepThreadCB();
	}
	
	eprintf("[1]\n");
	
	sceKernelSignalSema(sema, 1);

	return 0;
}

void testThreads() {
	int n;
	SceUInt timeout = 4 * 1000 * 1000;

	sceKernelStartThread(thid = sceKernelCreateThread("Test Thread", (void *)&threadFunction, 0x12, 0x10000, 0, NULL), 0, NULL);
	sema = sceKernelCreateSema("sema1", 0, 0, 1, NULL);
	
	for (n = 0; n < 100; n++) {
		sceKernelWakeupThread(thid);
	}
	
	sceKernelWaitSemaCB(sema, 1, &timeout);
	sceKernelTerminateDeleteThread(thid);
	
	eprintf("[2]\n");
}

int main(int argc, char **argv) {
	pspDebugScreenInit();

	testThreads();
	
	return 0;
}