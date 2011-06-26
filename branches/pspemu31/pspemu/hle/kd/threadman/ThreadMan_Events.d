module pspemu.hle.kd.threadman.ThreadMan_Events;

import pspemu.utils.sync.WaitEvent;

import pspemu.hle.kd.threadman.Types;

import pspemu.utils.Logger;
import pspemu.utils.String;

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
		this.bits |= bits;
		this.waitEvent.signal();
	}
	
	public bool checkEventFlag(uint bitsToMatch, PspEventFlagWaitTypes wait, ref uint checkedBits) {
		checkedBits = this.bits;
		if (wait & PspEventFlagWaitTypes.PSP_EVENT_WAITOR) {
			return ((checkedBits & bitsToMatch) != 0);
		} else {
			return ((checkedBits & bitsToMatch) == bitsToMatch);
		}
	}
	
	public uint waitEventFlag(uint bitsToMatch, PspEventFlagWaitTypes wait, bool callbacks) {
		uint matchedBits;

		bool matches() {
			//matchedBits = checkEventFlag(bitsToMatch, wait);
			//return (matchedBits != 0);
			uint matchedBits;
			return checkEventFlag(bitsToMatch, wait, matchedBits);
			//return checkEventFlag(bitsToMatch, wait) != 0; 
		}
		
		if (callbacks) {
			Logger.log(Logger.Level.WARNING, "ThreadManForUser", "Not implemented PspWaitEvent.waitEventFlag.callbacks");
		}
		
		//matchedBits = bits;

		while (!matches) {
			waitEvent.wait();
		}

		if (wait & PspEventFlagWaitTypes.PSP_EVENT_WAITCLEARALL) {
			this.bits = 0;
		} else if (wait & PspEventFlagWaitTypes.PSP_EVENT_WAITCLEAR) {
			this.bits &= ~bitsToMatch;
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
	 *
	 * @return < 0 on error. >= 0 event flag id.
	 *
	 * @par Example:
	 * @code
	 * int evid;
	 * evid = sceKernelCreateEventFlag("wait_event", 0, 0, 0);
	 * @endcode
	 */
	SceUID sceKernelCreateEventFlag(string name, PspEventFlagAttributes attr, int bits, SceKernelEventFlagOptParam *opt) {
		PspWaitEvent pspWaitEvent = new PspWaitEvent(name, attr, bits);
		int evid = uniqueIdFactory.add(pspWaitEvent); 
		logInfo("sceKernelCreateEventFlag('%s':%d, %s:%d, %032b, %08X)", name, evid, toSet(attr), attr, bits, cast(uint)opt);
		return evid;
	}

	/** 
	 * Delete an event flag
	 *
	 * @param evid - The event id returned by sceKernelCreateEventFlag.
	 *
	 * @return < 0 On error
	 */
	int sceKernelDeleteEventFlag(int evid) {
		logInfo("sceKernelDeleteEventFlag('%s':%d)", uniqueIdFactory.get!PspWaitEvent(evid).name, evid);
		uniqueIdFactory.remove!PspWaitEvent(evid);
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
		PspWaitEvent pspWaitEvent = uniqueIdFactory.get!PspWaitEvent(evid);
		logInfo("sceKernelClearEventFlag('%s':%d, %032b)", pspWaitEvent.name, evid, bits);
		uint oldBits = pspWaitEvent.bits;
		pspWaitEvent.clearBits(bits);
		logInfo("%032b ---> %032b", oldBits, pspWaitEvent.bits);
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
	 *
	 * @return < 0 On error
	 */
	int _sceKernelWaitEventFlagCB(int evid, u32 bits, PspEventFlagWaitTypes wait, u32 *outBits, SceUInt *timeout, bool callback) {
		try {
			PspWaitEvent pspWaitEvent = uniqueIdFactory.get!PspWaitEvent(evid);
			logInfo("_sceKernelWaitEventFlagCB('%s':%d, %032b, %s, %s, %08X)", pspWaitEvent.name, evid, bits, to!string(wait), to!string(callback), cast(uint)timeout);
			
			currentCpuThread.threadState.waitingBlock("_sceKernelWaitEventFlagCB", {
				uint matchedBits = pspWaitEvent.waitEventFlag(bits, wait, callback);
				if (outBits !is null) *outBits = matchedBits;
			});
			return 0;
		} catch (UniqueIdNotFoundException) {
			logWarning("SceKernelErrors.ERROR_KERNEL_NOT_FOUND_EVENT_FLAG");
			return SceKernelErrors.ERROR_KERNEL_NOT_FOUND_EVENT_FLAG;
		}
	}


	/** 
	 * Wait for an event flag for a given bit pattern.
	 *
	 * @param evid    - The event id returned by sceKernelCreateEventFlag.
	 * @param bits    - The bit pattern to poll for.
	 * @param wait    - Wait type, one or more of ::PspEventFlagWaitTypes or'ed together
	 * @param outBits - The bit pattern that was matched.
	 * @param timeout - Timeout in microseconds
	 *
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
	 *
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
		try {
			PspWaitEvent pspWaitEvent = uniqueIdFactory.get!PspWaitEvent(evid);
			
			logInfo("sceKernelSetEventFlag('%s':%d, %032b)", pspWaitEvent.name, evid, bits);
			uint oldBits = pspWaitEvent.bits;
			pspWaitEvent.setBits(bits);
			logInfo("%032b ---> %032b", oldBits, pspWaitEvent.bits);

			return 0;
		} catch (UniqueIdNotFoundException) {
			logWarning("SceKernelErrors.ERROR_KERNEL_NOT_FOUND_EVENT_FLAG");
			return SceKernelErrors.ERROR_KERNEL_NOT_FOUND_EVENT_FLAG;
		}
	}

	/** 
	  * Poll an event flag for a given bit pattern.
	  *
	  * @param evid    - The event id returned by sceKernelCreateEventFlag.
	  * @param bits    - The bit pattern to poll for.
	  * @param wait    - Wait type, one or more of ::PspEventFlagWaitTypes or'ed together
	  * @param outBits - The bit pattern that was matched.
	  *
	  * @return < 0 On error
	  */
	int sceKernelPollEventFlag(int evid, u32 bits, PspEventFlagWaitTypes wait, u32 *outBits) {
		try {
			PspWaitEvent pspWaitEvent = uniqueIdFactory.get!PspWaitEvent(evid);
			
			if (bits == 0) return SceKernelErrors.ERROR_KERNEL_EVENT_FLAG_ILLEGAL_WAIT_PATTERN;
			
			uint checkedBits;
			bool matched = pspWaitEvent.checkEventFlag(bits, wait, checkedBits);
			
			scope (exit) {
				logInfo(
					"sceKernelPollEventFlag(evid=%d, bits=%032b, wait=%s, outBits=(%08X)%032b:%s)",
					evid, bits, toSet(wait), cast(uint)outBits, checkedBits, matched
				);
			}
	
			if (outBits !is null) *outBits = checkedBits; 

			return (matched) ? 0 : SceKernelErrors.ERROR_KERNEL_EVENT_FLAG_POLL_FAILED; 
		} catch (UniqueIdNotFoundException) {
			logWarning("SceKernelErrors.ERROR_KERNEL_NOT_FOUND_EVENT_FLAG");
			return SceKernelErrors.ERROR_KERNEL_NOT_FOUND_EVENT_FLAG;
		}
	}
	
	void sceKernelReferEventFlagStatus() {
		unimplemented();
	}
}