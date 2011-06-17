module pspemu.hle.kd.loadexec.LoadExecForUser; // kd/loadexec.prx (sceLoadExec)

//debug = DEBUG_SYSCALL;

import pspemu.hle.ModuleNative;

import pspemu.hle.kd.loadexec.Types;

class LoadExecForUser : ModuleNative {
	void initNids() {
		mixin(registerd!(0xBD2F1094, sceKernelLoadExec));
		mixin(registerd!(0x2AC9954B, sceKernelExitGameWithStatus));
		mixin(registerd!(0x05572A5F, sceKernelExitGame));
		mixin(registerd!(0x4AC57943, sceKernelRegisterExitCallback));
	}

	void sceKernelExitGameWithStatus(int status) {
		throw(new HaltException("sceKernelExitGameWithStatus"));
	}

	/** 
	  * Execute a new game executable, limited when not running in kernel mode.
	  * 
	  * @param file - The file to execute.
	  * @param param - Pointer to a ::SceKernelLoadExecParam structure, or NULL.
	  *
	  * @return < 0 on error, probably.
	  *
	  */
	int sceKernelLoadExec(string file, SceKernelLoadExecParam *param) {
		unimplemented();
		return -1;
	}

	/**
	 * Exit game and go back to the PSP browser.
	 *
	 * @note You need to be in a thread in order for this function to work
	 *
	 */
	void sceKernelExitGame() {
		throw(new HaltException("sceKernelExitGame"));
	}

	/**
	 * Register callback
	 *
	 * @note By installing the exit callback the home button becomes active. However if sceKernelExitGame
	 * is not called in the callback it is likely that the psp will just crash.
	 *
	 * @par Example:
	 * @code
	 * int exit_callback(void) { sceKernelExitGame(); }
	 *
	 * cbid = sceKernelCreateCallback("ExitCallback", exit_callback, NULL);
	 * sceKernelRegisterExitCallback(cbid);
	 * @endcode
	 *
	 * @param cbid Callback id
	 * @return < 0 on error
	 */
	int sceKernelRegisterExitCallback(int cbid) {
		//unimplemented();
		return 0;
	}
}

static this() {
	mixin(ModuleNative.registerModule("LoadExecForUser"));
}