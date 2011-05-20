module pspemu.hle.kd.sysmem.sceSuspendForKernel; // kd/sysmem.prx (sceSystemMemoryManager)

import pspemu.hle.ModuleNative;

class sceSuspendForKernel : ModuleNative {
	void initNids() {
		mixin(registerd!(0xEADB1BD7, sceKernelPowerLock));
		mixin(registerd!(0x3AEE7261, sceKernelPowerUnlock));
		mixin(registerd!(0x090CCB3F, sceKernelPowerTick));
	}

	// @TODO: Unknown.
	void sceKernelPowerLock() {
		unimplemented();
	}

	// @TODO: Unknown.
	void sceKernelPowerUnlock() {
		unimplemented();
	}

	// @TODO: Unknown.
	void sceKernelPowerTick() {
		unimplemented();
	}
}

static this() {
	mixin(ModuleNative.registerModule("sceSuspendForKernel"));
}
