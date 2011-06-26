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

PSP_MODULE_INFO("THREAD TEST", 0, 1, 1);
PSP_MAIN_THREAD_ATTR(THREAD_ATTR_USER | THREAD_ATTR_VFPU);

static int semaphore = 0;

static int threadFunction(int args, void* argp) {
	int local_value = *(int *)argp;

	eprintf("%d, %d\n", args, local_value);

	sceKernelSignalSema(semaphore, 1);
	
	return 0;
}

void testThreads() {
	int n;

	// Create a semaphore for waiting both threads to execute.
	semaphore = sceKernelCreateSema("Semaphore", 0, 0, 2, NULL);
	
	for (n = 0; n < 2; n++) {
		// Create and start a new thread passing a stack local variable as parameter.
		// When sceKernelStartThread, thread is executed immediately, so in a while it has access
		// to the unmodified stack of the thread that created this one and can access n,
		// before it changes its value.
		sceKernelStartThread(
			sceKernelCreateThread("Test Thread", (void *)&threadFunction, 0x12, 0x10000, 0, NULL),
			n, &n
		);
	}

	// Wait until semaphore have been signaled two times (both new threads have been executed).
	sceKernelWaitSema(semaphore, 2, NULL);

	// After both threads have been executed, we will emit a -1 to check that semaphores work fine.
	eprintf("%d\n", -1);
}

int result;
SceUID evid;

void testEvents_thread1(int args, void* argp) {
	eprintf("[1]\n");
	sceKernelDelayThread(1000);
	eprintf("[2]\n");
	result = sceKernelSetEventFlag(evid, 4);
	//sceKernelDelayThread(1000);
	//eprintf("[3]\n");
}

void testEvents() {
	SceUInt timeout = 1000;
	u32 outBits = -1;
	evid = sceKernelCreateEventFlag("test_event", PSP_EVENT_WAITMULTIPLE, 4 | 2, NULL);

	outBits = -1;
	result = sceKernelPollEventFlag(evid, 4 | 2, PSP_EVENT_WAITAND, &outBits);
	eprintf("event: %08X:%d\n", result, outBits);

	outBits = -1;
	result = sceKernelPollEventFlag(evid, 8 | 2, PSP_EVENT_WAITAND, &outBits);
	eprintf("event: %08X:%d\n", result, outBits);

	outBits = -1;
	result = sceKernelPollEventFlag(evid, 8 | 4, PSP_EVENT_WAITOR, &outBits);
	eprintf("event: %08X:%d\n", result, outBits);
	result = sceKernelSetEventFlag(evid, 32 | 16);
	eprintf("event: %08X\n", result);
	result = sceKernelClearEventFlag(evid, ~4);
	eprintf("event: %08X\n", result);

	outBits = -1;
	result = sceKernelPollEventFlag(evid, 0xFFFFFFFC, PSP_EVENT_WAITOR, &outBits);
	eprintf("event: %08X:%d\n", result, outBits);

	outBits = -1;
	result = sceKernelPollEventFlag(evid + 100, 8 | 2, PSP_EVENT_WAITAND, &outBits);
	eprintf("event: %08X:%d\n", result, outBits);

	sceKernelStartThread(
		sceKernelCreateThread("Test Thread", (void *)&testEvents_thread1, 0x12, 0x10000, 0, NULL),
		0, NULL
	);

	outBits = -1;
	result = sceKernelWaitEventFlagCB(evid, 4, PSP_EVENT_WAITAND, &outBits, NULL);
	eprintf("event: %08X:%d\n", result, outBits);
	
	result = sceKernelClearEventFlag(evid, ~(2 | 8));

	outBits = -1;
	result = sceKernelWaitEventFlagCB(evid, 2 | 8, PSP_EVENT_WAITAND, &outBits, &timeout);
	eprintf("event: %08X:%d\n", result, outBits);

	result = sceKernelDeleteEventFlag(evid);
	eprintf("event: %08X\n", result);
	
	outBits = -1;
	result = sceKernelPollEventFlag(evid, 8 | 2, PSP_EVENT_WAITAND, &outBits);
	eprintf("event: %08X:%d\n", result, outBits);
	
	// Test PSP_EVENT_WAITCLEARALL
	// Test PSP_EVENT_WAITCLEAR
	// Test callback handling
}

/* Exit callback */
int exitCallback(int arg1, int arg2, void *common) {
	sceKernelExitGame();
	return 0;
}

/* Callback thread */
int callbackThread(SceSize args, void *argp) {
	int cbid;

	cbid = sceKernelCreateCallback("Exit Callback", (void*) exitCallback, NULL);
	sceKernelRegisterExitCallback(cbid);
	sceKernelSleepThreadCB();

	return 0;
}

/* Sets up the callback thread and returns its thread id */
int setupCallbacks(void) {
	int thid = 0;

	thid = sceKernelCreateThread("update_thread", callbackThread, 0x11, 0xFA0, 0, 0);
	if (thid >= 0) {
		sceKernelStartThread(thid, 0, 0);
	}
	return thid;
}

int main(int argc, char **argv) {
	pspDebugScreenInit();
	
	setupCallbacks();

	testThreads();
	testEvents();
	
	//{ int wait = 0; while (1) { pspDebugScreenSetXY(10, 0); pspDebugScreenPrintf("Wait...%d\n", wait); wait++; } }
	//sceKernelExitGame();
	
	return 0;
}