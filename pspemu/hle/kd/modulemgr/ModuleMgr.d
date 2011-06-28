module pspemu.hle.kd.modulemgr.ModuleMgr; // kd/modulemgr.prx (sceModuleManager)

import pspemu.hle.ModuleNative;

import std.stream;
import std.stdio;

import pspemu.hle.ModuleNative;
import pspemu.hle.ModulePsp;
import pspemu.hle.kd.modulemgr.Types;
import pspemu.hle.kd.iofilemgr.Types;

//debug = DEBUG_SYSCALL;

import pspemu.hle.kd.threadman.ThreadMan; 
import pspemu.hle.kd.iofilemgr.IoFileMgr;
import pspemu.hle.vfs.VirtualFileSystem;

class ModuleMgrForUser : ModuleNative {
	void initNids() {
		mixin(registerd!(0xD675EBB8, sceKernelSelfStopUnloadModule));
		mixin(registerd!(0xB7F46618, sceKernelLoadModuleByID));
		mixin(registerd!(0x977DE386, sceKernelLoadModule));
		mixin(registerd!(0x50F0C1EC, sceKernelStartModule));
		mixin(registerd!(0xD1FF982A, sceKernelStopModule));
		mixin(registerd!(0x2E0911AA, sceKernelUnloadModule));
		mixin(registerd!(0xD8B73127, sceKernelGetModuleIdByAddress));
		mixin(registerd!(0xF0A26395, sceKernelGetModuleId));
		mixin(registerd!(0x8F2DF740, sceKernelStopUnloadSelfModuleWithStatus));
		mixin(registerd!(0x748CBED9, sceKernelQueryModuleInfo));
	}

	/**
	 * Query the information about a loaded module from its UID.
	 * @note This fails on v1.0 firmware (and even it worked has a limited structure)
	 * so if you want to be compatible with both 1.5 and 1.0 (and you are running in 
	 * kernel mode) then call this function first then ::pspSdkQueryModuleInfoV1 
	 * if it fails, or make separate v1 and v1.5+ builds.
	 *
	 * @param modid - The UID of the loaded module.
	 * @param info  - Pointer to a ::SceKernelModuleInfo structure.
	 * 
	 * @return 0 on success, otherwise one of ::PspKernelErrorCodes.
	 */
	int sceKernelQueryModuleInfo(SceUID modid, SceKernelModuleInfo* info) {
		unimplemented_notice();
		return 0;
	}
	
	uint sceKernelGetModuleIdByAddress() {
		unimplemented_notice();
		return 0;
	}

	/**
	 * Get module ID from the module that called the API. 
	 *
	 * @return >= 0 on success
	 */
	uint sceKernelGetModuleId() {
		//unimplemented();
		unimplemented_notice();
		
		ModulePsp modulePsp = new ModulePsp();
		modulePsp.dummyModule = true;
		return uniqueIdFactory.add(modulePsp);
	}

	uint sceKernelStopUnloadSelfModuleWithStatus() {
		unimplemented_notice();
		throw(new HaltException("sceKernelStopUnloadSelfModuleWithStatus"));
		return 0;
	}

	/**
	 * Stop and unload the current module.
	 *
	 * @param unknown - Unknown (I've seen 1 passed).
	 * @param argsize - Size (in bytes) of the arguments that will be passed to module_stop().
	 * @param argp    - Pointer to arguments that will be passed to module_stop().
	 *
	 * @return ??? on success, otherwise one of ::PspKernelErrorCodes.
	 */
	int sceKernelSelfStopUnloadModule(int unknown, SceSize argsize, void *argp) {
		//hleEmulatorState.emulatorState.runningState.stop();
		logWarning("sceKernelSelfStopUnloadModule");
		hleEmulatorState.emulatorState.runningState.stopCpu();
		throw(new HaltException("sceKernelSelfStopUnloadModule"));
		return 0;
	}

	/**
	 * Load a module from the given file UID.
	 *
	 * @param fid    - The module's file UID.
	 * @param flags  - Unused, always 0.
	 * @param option - Pointer to an optional ::SceKernelLMOption structure.
	 *
	 * @return The UID of the loaded module on success, otherwise one of ::PspKernelErrorCodes.
	 */
	SceUID sceKernelLoadModuleByID(SceUID fid, int flags, SceKernelLMOption *option) {
		FileHandle fileHandle = uniqueIdFactory.get!FileHandle(fid);

		logInfo("sceKernelLoadModuleByID(%d, %d, 0x%08X)", fid, flags, cast(uint)cast(void*)option);
		unimplemented_notice();
		return 0;
	}

