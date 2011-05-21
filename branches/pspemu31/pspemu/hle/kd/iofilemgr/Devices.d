module pspemu.hle.kd.iofilemgr.Devices;

//import pspemu.core.cpu.Interrupts;

import pspemu.hle.ModuleNative;

import pspemu.utils.Utils;
import pspemu.utils.Path;
import pspemu.utils.Logger;
import pspemu.utils.VirtualFileSystem;

import pspemu.hle.kd.iofilemgr.Types;

import pspemu.hle.Callbacks;
import pspemu.hle.HleEmulatorState;

class IoDevice : VFS_Proxy {
	//Cpu cpu;
	string name = "<iodev:unknown>";

	HleEmulatorState hleEmulatorState;

	this(HleEmulatorState hleEmulatorState, VFS node) {
		this.hleEmulatorState = hleEmulatorState;
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
	this(HleEmulatorState hleEmulatorState, VFS node) { super(hleEmulatorState, node); }
}

class MemoryStickDevice : IoDevice {
	bool _inserted = true;
	string name = "<iodev:mstick>";

	this(HleEmulatorState hleEmulatorState, VFS node) { super(hleEmulatorState, node); }

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
		if (_inserted != value) {
			_inserted = value;

			Logger.log(Logger.Level.INFO, "Devices", "MemoryStickDevice.setInserted: %d", _inserted);

			hleEmulatorState.callbacksHandler.trigger(
				CallbacksHandler.Type.MemoryStickInsertEject,
				[0, _inserted ? 1 : 2, 0]
			);
		}
		return _inserted;
	}

	override int sceIoDevctl(uint cmd, ubyte[] inData, ubyte[] outData) {
		PspCallback pspCallback;

		switch (cmd) {
			case 0x02025806: // MScmIsMediumInserted
				Logger.log(Logger.Level.INFO, "Devices", "MScmIsMediumInserted");
				*(cast(uint*)outData.ptr) = cast(uint)inserted;
			break;
			case 0x02415821: // MScmRegisterMSInsertEjectCallback
				Logger.log(Logger.Level.INFO, "Devices", "MScmRegisterMSInsertEjectCallback");

				pspCallback = hleEmulatorState.uniqueIdFactory.get!PspCallback(*(cast(uint*)inData.ptr));
				hleEmulatorState.callbacksHandler.register(CallbacksHandler.Type.MemoryStickInsertEject, pspCallback); 
			break;
			case 0x02415822: // MScmUnregisterMSInsertEjectCallback
				Logger.log(Logger.Level.INFO, "Devices", "MScmUnregisterMSInsertEjectCallback");
			
				pspCallback = hleEmulatorState.uniqueIdFactory.get!PspCallback(*(cast(uint*)inData.ptr));
				hleEmulatorState.callbacksHandler.unregister(CallbacksHandler.Type.MemoryStickInsertEject, pspCallback);
			break;
			default: // Unknown command
				Logger.log(Logger.Level.ERROR, "Devices", "MemoryStickDevice.sceIoDevctl: Unknown command 0x%08X!", cmd);
				return -1;
			break;
		}
		return 0;
	}
}
