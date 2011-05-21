module pspemu.hle.kd.lowio.sceSysreg_driver;

import pspemu.hle.ModuleNative;

class sceSysreg_driver : ModuleNative {
	void initNids() {
		mixin(registerd!(0xDE59DACB, sceSysregMeResetEnable));
		mixin(registerd!(0x44F6CDA7, sceSysregMeBusClockEnable));
		mixin(registerd!(0x2DB0EB28, sceSysregMeResetDisable));
		mixin(registerd!(0x7558064A, sceSysregVmeResetDisable));
	}
	
	/**
	  * Enable the ME reset.
	  *
	  * @return < 0 on error.
	  */
	int sceSysregMeResetEnable() {
		return 0;
	}
	
	/**
	  * Disable the ME reset.
	  *
	  * @return < 0 on error.
	  */
	int sceSysregMeResetDisable() {
		return 0;
	}
	
	/**
	  * Enable the VME reset.
	  *
	  * @return < 0 on error.
	  */
	int sceSysregVmeResetEnable() {
		return 0;
	}
	
	/**
	  * Disable the VME reset.
	  *
	  * @return < 0 on error.
	  */
	int sceSysregVmeResetDisable() {
		return 0;
	}
	
	/**
	  * Enable the ME bus clock.
	  *
	  * @return < 0 on error.
	  */
	int sceSysregMeBusClockEnable() {
		return 0;
	}
	
	/**
	  * Disable the ME bus clock.
	  *
	  * @return < 0 on error.
	  */
	int sceSysregMeBusClockDisable() {
		return 0;
	}
}

static this() {
	mixin(ModuleNative.registerModule("sceSysreg_driver"));
}
