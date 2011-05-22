module pspemu.hle.kd.modulemgr.ModuleMgrForUser; // kd/modulemgr.prx (sceModuleManager)

import std.stream;
import std.stdio;

import pspemu.hle.ModuleNative;
import pspemu.hle.ModulePsp;
import pspemu.hle.kd.modulemgr.Types;

//debug = DEBUG_SYSCALL;

import pspemu.hle.kd.threadman.ThreadManForUser; 
import pspemu.hle.kd.iofilemgr.IoFileMgrForKernel;

class ModuleMgrForUser : ModuleNative {
	void initNids() {
		mixin(registerd!(0xD675EBB8, sceKernelSelfStopUnloadModule));
		mixin(registerd!(0xB7F46618, sceKernelLoadModuleByID));
		mixin(registerd!(0x977DE386, sceKernelLoadModule));
		mixin(registerd!(0x50F0C1EC, sceKernelStartModule));
		mixin(registerd!(0xD1FF982A, sceKernelStopModule));
		mixin(registerd!(0x2E0911AA, sceKernelUnloadModule));
		mixin(registerd!(0xD8B73127, sceKernelGetModuleIdByAddressFunction));
		mixin(registerd!(0xF0A26395, sceKernelGetModuleIdFunction));
		mixin(registerd!(0x8F2DF740, ModuleMgrForUser_8F2DF740));
	}
	
	void sceKernelGetModuleIdByAddressFunction() {
		unimplemented();
	}

	void sceKernelGetModuleIdFunction() {
		unimplemented();
	}

	void ModuleMgrForUser_8F2DF740() {
		unimplemented();
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
		unimplemented();
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
		Logger.log(Logger.Level.INFO, "ModuleMgrForUser", "@WARNING FAKED :: sceKernelLoadModule('%s', %d, 0x%08X)", path, flags, cast(uint)option);
		
		IoFileMgrForKernel ioFileMgrForKernel = hleEmulatorState.moduleManager.get!IoFileMgrForKernel();
		//writefln("################# %s", path);
		//writefln("################# %s", ioFileMgrForKernel.locateParentAndUpdateFile(path));
		//writefln("################# %s", ioFileMgrForKernel.locateParentAndUpdateFile(path).open(path, FileMode.In));
		Stream moduleStream;
		moduleStream = ioFileMgrForKernel.locateParentAndUpdateFile(path).open(path, FileMode.In);
		//writefln("############# %d", moduleStream.size);
		
		//ModulePsp modulePsp = hleEmulatorState.moduleLoader.load(path);
		ModulePsp modulePsp = hleEmulatorState.moduleLoader.load(moduleStream, path);
		
		// Fill the blank imports of the current module with the exports from the loaded module.
		currentThreadState().threadModule.fillImportsWithExports(currentMemory, modulePsp);
		
		Logger.log(Logger.Level.INFO, "ModuleMgrForUser", "sceKernelLoadModule.loaded");
		return hleEmulatorState.uniqueIdFactory.add(modulePsp);
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
		ModulePsp modulePsp = hleEmulatorState.uniqueIdFactory.get!ModulePsp(modid);
		
		ThreadManForUser threadManForUser = hleEmulatorState.moduleManager.get!ThreadManForUser();
		
		//SceUID sceKernelCreateThread(string name, SceKernelThreadEntry entry, int initPriority, int stackSize, SceUInt attr, SceKernelThreadOptParam *option)
		SceUID thid = threadManForUser.sceKernelCreateThread("main_thread", modulePsp.sceModule.entry_addr, 0, 0x1000, modulePsp.sceModule.attribute, null);
		ThreadState threadState = hleEmulatorState.uniqueIdFactory.get!ThreadState(thid);
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
		unimplemented();
		return -1;
	}

	/**
	 * Unload a stopped module.
	 *
	 * @param modid - The UID of the module to unload.
	 *
	 * @return ??? on success, otherwise one of ::PspKernelErrorCodes.
	 */
	int sceKernelUnloadModule(SceUID modid) {
		unimplemented();
		return -1;
	}
}

static this() {
	mixin(ModuleNative.registerModule("ModuleMgrForUser"));
}