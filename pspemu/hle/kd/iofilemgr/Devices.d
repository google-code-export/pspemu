module pspemu.hle.kd.iofilemgr.Devices;

//import pspemu.core.cpu.Interrupts;

import pspemu.hle.ModuleNative;

import pspemu.utils.Utils;
import pspemu.utils.Path;
import pspemu.utils.Logger;
import pspemu.utils.VirtualFileSystem;

import pspemu.hle.kd.iofilemgr.Types;

class IoDevice : VFS_Proxy {
	//Cpu cpu;
	string name = "<iodev:unknown>";

	this(VFS node) {
		super(name, node, null);
		register();
	}
	
	void register() {
	}
	
	bool present() { return true; }
	
	bool inserted() { return false; }
	bool inserted(bool value) { return false; }

	int sceIoDevctl(uint cmd, ubyte[] inData, ubyte[] outData) {
		return -1;
	}
}

class UmdDevice : IoDevice {
	this(VFS node) { super(node); }
}

class MemoryStickDevice : IoDevice {
	bool _inserted = true;
	bool[uint] callbacks;
	string name = "<iodev:mstick>";

	this(VFS node) { super(node); }

	override void register() {
		//writefln("MemoryStickDevice.register");
		/*
		cpu.interrupts.registerCallback(Interrupts.Type.GPIO, delegate void() {
			writefln("MemoryStickDevice.processGPIO");
			cpu.queueCallbacks(callbacks.keys, []);
		});
		*/
	}

	override bool inserted() { return _inserted; }
	override bool inserted(bool value) {
		/*
		if (_inserted != value) {
			_inserted = value;
			cpu.interrupts.queue(Interrupts.Type.GPIO);
		}
		return _inserted;
		*/
		return _inserted;
	}

	override int sceIoDevctl(uint cmd, ubyte[] inData, ubyte[] outData) {
		/*
		switch (cmd) {
			case 0x02025806: // MScmIsMediumInserted
				*(cast(uint*)outData.ptr) = cast(uint)inserted;
				writefln("MScmIsMediumInserted");
			break;
			case 0x02415821: // MScmRegisterMSInsertEjectCallback
				uint callback = *(cast(uint*)inData.ptr);
				callbacks[callback] = true;
				writefln("MScmRegisterMSInsertEjectCallback");
			break;
			case 0x02415822: // MScmUnregisterMSInsertEjectCallback
				uint callback = *(cast(uint*)inData.ptr);
				callbacks.remove(callback);
				writefln("MScmUnregisterMSInsertEjectCallback");
			break;
			default: // Unknown command
				writefln("MemoryStickDevice.sceIoDevctl: Unknown command 0x%08X!", cmd);
				return -1;
			break;
		}
		*/
		return 0;
	}
}
