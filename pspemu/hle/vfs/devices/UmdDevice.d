module pspemu.hle.vfs.devices.UmdDevice;

public import pspemu.hle.vfs.devices.IoDevice;

class UmdDevice : IoDevice {
	this(HleEmulatorState hleEmulatorState, VirtualFileSystem parentVirtualFileSystem) {
		super(hleEmulatorState, parentVirtualFileSystem);
	}

	override int ioctl(uint cmd, ubyte[] indata, ubyte[] outdata) {
		throw(new Exception("Must implemente ioctl"));
	}

	override int devctl(string devname, uint cmd, ubyte[] indata, ubyte[] outdata) {
		throw(new Exception("Must implemente devctl"));
	}
}