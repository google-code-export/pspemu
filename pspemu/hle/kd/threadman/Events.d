module pspemu.hle.kd.threadman.Events;

import pspemu.utils.sync.WaitEvent;

import pspemu.hle.kd.threadman.Types;

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
		unimplemented();
		return -1;
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
		unimplemented();
		return -1;
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
	int sceKernelWaitEventFlag(int evid, u32 bits, u32 wait, u32 *outBits, SceUInt *timeout) {
		unimplemented();
		return -1;
	}

	/** 
	 * Wait for an event flag for a given bit pattern with callback.
	 *
	 * @param evid - The event id returned by sceKernelCreateEventFlag.
	 * @param bits - The bit pattern to poll for.
	 * @param wait - Wait type, one or more of ::PspEventFlagWaitTypes or'ed together
	 * @param outBits - The bit pattern that was matched.
	 * @param timeout  - Timeout in microseconds
	 * @return < 0 On error
	 */
	int sceKernelWaitEventFlagCB(int evid, u32 bits, u32 wait, u32 *outBits, SceUInt *timeout) {
		unimplemented();
		return -1;
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
		pspWaitEvent.bits = bits;
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