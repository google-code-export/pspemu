module pspemu.hle.ModuleManager;

import std.stdio;

import pspemu.hle.Module;
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

	/**
	 * Obtains a singleton instance of the module by a given name.
	 */
	Module getName(string moduleName) {
		if (moduleName !in loadedModules) {
			auto loadedModule = cast(Module)(ModuleNative.getModule(moduleName).create);
			loadedModule.hleEmulatorState = this.hleEmulatorState;
			//loadedModule.cpu = cpu;
			//loadedModule.moduleManager = this;
			loadedModule.init();
			loadedModules[moduleName] = loadedModule;
		}
		return loadedModules[moduleName];
	}

	void dumpLoadedModules() {
		writefln("LoadedModules {");
		foreach (_module; loadedModules) writefln("  '%s'", _module);
		writefln("}");
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
