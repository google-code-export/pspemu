module pspemu.hle.kd.iofilemgr.IoFileMgrForUser; // kd/iofilemgr.prx (sceIOFileManager)

import pspemu.hle.kd.iofilemgr.IoFileMgrForKernel;

import pspemu.hle.ModuleNative;

class IoFileMgrForUser : IoFileMgrForKernel {
}

static this() {
	mixin(ModuleNative.registerModule("IoFileMgrForUser"));
}
