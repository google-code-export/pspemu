module pspemu.hle.kd.threadman.Threads;

import pspemu.hle.kd.threadman.Types;
import pspemu.core.ThreadState;
import pspemu.hle.ModuleNative;

import pspemu.utils.Logger;

template ThreadManForUser_Threads() {
	/**
	 * Thread Manager
	 */
	//PspThreadManager threadManager;

	void initModule_Threads() {
		//threadManager = new PspThreadManager(this);
	}

	void initNids_Threads() {
		mixin(registerd!(0x446D8DE6, sceKernelCreateThread));
		mixin(registerd!(0xF475845D, sceKernelStartThread));
		mixin(registerd!(0xAA73C935, sceKernelExitThread));
		mixin(registerd!(0x9ACE131E, sceKernelSleepThread));
		mixin(registerd!(0x82826F70, sceKernelSleepThreadCB));
		mixin(registerd!(0xEA748E31, sceKernelChangeCurrentThreadAttr));
		mixin(registerd!(0xCEADEB47, sceKernelDelayThread));
		mixin(registerd!(0x68DA9E36, sceKernelDelayThreadCB));
		mixin(registerd!(0x293B45B8, sceKernelGetThreadId));
		mixin(registerd!(0x17C1684E, sceKernelReferThreadStatus));
		mixin(registerd!(0x71BC9871, sceKernelChangeThreadPriority));
		mixin(registerd!(0x809CE29B, sceKernelExitDeleteThread));
		mixin(registerd!(0x278C0DF5, sceKernelWaitThreadEnd));
		mixin(registerd!(0x9FA03CD3, sceKernelDeleteThread));
		/+
		mixin(registerd!(0x383F7BCC, sceKernelTerminateDeleteThread));
		mixin(registerd!(0xD59EAD2F, sceKernelWakeupThread));
		mixin(registerd!(0x9944F31F, sceKernelSuspendThread));
		mixin(registerd!(0x840E8133, sceKernelWaitThreadEndCB));
		mixin(registerd!(0x94AA61EE, sceKernelGetThreadCurrentPriority));
		mixin(registerd!(0x75156E8F, sceKernelResumeThread));
		mixin(registerd!(0x616403BA, sceKernelTerminateThread));
		mixin(registerd!(0x3B183E26, sceKernelGetThreadExitStatus));
		+/
	}
	
	/**
	 * Create a thread
	 *
	 * @par Example:
	 * @code
	 * SceUID thid;
	 * thid = sceKernelCreateThread("my_thread", threadFunc, 0x18, 0x10000, 0, NULL);
	 * @endcode
	 *
	 * @param name         - An arbitrary thread name.
	 * @param entry        - The thread function to run when started.
	 * @param initPriority - The initial priority of the thread. Less if higher priority.
	 * @param stackSize    - The size of the initial stack.
	 * @param attr         - The thread attributes, zero or more of ::PspThreadAttributes.
	 * @param option       - Additional options specified by ::SceKernelThreadOptParam.

	 * @return UID of the created thread, or an error code.
	 */
	SceUID sceKernelCreateThread(string name, SceKernelThreadEntry entry, int initPriority, int stackSize, SceUInt attr, SceKernelThreadOptParam *option) {
		/*
		string name         = get_argument_str(0);
		//void*  entry        = get_argument_ptr!void(1);
		uint   entry        = get_argument_int(1);
		int    initPriority = get_argument_int(2);
		int    stackSize    = get_argument_int(3);
		int    attr         = get_argument_int(4);
		void*  option       = get_argument_ptr!void(5);
		*/

		ThreadState newThreadState = new ThreadState(currentEmulatorState, new Registers());
		
		newThreadState.threadModule = currentThreadState.threadModule;
		
		newThreadState.registers.copyFrom(currentRegisters);
		newThreadState.registers.pcSet = entry;
		
		newThreadState.registers.SP = hleEmulatorState.memoryManager.allocStack(PspPartition.User, std.string.format("stack for thread '%s'", name), stackSize);
		
		newThreadState.registers.RA = 0x08000000;
		newThreadState.thid = hleEmulatorState.uniqueIdFactory.add(newThreadState);
		
		logInfo("sceKernelCreateThread(thid:'%d', name:'%s', SP:0x%08X)", newThreadState.thid, name, newThreadState.registers.SP);
		
		newThreadState.sceKernelThreadInfo.attr = attr;
		newThreadState.sceKernelThreadInfo.name[0..name.length] = name;
		newThreadState.sceKernelThreadInfo.initPriority = initPriority;
		newThreadState.sceKernelThreadInfo.currentPriority = initPriority;
		newThreadState.sceKernelThreadInfo.gpReg = cast(void *)currentRegisters().GP;
		newThreadState.sceKernelThreadInfo.stackSize = stackSize;
		newThreadState.sceKernelThreadInfo.stack = cast(void *)(newThreadState.registers.SP - stackSize);
		newThreadState.sceKernelThreadInfo.entry = entry;
		newThreadState.sceKernelThreadInfo.size = SceKernelThreadInfo.sizeof;
		newThreadState.sceKernelThreadInfo.status = PspThreadStatus.PSP_THREAD_STOPPED;

		newThreadState.name = cast(string)newThreadState.sceKernelThreadInfo.name[0..name.length];
		
		return newThreadState.thid;
		
		/*
		auto pspThread = new PspThread(threadManager);

		SceUID thid = 0; foreach (thid_cur; threadManager.createdThreads.keys) if (thid < thid_cur) thid = thid_cur; thid++;

		threadManager.createdThreads[thid] = pspThread;
		
		pspThread.thid = thid;

		pspThread.name = cast(string)pspThread.info.name[0..name.length];

		pspThread.info.name[0..name.length] = name[0..name.length];
		pspThread.info.currentPriority = pspThread.info.initPriority = initPriority;
		pspThread.info.size      = pspThread.info.sizeof;
		pspThread.info.stackSize = stackSize;
		pspThread.info.entry     = entry;
		pspThread.info.attr      = attr;
		pspThread.info.status    = PspThreadStatus.PSP_THREAD_STOPPED;

		// Set stack.
		pspThread.createStack(moduleManager.get!(SysMemUserForUser));
		
		// Set extra info.
		pspThread.info.gpReg = cast(void *)cpu.registers.GP;

		// Set thread registers.
		with (pspThread.registers) {
			pspThread.registers.R[] = 0; // Clears all the registers (though it's not necessary).
			pcSet(entry);
			GP = cpu.registers.GP;
			SP = pspThread.stack.block.high - 0x600;
			//K0 = pspThread.stack.block.high - 0x600; //?
			RA = 0x08000200; // sceKernelExitDeleteThread
		}

		return thid;
		*/
	}
	
	/**
	 * Start a created thread
	 *
	 * @param thid   - Thread id from sceKernelCreateThread
	 * @param arglen - Length of the data pointed to by argp, in bytes
	 * @param argp   - Pointer to the arguments.
	 */
	int sceKernelStartThread(SceUID thid, SceSize arglen, /*void**/ uint argp) {
		logInfo("sceKernelStartThread(%d, %d, %08X)", thid, arglen, argp);
		
		ThreadState newThreadState = hleEmulatorState.uniqueIdFactory.get!(ThreadState)(thid);
		
		newThreadState.registers.A0 = arglen;
		newThreadState.registers.A1 = argp;
		
		CpuThreadBase newCpuThread = currentCpuThread().createCpuThread(newThreadState);
		
		//writefln("sceKernelStartThread(%d, %d, %08X)", thid, arglen, argp);

		/*
		newCpuThread.executeBefore = delegate() {
			writefln("started new thread");
		};
		*/
		
		newCpuThread.start();

		newThreadState.sceKernelThreadInfo.status = PspThreadStatus.PSP_THREAD_RUNNING;

		// newCpuThread could access parent's stack because it has some cycles at the start.
		newCpuThread.thisThreadWaitCyclesAtLeast(1_000_000);
		
		
		// @TODO
		
		return 0;
		
		//callLibrary("ThreadManForUser", "sceKernelStartThread");
		//throw(new Exception("sceKernelStartThread"));

		/*
		if (thid < 0) return -1;
		auto pspThread = getThreadFromId(thid);
		if (pspThread is null) {
			writefln("sceKernelStartThread: Null");
			return -1;
		}
		//writefln("sceKernelStartThread:%d,%d,%d", thid, arglen, cpu.memory.getPointerReverseOrNull(argp));
		pspThread.info.status  = PspThreadStatus.PSP_THREAD_RUNNING;
		threadManager.addToRunningList(pspThread);

		// NOTE: It's mandatory to switch immediately to this thread, because the new thread
		// may use volatile data (por example a value that will be change in the parent thread)
		// in a few instructions.
		// Set the value to the current thread.
		returnValue = 0;
		avoidAutosetReturnValue();

		// Then change to the next thread and avoid writting the return value to that thread.
		pspThread.switchToThisThread();

		return 0;
		*/
	}

	/**
	 * Exit a thread
	 *
	 * @param status - Exit status.
	 */
	void sceKernelExitThread(int status) {
		logInfo("sceKernelExitThread(%d)", status);
		//writefln("sceKernelExitThread(%d)", status);
		throw(new HaltException(std.string.format("sceKernelExitThread(%d)", status)));
	}
	
	/** 
	  * Exit a thread and delete itself.
	  *
	  * @param status - Exit status
	  */
	int sceKernelExitDeleteThread(int status) {
		logInfo("sceKernelExitDeleteThread(%d)", status);
		throw(new HaltException(std.string.format("sceKernelExitDeleteThread(%d)", status)));
		return 0;
	}

	int _sceKernelSleepThreadCB(bool CallBack) {
		currentCpuThread.threadState.waitingBlock({
			//.writefln("sceKernelSleepThreadCB()");
			while (currentEmulatorState().runningState.running) {
				Thread.sleep(dur!("msecs")(1));
			}
			throw(new HaltException("Halt"));
		});
		return 0;
	}
	
	/**
	 * Sleep thread
	 *
	 * @return < 0 on error.
	 */
	int sceKernelSleepThread() {
		logInfo("sceKernelSleepThread()");
		return _sceKernelSleepThreadCB(false);
	}
	
	/**
	 * Sleep thread but service any callbacks as necessary
	 *
	 * @par Example:
	 * <code>
	 *     // Once all callbacks have been setup call this function
	 *     sceKernelSleepThreadCB();
	 * </code>
	 */
	int sceKernelSleepThreadCB() {
		logInfo("sceKernelSleepThreadCB()");
		return _sceKernelSleepThreadCB(true);
	}
	
	/**
	 * Modify the attributes of the current thread.
	 *
	 * @param unknown - Set to 0.
	 * @param attr    - The thread attributes to modify.  One of ::PspThreadAttributes.
	 *
	 * @return < 0 on error.
	 */
	int sceKernelChangeCurrentThreadAttr(int unknown, SceUInt attr) {
		writefln("UNIMPLEMENTED: sceKernelChangeCurrentThreadAttr(%d, %d)", unknown, attr);
		//threadManager.currentThread.info.attr = attr;
		return 0;
	}

	int _sceKernelDelayThread(SceUInt delay, bool callbacks) {
		currentCpuThread.threadState.waitingBlock({
			//writefln("sceKernelDelayThread(%d)", delay);
			
			while (delay > 0) {
				// @TODO This should be done with a set of mutexs, and a wait for any.
				if (!currentEmulatorState.runningState.running) throw(new HaltException("Halt"));
				Thread.sleep(dur!("usecs")(1000));
				delay -= 1000;
			}
		});
		return 0;
	}

	/**
	 * Delay the current thread by a specified number of microseconds
	 *
	 * @param delay - Delay in microseconds.
	 *
	 * @par Example:
	 * <code>
	 *     sceKernelDelayThread(1000000); // Delay for a second
	 * </code>
	 */
	int sceKernelDelayThread(SceUInt delay) {
		logInfo("sceKernelDelayThread(%d)", delay);
		return _sceKernelDelayThread(delay, /*callbacks = */false);
	}
	
	/**
	 * Delay the current thread by a specified number of microseconds and handle any callbacks.
	 *
	 * @param delay - Delay in microseconds.
	 *
	 * @par Example:
	 * <code>
	 *     sceKernelDelayThread(1000000); // Delay for a second
	 * </code>
	 */
	int sceKernelDelayThreadCB(SceUInt delay) {
		logInfo("sceKernelDelayThreadCB(%d)", delay);
		return _sceKernelDelayThread(delay, /*callbacks = */true);
	}

	/** 
	 * Get the current thread Id
	 *
	 * @return The thread id of the calling thread.
	 */
	SceUID sceKernelGetThreadId() {
		logInfo("sceKernelGetThreadId()");
		return currentThreadState().thid;
	}
	
	/** 
	 * Get the status information for the specified thread.
	 * 
	 * @param thid - Id of the thread to get status
	 * @param info - Pointer to the info structure to receive the data.
	 * Note: The structures size field should be set to
	 * sizeof(SceKernelThreadInfo) before calling this function.
	 *
	 * @par Example:
	 * <code>
	 *     SceKernelThreadInfo status;
	 *     status.size = sizeof(SceKernelThreadInfo);
	 *     if (sceKernelReferThreadStatus(thid, &status) == 0) { Do something... }
	 * </code>
	 *
	 * @return 0 if successful, otherwise the error code.
	 */
	int sceKernelReferThreadStatus(SceUID thid, SceKernelThreadInfo* info) {
		logInfo("sceKernelReferThreadStatus(%d)", thid);
		if (thid < 0) return -1;
		ThreadState threadState = hleEmulatorState.uniqueIdFactory.get!(ThreadState)(thid);
		if (threadState is null) return -1;
		if (info        is null) return -2;

		*info = threadState.sceKernelThreadInfo;
		
		return 0;
	}
	
	/**
	  * Change the threads current priority.
	  * 
	  * @param thid     - The ID of the thread (from sceKernelCreateThread or sceKernelGetThreadId)
	  * @param priority - The new priority (the lower the number the higher the priority)
	  *
	  * @par Example:
	  * @code
	  * int thid = sceKernelGetThreadId();
	  * // Change priority of current thread to 16
	  * sceKernelChangeThreadPriority(thid, 16);
	  * @endcode
	  *
	  * @return 0 if successful, otherwise the error code.
	  */
	int sceKernelChangeThreadPriority(SceUID thid, int priority) {
		logInfo("sceKernelChangeThreadPriority(%d, %d)", thid, priority);
		if (thid < 0) return -1;
		ThreadState threadState = hleEmulatorState.uniqueIdFactory.get!(ThreadState)(thid);
		threadState.sceKernelThreadInfo.currentPriority = priority; 
		return 0;
	}
	
	/** 
	 * Wait until a thread has ended.
	 *
	 * @param thid    - Id of the thread to wait for.
	 * @param timeout - Timeout in microseconds (assumed).
	 *
	 * @return < 0 on error.
	 */
	int sceKernelWaitThreadEnd(SceUID thid, SceUInt* timeout) {
		if (thid < 0) return -1;
		ThreadState threadState = hleEmulatorState.uniqueIdFactory.get!(ThreadState)(thid);
		
		while (!(threadState.sceKernelThreadInfo.status & PspThreadStatus.PSP_THREAD_STOPPED | PspThreadStatus.PSP_THREAD_KILLED)) {
			currentEmulatorState.threadEndedCondition.wait();
		}
		
		return 0;
	}
	
	/**
	 * Delete a thread
	 *
	 * @param thid - UID of the thread to be deleted.
	 *
	 * @return < 0 on error.
	 */
	int sceKernelDeleteThread(SceUID thid) {
		if (thid < 0) return -1;
		hleEmulatorState.uniqueIdFactory.remove!(ThreadState)(thid);
		return 0;
	}


	/+

	PspThread getThreadFromId(SceUID thid) {
		if ((thid in threadManager.createdThreads) is null) throw(new Exception(std.string.format("No thread with THID/UID(%d)", thid)));
		return threadManager.createdThreads[thid];
	}

	/**
	 * Resume a thread previously put into a suspended state with ::sceKernelSuspendThread.
	 *
	 * @param thid - UID of the thread to resume.
	 *
	 * @return Success if >= 0, an error if < 0.
	 */
	int sceKernelResumeThread(SceUID thid) {
		unimplemented();
		return -1;
	}


	/**
	 * Terminate and delete a thread.
	 *
	 * @param thid - UID of the thread to terminate and delete.
	 *
	 * @return Success if >= 0, an error if < 0.
	 */
	int sceKernelTerminateDeleteThread(SceUID thid) {
		return sceKernelDeleteThread(thid);
	}

	/**
	 * Wake a thread previously put into the sleep state.
	 *
	 * @param thid - UID of the thread to wake.
	 *
	 * @return Success if >= 0, an error if < 0.
	 */
	int sceKernelWakeupThread(SceUID thid) {
		unimplemented();
		return -1;
	}

	/**
	 * Suspend a thread.
	 *
	 * @param thid - UID of the thread to suspend.
	 *
	 * @return Success if >= 0, an error if < 0.
	 */
	int sceKernelSuspendThread(SceUID thid) {
		unimplemented();
		return -1;
	}

	/** 
	 * Wait until a thread has ended and handle callbacks if necessary.
	 *
	 * @param thid    - Id of the thread to wait for.
	 * @param timeout - Timeout in microseconds (assumed).
	 *
	 * @return < 0 on error.
	 */
	int sceKernelWaitThreadEndCB(SceUID thid, SceUInt *timeout) {
		unimplemented();
		return -1;
	}
		
	/**
	 * Get the current priority of the thread you are in.
	 *
	 * @return The current thread priority
	 */
	int sceKernelGetThreadCurrentPriority() {
		unimplemented();
		return -1;
	}

	/**
	 * Terminate a thread.
	 *
	 * @param thid - UID of the thread to terminate.
	 *
	 * @return Success if >= 0, an error if < 0.
	 */
	int sceKernelTerminateThread(SceUID thid) {
		unimplemented();
		return -1;
	}

	/**
	 * Get the exit status of a thread.
	 *
	 * @param thid - The UID of the thread to check.
	 *
	 * @return The exit status
	 */
	int sceKernelGetThreadExitStatus(SceUID thid) {
		unimplemented();
		return 0;
	}
	+/
}
