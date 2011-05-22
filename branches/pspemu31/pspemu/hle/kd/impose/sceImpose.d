module pspemu.hle.kd.impose.sceImpose;

import pspemu.hle.ModuleNative;
import pspemu.hle.HleEmulatorState;

class sceImpose : ModuleNative {
	void initNids() {
		mixin(registerd!(0x8C943191, sceImposeGetBatteryIconStatus));
	}
	
	uint sceImposeGetBatteryIconStatus(uint* addrCharging, uint* addrIconStatus) {
        float chargedPercentage = 0.5;
        bool  charging = true;
        
        if (addrCharging !is null) {
        	*addrCharging = cast(uint)charging; // 0..1
        }

        if (addrIconStatus !is null) {
        	*addrIconStatus = cast(int)(chargedPercentage * 3); // 0..3
        }

        return 0;
	}
}

static this() {
	mixin(ModuleNative.registerModule("sceImpose"));
}
