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
		logWarning("Not Implemented sceKernelPowerLock");
	}

	// @TODO: Unknown.
	void sceKernelPowerUnlock() {
		logWarning("Not Implemented sceKernelPowerUnlock");
	}

	// @TODO: Unknown.
	void sceKernelPowerTick() {
		logWarning("Not Implemented sceKernelPowerTick");
	}
}

static this() {
	mixin(ModuleNative.registerModule("sceSuspendForKernel"));
}
