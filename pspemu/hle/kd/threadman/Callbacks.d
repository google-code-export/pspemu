module pspemu.hle.kd.threadman.Callbacks;

import pspemu.hle.kd.threadman.Types;

/**
 * Callbacks related stuff.
 */
template ThreadManForUser_Callbacks() {
	void initModule_Callbacks() {
		
	}
	
	void initNids_Callbacks() {
		mixin(registerd!(0xE81CAF8F, sceKernelCreateCallback));
		mixin(registerd!(0xEDBA5844, sceKernelDeleteCallback));
		mixin(registerd!(0x349D6D6C, sceKernelCheckCallback));
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
	int sceKernelCreateCallback(string name, SceKernelCallbackFunction func, void* arg) {
		PspCallback pspCallback = new PspCallback(name, func, arg);
		int uid = hleEmulatorState.uniqueIdFactory.add(pspCallback);
		logInfo("sceKernelCreateCallback('%s':%d, %08X, %08X)", name, uid, cast(uint)func, cast(uint)arg);
		return uid;
	}
	
	/**
	 * Delete a callback
	 *
	 * @param cb - The UID of the specified callback
	 *
	 * @return 0 on success, < 0 on error
	 */
	int sceKernelDeleteCallback(SceUID cb) {
		unimplemented();
		return -1;
	}

	/**
	 * Check callback ?
	 *
	 * @return Something or another
	 */
	int sceKernelCheckCallback() {
		unimplemented();
		return -1;
	}
}