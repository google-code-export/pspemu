module pspemu.hle.ModuleManager;

import std.stdio;
import std.stream;

import pspemu.hle.Module;
import pspemu.hle.ModulePsp;
import pspemu.hle.ModuleNative;

import pspemu.hle.HleEmulatorState;

//public import pspemu.All;
class ModuleManager {
	/**
	 * A list of modules loaded.
	 */
	private Module[string] loadedModules;

	string delegate() getCurrentThreadName;
	
	HleEmulatorState hleEmulatorState;
	
	public this(HleEmulatorState hleEmulatorState) {
		this.hleEmulatorState = hleEmulatorState;
	}

	void reset() {
		//Logger.log(Logger.Level.DEBUG, "ModuleManager", "reset()");
		foreach (loadedModule; loadedModules) loadedModule.shutdownModule();
		loadedModules = null;
		getCurrentThreadName = null;
	}
	
	string currentThreadName() {
		string s = getCurrentThreadName ? getCurrentThreadName() : "<unknown>";
		return std.string.format("Thread('%-12s')", s);
	}
	
	ModulePsp createDummyModule() {
		ModulePsp loadedModule = new ModulePsp();
		loadedModule.dummyModule = true;
		loadedModule.modid = hleEmulatorState.uniqueIdFactory.add!Module(loadedModule);
		return loadedModule;
	}
	
	ModulePsp loadPspModule(Stream stream, string fileName = "?unknownFileName?") {
		//writefln("[1]");
		ModulePsp loadedModule = hleEmulatorState.moduleLoader.load(stream, fileName);
		//writefln("[2]");
		loadedModule.modid = hleEmulatorState.uniqueIdFactory.add!Module(loadedModule);
		//writefln("[3]");
		if (fileName in loadedModules) throw(new Exception("Module already loaded"));
		loadedModules[fileName] = loadedModule; 
		//writefln("[4]");
		return loadedModule;
	}

	/**
	 * Obtains a singleton instance of the module by a given name.
	 */
	Module getName(string moduleName) {
		if (moduleName !in loadedModules) {
			Logger.log(Logger.Level.INFO, "ModuleManager", "%08X :: Loading module '%s'", cast(uint)cast(void *)this, moduleName);
			Module loadedModule = cast(Module)(ModuleNative.getModule(moduleName).create);
			loadedModule.hleEmulatorState = this.hleEmulatorState;
			//loadedModule.cpu = cpu;
			//loadedModule.moduleManager = this;
			loadedModule.init();
			loadedModules[moduleName] = loadedModule;

			loadedModule.modid = hleEmulatorState.uniqueIdFactory.add!Module(loadedModule);
		}
		return loadedModules[moduleName];
	}

	void dumpLoadedModules() {
		writefln("LoadedModules {");
		foreach (_module; loadedModules) writefln("  '%s'", _module);
		writefln("}");
	}
	
	Module getModuleByAddress(uint addr) {
		foreach (loadedModule; loadedModules) {
			if (addr == loadedModule.entryPoint) return loadedModule; 
		}
		throw(new Exception("Not implemented getModuleByAddress"));
		return null;
	}

	/**
	 * Obtains a singleton instance of the module by a given type.
	 */
	Type get(alias Type)() {
		return cast(Type)getName(Type.stringof);
	}

	/**
	 * Alias for getting a module.
	 */
	alias getName opIndex;
}