	/**
	 * Load a module.
	 * @note This function restricts where it can load from (such as from flash0) 
	 * unless you call it in kernel mode. It also must be called from a thread.
	 * 
	 * @param path   - The path to the module to load.
	 * @param flags  - Unused, always 0 .
	 * @param option - Pointer to a mod_param_t structure. Can be NULL.
	 *
	 * @return The UID of the loaded module on success, otherwise one of ::PspKernelErrorCodes.
	 */
	SceUID sceKernelLoadModule(string path, int flags, SceKernelLMOption* option) {
		try {
			Logger.log(Logger.Level.INFO, "ModuleMgrForUser", "@WARNING FAKED :: sceKernelLoadModule('%s', %d, 0x%08X)", path, flags, cast(uint)option);
			
			IoFileMgrForKernel ioFileMgrForKernel = hleEmulatorState.moduleManager.get!IoFileMgrForKernel();
			//writefln("################# %s", path);
			//writefln("################# %s", ioFileMgrForKernel.locateParentAndUpdateFile(path));
			//writefln("################# %s", ioFileMgrForKernel.locateParentAndUpdateFile(path).open(path, FileMode.In));
			Stream moduleStream;
			moduleStream = ioFileMgrForKernel._open(path, SceIoFlags.PSP_O_RDONLY, octal!777);
			//writefln("############# %d", moduleStream.size);
			
			//ModulePsp modulePsp = hleEmulatorState.moduleLoader.load(path);
			ModulePsp modulePsp = hleEmulatorState.moduleLoader.load(moduleStream, path);
			
			// Fill the blank imports of the current module with the exports from the loaded module.
			currentThreadState().threadModule.fillImportsWithExports(currentMemory, modulePsp);
			
			Logger.log(Logger.Level.INFO, "ModuleMgrForUser", "sceKernelLoadModule.loaded");
			return uniqueIdFactory.add(modulePsp);
		} catch (Throwable o) {
			logError("Unable to load module sceKernelLoadModule '%s' : %s", path, o);
			
			ModulePsp modulePsp = new ModulePsp();
			modulePsp.dummyModule = true;
			return uniqueIdFactory.add(modulePsp);
		}
	}

	/**
	 * Start a loaded module.
	 *
	 * @param modid   - The ID of the module returned from LoadModule.
	 * @param argsize - Length of the args.
	 * @param argp    - A pointer to the arguments to the module.
	 * @param status  - Returns the status of the start.
	 * @param option  - Pointer to an optional ::SceKernelSMOption structure.
	 *
	 * @return ??? on success, otherwise one of ::PspKernelErrorCodes.
	 */
	int sceKernelStartModule(SceUID modid, SceSize argsize, uint argp, int *status, SceKernelSMOption *option) {
		if (modid == 0) {
			return 0;
		}
		
		ModulePsp modulePsp = uniqueIdFactory.get!ModulePsp(modid);
		
		if (modulePsp.dummyModule) {
			return 0;
		}
		
		ThreadManForUser threadManForUser = hleEmulatorState.moduleManager.get!ThreadManForUser();
		
		//SceUID sceKernelCreateThread(string name, SceKernelThreadEntry entry, int initPriority, int stackSize, SceUInt attr, SceKernelThreadOptParam *option)
		SceUID thid = threadManForUser.sceKernelCreateThread("main_thread", modulePsp.sceModule.entry_addr, 0, 0x1000, modulePsp.sceModule.attribute, null);
		ThreadState threadState = uniqueIdFactory.get!ThreadState(thid);
		threadState.threadModule = modulePsp;
		
		threadManForUser.sceKernelStartThread(thid, argsize, argp);
		
		return 0;
	}

	/**
	 * Stop a running module.
	 *
	 * @param modid   - The UID of the module to stop.
	 * @param argsize - The length of the arguments pointed to by argp.
	 * @param argp    - Pointer to arguments to pass to the module's module_stop() routine.
	 * @param status  - Return value of the module's module_stop() routine.
	 * @param option  - Pointer to an optional ::SceKernelSMOption structure.
	 *
	 * @return ??? on success, otherwise one of ::PspKernelErrorCodes.
	 */
	int sceKernelStopModule(SceUID modid, SceSize argsize, void *argp, int *status, SceKernelSMOption *option) {
		unimplemented_notice();
		return 0;
	}

	/**
	 * Unload a stopped module.
	 *
	 * @param modid - The UID of the module to unload.
	 *
	 * @return ??? on success, otherwise one of ::PspKernelErrorCodes.
	 */
	int sceKernelUnloadModule(SceUID modid) {
		unimplemented_notice();
		return 0;
	}
}

class ModuleMgrForKernel : ModuleMgrForUser {
}

static this() {
	mixin(ModuleNative.registerModule("ModuleMgrForKernel"));
	mixin(ModuleNative.registerModule("ModuleMgrForUser"));
}