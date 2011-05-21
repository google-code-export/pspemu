module pspemu.hle.kd.sysmem.sceSysEventForKernel; // kd/sysmem.prx (sceSystemMemoryManager)

import pspemu.hle.ModuleNative;
import pspemu.core.exceptions.NotImplementedException;

//typedef int(* 	PspSysEventHandlerFunc )(int ev_id, char *ev_name, void *param, int *result)
alias uint PspSysEventHandler;

class sceSysEventForKernel : ModuleNative {
	void initNids() {
		mixin(registerd!(0xCD9E4BB5, sceKernelRegisterSysEventHandler));
	}
	
	int sceKernelRegisterSysEventHandler(PspSysEventHandler *handler) {
		throw(new NotImplementedException("Not implemented"));
	}
}

static this() {
	mixin(ModuleNative.registerModule("sceSysEventForKernel"));
}
