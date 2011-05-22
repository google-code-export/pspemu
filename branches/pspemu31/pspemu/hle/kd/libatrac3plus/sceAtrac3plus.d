module pspemu.hle.kd.libatrac3plus.sceAtrac3plus;

import pspemu.hle.ModuleNative;
import pspemu.hle.HleEmulatorState;

class Atrac3Object {
	void *buf;
	SceSize bufsize;
	int nloops;
}

class sceAtrac3plus : ModuleNative {
	void initNids() {
		mixin(registerd!(0x7A20E7AF, sceAtracSetDataAndGetID));
		mixin(registerd!(0x868120B5, sceAtracSetLoopNum));
	}
	
	/**
	 * Creates a new Atrac ID from the specified data
	 *
	 * @param buf - the buffer holding the atrac3 data, including the RIFF/WAVE header.
	 * @param bufsize - the size of the buffer pointed by buf
	 *
	 * @return the new atrac ID, or < 0 on error 
	*/
	int sceAtracSetDataAndGetID(void *buf, SceSize bufsize) {
		Atrac3Object atrac3Object = new Atrac3Object();
		atrac3Object.buf = buf;
		atrac3Object.bufsize = bufsize;
		return cast(int)hleEmulatorState.uniqueIdFactory.add(atrac3Object);
	}
	
	/**
	 * Sets the number of loops for this atrac ID
	 *
	 * @param atracID - the atracID
	 * @param nloops - the number of loops to set
	 *
	 * @return < 0 on error, otherwise 0
	 *
	*/
	int sceAtracSetLoopNum(int atracID, int nloops) {
		Atrac3Object atrac3Object = hleEmulatorState.uniqueIdFactory.get!Atrac3Object(atracID);
		atrac3Object.nloops = nloops;
		return 0;
	}
}

static this() {
	mixin(ModuleNative.registerModule("sceAtrac3plus"));
}
