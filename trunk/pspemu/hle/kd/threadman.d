module pspemu.hle.kd.threadman; // kd/threadman.prx (sceThreadManager)

//debug = DEBUG_SYSCALL;

import pspemu.hle.Module;

class ThreadManForUser : Module {
	this() {
		mixin(registerd!(0xE81CAF8F, sceKernelCreateCallback));
		mixin(registerd!(0x82826F70, sceKernelSleepThreadCB));
		mixin(registerd!(0x446D8DE6, sceKernelCreateThread));
		mixin(registerd!(0xF475845D, sceKernelStartThread));
		mixin(registerd!(0xAA73C935, sceKernelExitThread));
		mixin(registerd!(0x55C20A00, sceKernelCreateEventFlag));
		mixin(register(0x1FB15A32, "sceKernelSetEventFlag"));
	}

	/** 
	  * Create an event flag.
	  *
	  * @param name - The name of the event flag.
	  * @param attr - Attributes from ::PspEventFlagAttributes
	  * @param bits - Initial bit pattern.
	  * @param opt  - Options, set to NULL
	  * @return < 0 on error. >= 0 event flag id.
	  *
	  * @par Example:
	  * @code
	  * int evid;
	  * evid = sceKernelCreateEventFlag("wait_event", 0, 0, 0);
	  * @endcode
	  */
	SceUID sceKernelCreateEventFlag(/*const*/ char *name, int attr, int bits, SceKernelEventFlagOptParam *opt) {
		return 0;
	}

	/**
	 * Sleep thread but service any callbacks as necessary
	 *
	 * @par Example:
	 * @code
	 * // Once all callbacks have been setup call this function
	 * sceKernelSleepThreadCB();
	 * @endcode
	 */
	int sceKernelSleepThreadCB() {
		return 0;
	}
	
	/**
	 * Exit a thread
	 *
	 * @param status - Exit status.
	 */
	int sceKernelExitThread(int status) {
		return 0;
	}

	/**
	 * Create a thread
	 *
	 * @par Example:
	 * @code
	 * SceUID thid;
	 * thid = sceKernelCreateThread("my_thread", threadFunc, 0x18, 0x10000, 0, NULL);
	 * @endcode
	 *
	 * @param name - An arbitrary thread name.
	 * @param entry - The thread function to run when started.
	 * @param initPriority - The initial priority of the thread. Less if higher priority.
	 * @param stackSize - The size of the initial stack.
	 * @param attr - The thread attributes, zero or more of ::PspThreadAttributes.
	 * @param option - Additional options specified by ::SceKernelThreadOptParam.

	 * @return UID of the created thread, or an error code.
	 */
	SceUID sceKernelCreateThread(/*const*/ char *name, SceKernelThreadEntry entry, int initPriority, int stackSize, SceUInt attr, SceKernelThreadOptParam *option) {
		return param(1);
	}

	/**
	 * Start a created thread
	 *
	 * @param thid - Thread id from sceKernelCreateThread
	 * @param arglen - Length of the data pointed to by argp, in bytes
	 * @param argp - Pointer to the arguments.
	 */
	//int sceKernelStartThread(SceUID thid, SceSize arglen, void *argp) {
	void sceKernelStartThread(SceUID thid, SceSize arglen, void *argp) {
		cpu.registers.A0 = 0;
		cpu.registers.A1 = 0;
		cpu.registers.pcSet(thid);
	}

	/**
	 * Create callback
	 *
	 * @par Example:
	 * @code
	 * int cbid;
	 * cbid = sceKernelCreateCallback("Exit Callback", exit_cb, NULL);
	 * @endcode
	 *
	 * @param name - A textual name for the callback
	 * @param func - A pointer to a function that will be called as the callback
	 * @param arg  - Argument for the callback ?
	 *
	 * @return >= 0 A callback id which can be used in subsequent functions, < 0 an error.
	 */
	int sceKernelCreateCallback(const char *name, SceKernelCallbackFunction func, void *arg) {
		return 0;
	}
}

class ThreadManForKernel : ThreadManForUser {
}

alias uint SceKernelThreadEntry;
alias uint SceKernelCallbackFunction;

//alias int function(SceSize args, void *argp) SceKernelThreadEntry;
//alias int function(int arg1, int arg2, void *arg) SceKernelCallbackFunction;

/** Structure to hold the event flag information */
struct SceKernelEventFlagInfo {
	SceSize 	size;
	char 		name[32];
	SceUInt 	attr;
	SceUInt 	initPattern;
	SceUInt 	currentPattern;
	int 		numWaitThreads;
}

struct SceKernelEventFlagOptParam {
	SceSize 	size;
}

/** Additional options used when creating threads. */
struct SceKernelThreadOptParam {
	/** Size of the ::SceKernelThreadOptParam structure. */
	SceSize 	size;
	/** UID of the memory block (?) allocated for the thread's stack. */
	SceUID 		stackMpid;
}

static this() {
	mixin(Module.registerModule("ThreadManForUser"));
	mixin(Module.registerModule("ThreadManForKernel"));
}