module pspemu.hle.kd.threadman.Semaphores;

//import pspemu.hle.kd.threadman_common;

import std.math;

import pspemu.utils.MathUtils;

import pspemu.hle.kd.Types;
import pspemu.hle.kd.threadman.Types;

import core.sync.condition;
import core.sync.mutex;

import std.c.windows.windows;

class PspSemaphore {
	string name;
	SceKernelSemaInfo info;
	Condition updatedCountCondition;
	
	this() {
		updatedCountCondition = new Condition(new Mutex());
	}

	public void incrementCount(int count) {
		info.currentCount = min(info.maxCount, info.currentCount + count);
		updatedCountCondition.notify();
	}
	
	public void waitSignal(int expectedValueAtLeast, uint timeout) {
		// @TODO: ignored timeout
		info.numWaitThreads++;
		{
			while (info.currentCount < expectedValueAtLeast) {
				updatedCountCondition.wait();
			}
			info.currentCount -= expectedValueAtLeast;
		}
		info.numWaitThreads--;
	}
}

template ThreadManForUser_Semaphores() {
	//PspSemaphoreManager semaphoreManager;

	void initModule_Semaphores() {
		//threadManager = new PspThreadManager(this);
		//semaphoreManager = new PspSemaphoreManager(this);
	}

	void initNids_Semaphores() {
		mixin(registerd!(0xD6DA4BA1, sceKernelCreateSema));
		mixin(registerd!(0x3F53E640, sceKernelSignalSema));
		mixin(registerd!(0x28B6489C, sceKernelDeleteSema));
		mixin(registerd!(0x4E3A1105, sceKernelWaitSema));
		/*
		mixin(registerd!(0x6D212BAC, sceKernelWaitSemaCB));
		mixin(registerd!(0x58B1F937, sceKernelPollSema));
		*/
	}
	
	/**
	 * Creates a new semaphore
	 *
	 * @par Example:
	 * @code
	 * int semaid;
	 * semaid = sceKernelCreateSema("MyMutex", 0, 1, 1, 0);
	 * @endcode
	 *
	 * @param name      - Specifies the name of the sema
	 * @param attr      - Sema attribute flags (normally set to 0)
	 * @param initCount - Sema initial value 
	 * @param maxCount  - Sema maximum value
	 * @param option    - Sema options (normally set to 0)
	 *
	 * @return A semaphore id
	 */
	SceUID sceKernelCreateSema(string name, SceUInt attr, int initCount, int maxCount, SceKernelSemaOptParam* option) {
		writefln("sceKernelCreateSema('%s')", name);
		auto semaphore = new PspSemaphore();
		semaphore.name = name;
		{
			semaphore.info.name[0..semaphore.name.length] = semaphore.name[0..$];
			semaphore.info.attr           = attr;
			semaphore.info.initCount      = initCount;
			semaphore.info.currentCount   = initCount; // Actual value
			semaphore.info.maxCount       = maxCount;
			semaphore.info.numWaitThreads = 0;
		}
		return hleEmulatorState.uniqueIdFactory.add(semaphore);
	}
	
	/**
	 * Send a signal to a semaphore
	 *
	 * @par Example:
	 * @code
	 * // Signal the sema
	 * sceKernelSignalSema(semaid, 1);
	 * @endcode
	 *
	 * @param semaid - The sema id returned from sceKernelCreateSema
	 * @param signal - The amount to signal the sema (i.e. if 2 then increment the sema by 2)
	 *
	 * @return < 0 On error.
	 */
	int sceKernelSignalSema(SceUID semaid, int signal) {
		auto semaphore = hleEmulatorState.uniqueIdFactory.get!PspSemaphore(semaid); 
		writefln("sceKernelSignalSema(%d:'%s', %d)", semaid, semaphore.name, signal);
		semaphore.incrementCount(signal);
		return 0;
	}
	
	/**
	 * Destroy a semaphore
	 *
	 * @param semaid - The semaid returned from a previous create call.
	 * @return Returns the value 0 if its succesful otherwise -1
	 */
	int sceKernelDeleteSema(SceUID semaid) {
		auto semaphore = hleEmulatorState.uniqueIdFactory.get!PspSemaphore(semaid);
		writefln("sceKernelDeleteSema(%d:'%s')", semaid, semaphore.name);
		hleEmulatorState.uniqueIdFactory.remove!PspSemaphore(semaid);
		return 0;
	}
	
	/**
	 * Lock a semaphore
	 *
	 * @par Example:
	 * @code
	 * sceKernelWaitSema(semaid, 1, 0);
	 * @endcode
	 *
	 * @param semaid  - The sema id returned from sceKernelCreateSema
	 * @param signal  - The value to wait for (i.e. if 1 then wait till reaches a signal state of 1 or greater)
	 * @param timeout - Timeout in microseconds (assumed).
	 *
	 * @return < 0 on error.
	 */
	int sceKernelWaitSema(SceUID semaid, int signal, SceUInt* timeout) {
		auto semaphore = hleEmulatorState.uniqueIdFactory.get!PspSemaphore(semaid);
		currentCpuThread.threadState.waitingBlock({
			semaphore.waitSignal(signal, (timeout !is null) ? *timeout : 0);
		});
		return 0;
	}

	/+
	/**
	 * Poll a sempahore.
	 *
	 * @param semaid - UID of the semaphore to poll.
	 * @param signal - The value to test for.
	 *
	 * @return < 0 on error.
	 */
	int sceKernelPollSema(SceUID semaid, int signal) {
		unimplemented();
		return -1;
	}

	/**
	 * Retrieve information about a semaphore.
	 *
	 * @param semaid - UID of the semaphore to retrieve info for.
	 * @param info - Pointer to a ::SceKernelSemaInfo struct to receive the info.
	 *
	 * @return < 0 on error.
	 */
	int sceKernelReferSemaStatus(SceUID semaid, SceKernelSemaInfo* info) {
		unimplemented();
		return -1;
	}

	/**
	 * Lock a semaphore a handle callbacks if necessary.
	 *
	 * @par Example:
	 * @code
	 * sceKernelWaitSemaCB(semaid, 1, 0);
	 * @endcode
	 *
	 * @param semaid - The sema id returned from sceKernelCreateSema
	 * @param signal - The value to wait for (i.e. if 1 then wait till reaches a signal state of 1)
	 * @param timeout - Timeout in microseconds (assumed).
	 *
	 * @return < 0 on error.
	 */
	int sceKernelWaitSemaCB(SceUID semaid, int signal, SceUInt *timeout) {
		unimplemented();
		return -1;
	}
	+/
}
