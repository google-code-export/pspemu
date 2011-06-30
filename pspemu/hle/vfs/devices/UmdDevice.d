module pspemu.hle.vfs.devices.UmdDevice;

import pspemu.hle.vfs.devices.IoDevice;

import pspemu.utils.Logger;
import pspemu.hle.kd.SceKernelErrors;

class UmdDevice : IoDevice {
	this(HleEmulatorState hleEmulatorState, VirtualFileSystem parentVirtualFileSystem) {
		super(hleEmulatorState, parentVirtualFileSystem);
	}

	override int ioctl(FileHandle fileHandle, uint cmd, ubyte[] indata, ubyte[] outdata) {
		IoCtlCommand command = cast(IoCtlCommand)cmd;
		switch (command) {
			case IoCtlCommand.UmdSeekFile: {
				uint seekOffset = *(cast(uint*)indata.ptr);
				fileHandle.position = seekOffset;
				Logger.log(Logger.Level.INFO, "UmdDevice", "Seek: %d", seekOffset);
				return 0;
			} break;
			case IoCtlCommand.GetUmdFileLength: {
				if (outdata.length < 8) return SceKernelErrors.ERROR_INVALID_ARGUMENT;
				if (fileHandle is null) return SceKernelErrors.ERROR_INVALID_ARGUMENT;
				*(cast(ulong*)outdata.ptr) = cast(ulong)fileHandle.size;
				Logger.log(Logger.Level.INFO, "UmdDevice", "File Size: %d", fileHandle.size);
				return 0;
			} break;
			default:
				throw(new Exception(std.string.format("Unknown IoCtrlCommand 0x%08X (UmdDevice)", cmd)));
			break;
		}
		//throw(new Exception("Must implemente ioctl"));
	}

	override int devctl(string devname, uint cmd, ubyte[] indata, ubyte[] outdata) {
		throw(new Exception("Must implemente devctl (UmdDevice)"));
	}
}