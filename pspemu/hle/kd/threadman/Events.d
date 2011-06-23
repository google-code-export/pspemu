module pspemu.hle.kd.threadman.Events;

import pspemu.utils.sync.WaitEvent;

import pspemu.hle.kd.threadman.Types;

import pspemu.utils.Logger;

class PspWaitEvent {
	WaitEvent waitEvent;
	string name;
	int attr;
	int bits;
	
	this(string name, int attr, int bits) {
		this.waitEvent = new WaitEvent("PspWaitEvent");
		this.name = cast(string)((cast(char [])name).dup);
		this.attr = attr;
		this.bits = bits;		
	}
	
	public void clearBits(uint bits) {
		this.bits &= bits;
		//this.waitEvent.signal();
	}
	
	public void setBits(uint bits) {
		this.bits = bits;
		this.waitEvent.signal();
	}
	
	public uint waitEventFlag(uint bitsToMatch, PspEventFlagWaitTypes wait, bool callbacks) {
		PspWaitEvent pspWaitEvent;
		bool delegate() matches;
		
		if (wait & PspEventFlagWaitTypes.PSP_EVENT_WAITOR) {
			matches = delegate() { return ((pspWaitEvent.bits & bitsToMatch) != 0); };
		} else {
			matches = delegate() { return ((pspWaitEvent.bits & bitsToMatch) == bitsToMatch); };
		}
		
		if (callbacks) {
			Logger.log(Logger.Level.WARNING, "ThreadManForUser", "Not implemented PspWaitEvent.waitEventFlag.callbacks");
		}

		uint matchedBits = bits;
		
		while (!matches) {
			waitEvent.wait();
		}
		
		if (wait & PspEventFlagWaitTypes.PSP_EVENT_WAITCLEAR) {
			bits = 0;
		}
		return matchedBits;
	}
}

/**
 * Events related stuff.
 */
template ThreadManForUser_Events() {
	void initModule_Events() {
		
	}
	
	void initNids_Events() {
		mixin(registerd!(0x55C20A00, sceKernelCreateEventFlag));
		mixin(registerd!(0xEF9E4C70, sceKernelDeleteEventFlag));
		mixin(registerd!(0x1FB15A32, sceKernelSetEventFlag));
		mixin(registerd!(0x812346E4, sceKernelClearEventFlag));
		mixin(registerd!(0x402FCF22, sceKernelWaitEventFlag));
		mixin(registerd!(0x328C546A, sceKernelWaitEventFlagCB));
		mixin(registerd!(0x30FD48F0, sceKernelPollEventFlag));
		mixin(registerd!(0xA66B0120, sceKernelReferEventFlagStatus));
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
	SceUID sceKernelCreateEventFlag(string name, int attr, int bits, SceKernelEventFlagOptParam *opt) {
		PspWaitEvent pspWaitEvent = new PspWaitEvent(name, attr, bits);
		return hleEmulatorState.uniqueIdFactory.add(pspWaitEvent);
	}

	/** 
	 * Delete an event flag
	 *
	 * @param evid - The event id returned by sceKernelCreateEventFlag.
	 *
	 * @return < 0 On error
	 */
	int sceKernelDeleteEventFlag(int evid) {
		hleEmulatorState.uniqueIdFactory.remove!PspWaitEvent(evid);
		return 0;
	}

	/**
	 * Clear a event flag bit pattern
	 *
	 * @param evid - The event id returned by ::sceKernelCreateEventFlag
	 * @param bits - The bits to clean
	 *
	 * @return < 0 on Error
	 */
	int sceKernelClearEventFlag(SceUID evid, u32 bits) {
		//unimplemented_notice();
		PspWaitEvent pspWaitEvent = hleEmulatorState.uniqueIdFactory.get!PspWaitEvent(evid);
		pspWaitEvent.clearBits(bits);
		return 0;
		//return -1;
	}
	
	/** 
	 * Wait for an event flag for a given bit pattern with callback.
	 *
	 * @param evid    - The event id returned by sceKernelCreateEventFlag.
	 * @param bits    - The bit pattern to poll for.
	 * @param wait    - Wait type, one or more of ::PspEventFlagWaitTypes or'ed together
	 * @param outBits - The bit pattern that was matched.
	 * @param timeout - Timeout in microseconds
	 * @return < 0 On error
	 */
	int _sceKernelWaitEventFlagCB(int evid, u32 bits, PspEventFlagWaitTypes wait, u32 *outBits, SceUInt *timeout, bool callback) {
		PspWaitEvent pspWaitEvent = hleEmulatorState.uniqueIdFactory.get!PspWaitEvent(evid);
		uint matchedBits = pspWaitEvent.waitEventFlag(bits, wait, callback);
		if (outBits !is null) *outBits = matchedBits;
		return 0;
	}


	/** 
	 * Wait for an event flag for a given bit pattern.
	 *
	 * @param evid - The event id returned by sceKernelCreateEventFlag.
	 * @param bits - The bit pattern to poll for.
	 * @param wait - Wait type, one or more of ::PspEventFlagWaitTypes or'ed together
	 * @param outBits - The bit pattern that was matched.
	 * @param timeout  - Timeout in microseconds
	 * @return < 0 On error
	 */
	int sceKernelWaitEventFlag(int evid, u32 bits, PspEventFlagWaitTypes wait, u32 *outBits, SceUInt *timeout) {
		return _sceKernelWaitEventFlagCB(evid, bits, wait, outBits, timeout, false);
	}

	/** 
	 * Wait for an event flag for a given bit pattern with callback.
	 *
	 * @param evid    - The event id returned by sceKernelCreateEventFlag.
	 * @param bits    - The bit pattern to poll for.
	 * @param wait    - Wait type, one or more of ::PspEventFlagWaitTypes or'ed together
	 * @param outBits - The bit pattern that was matched.
	 * @param timeout - Timeout in microseconds
	 * @return < 0 On error
	 */
	int sceKernelWaitEventFlagCB(int evid, u32 bits, PspEventFlagWaitTypes wait, u32 *outBits, SceUInt *timeout) {
		return _sceKernelWaitEventFlagCB(evid, bits, wait, outBits, timeout, true);
	}

	/** 
	  * Set an event flag bit pattern.
	  *
	  * @param evid - The event id returned by sceKernelCreateEventFlag.
	  * @param bits - The bit pattern to set.
	  *
	  * @return < 0 On error
	  */
	int sceKernelSetEventFlag(SceUID evid, u32 bits) {
		PspWaitEvent pspWaitEvent = hleEmulatorState.uniqueIdFactory.get!PspWaitEvent(evid);
		pspWaitEvent.setBits(bits);
		return 0;
	}

	/** 
	  * Poll an event flag for a given bit pattern.
	  *
	  * @param evid - The event id returned by sceKernelCreateEventFlag.
	  * @param bits - The bit pattern to poll for.
	  * @param wait - Wait type, one or more of ::PspEventFlagWaitTypes or'ed together
	  * @param outBits - The bit pattern that was matched.
	  * @return < 0 On error
	  */
	int sceKernelPollEventFlag(int evid, u32 bits, u32 wait, u32 *outBits) {
		unimplemented();
		return -1;
	}
	
	void sceKernelReferEventFlagStatus() {
		unimplemented();
	}
}