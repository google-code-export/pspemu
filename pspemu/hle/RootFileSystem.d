module pspemu.hle.RootFileSystem;

import std.string;

import pspemu.utils.Logger;
import pspemu.utils.Path;

import pspemu.hle.HleEmulatorState;
import pspemu.utils.VirtualFileSystem;
import pspemu.hle.kd.iofilemgr.Devices;

class RootFileSystem {
	HleEmulatorState hleEmulatorState;
	VFS fsroot, gameroot;
	IoDevice[string] devices;
	string fscurdir;
	
	this(HleEmulatorState hleEmulatorState) {
		this.hleEmulatorState = hleEmulatorState;
		init();
	}

	void init() {
		//.writefln("[1]");
		fsroot = new VFS("<root>");
		//.writefln("[2]");

		// Devices.
		devices["ms0:"   ] = new MemoryStickDevice(hleEmulatorState, new FileSystem(ApplicationPaths.exe ~ "/pspfs/ms0", "ms0:"));
		devices["flash0:"] = new IoDevice         (hleEmulatorState, new FileSystem(ApplicationPaths.exe ~ "/pspfs/flash0", "flash0:"));
		devices["flash1:"] = new IoDevice         (hleEmulatorState, new FileSystem(ApplicationPaths.exe ~ "/pspfs/flash1", "flash1:"));
		devices["umd0:"  ] = new UmdDevice        (hleEmulatorState, new FileSystem(ApplicationPaths.exe ~ "/pspfs/umd0", "umd0:"));
		//.writefln("[3]");
	
		// Aliases.
		devices["disc0:" ] = devices["umd0:"];
		devices["ms:"    ] = devices["ms0:"];
		devices["fatms0:"] = devices["ms0:"];
		//.writefln("[4]");

		// Mount registered devices:
		foreach (deviceName, device; devices) fsroot.addChild(device, deviceName);
		
		//.writefln("[5]");
		
		fscurdir = "ms0:/PSP/GAME/virtual";
		//writefln("%s", fsroot[fscurdir]);
		gameroot = new VFS_Proxy("<gameroot>", fsroot[fscurdir]);
	}
	
	void setVirtualDir(string path) {
		// No absolute path; Relative path. No starts by '/' nor contains ':'.
		if ((path[0] == '/') || (path.indexOf(':') != -1)) {
			//writefln("set absolute!");
		} else {
			//writefln("path already absolute!");
			path = std.file.getcwd() ~ '/' ~ path;
		}
		//writefln("setVirtualDir('%s')", path);

		fsroot["ms0:/PSP/GAME"].addChild(new FileSystem(path), "virtual");
		gameroot = new VFS_Proxy("<gameroot>", fsroot[fscurdir]);
		
		Logger.log(Logger.Level.INFO, "IoFileMgrForKernel", "Setted ms0:/PSP/GAME/virtual to '%s'", path);
	}
}