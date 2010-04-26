module pspemu.hle.kd.iofilemgr; // kd/iofilemgr.prx (sceIOFileManager)

//debug = DEBUG_SYSCALL;

import std.date;

import pspemu.core.cpu.Interrupts;

import pspemu.hle.Module;

import pspemu.utils.Utils;
import pspemu.utils.VirtualFileSystem;

import pspemu.utils.Logger;

class IoDevice : VFS_Proxy {
	Cpu cpu;
	string name = "<iodev:unknown>";

	this(Cpu cpu, VFS node) {
		this.cpu = cpu;
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
	this(Cpu cpu, VFS node) { super(cpu, node); }
}

class MemoryStickDevice : IoDevice {
	bool _inserted = true;
	bool[uint] callbacks;
	string name = "<iodev:mstick>";

	this(Cpu cpu, VFS node) { super(cpu, node); }

	override void register() {
		//writefln("MemoryStickDevice.register");
		cpu.interrupts.registerCallback(Interrupts.Type.GPIO, delegate void() {
			writefln("MemoryStickDevice.processGPIO");
			cpu.queueCallbacks(callbacks.keys, []);
		});
	}

	override bool inserted() { return _inserted; }
	override bool inserted(bool value) {
		if (_inserted != value) {
			_inserted = value;
			cpu.interrupts.queue(Interrupts.Type.GPIO);
		}
		return _inserted;
	}

	override int sceIoDevctl(uint cmd, ubyte[] inData, ubyte[] outData) {
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
		return 0;
	}
}

class IoFileMgrForKernel : Module {
	VFS fsroot, gameroot;
	IoDevice[string] devices;
	string fscurdir;

	void initModule() {
		fsroot = new VFS("<root>");

		// Devices.
		devices["ms0:"   ] = new MemoryStickDevice(this.cpu, new FileSystem(ApplicationPaths.exe ~ "/pspfs/ms0"));
		devices["flash0:"] = new IoDevice         (this.cpu, new FileSystem(ApplicationPaths.exe ~ "/pspfs/flash0"));
		devices["flash1:"] = new IoDevice         (this.cpu, new FileSystem(ApplicationPaths.exe ~ "/pspfs/flash0"));
		devices["umd0:"  ] = new UmdDevice        (this.cpu, new FileSystem(ApplicationPaths.exe ~ "/pspfs/umd0"));
	
		// Aliases.
		devices["disc0:" ] = devices["umd0:"];
		devices["ms:"    ] = devices["ms0:"];
		devices["fatms0:"] = devices["ms0:"];

		// Mount registered devices:
		foreach (deviceName, device; devices) fsroot.addChild(device, deviceName);
		
		fscurdir = "ms0:/PSP/GAME/virtual";
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
	}

	void initNids() {
		mixin(registerd!(0x55F4717D, sceIoChdir));
		mixin(registerd!(0x810C4BC3, sceIoClose));
		mixin(registerd!(0x109F50BC, sceIoOpen));
		mixin(registerd!(0x6A638D83, sceIoRead));
		mixin(registerd!(0x42EC03AC, sceIoWrite));
		mixin(registerd!(0x27EB27B8, sceIoLseek));
		mixin(registerd!(0x68963324, sceIoLseek32));

		mixin(registerd!(0x54F5FB11, sceIoDevctl));

		mixin(registerd!(0xACE946E8, sceIoGetstat));
		mixin(registerd!(0xB8A740F4, sceIoChstat));
		mixin(registerd!(0xF27A9C51, sceIoRemove));
		mixin(registerd!(0x779103A0, sceIoRename));

		mixin(registerd!(0xB29DDF9C, sceIoDopen));
		mixin(registerd!(0xEB092469, sceIoDclose));
		mixin(registerd!(0xE3EB004C, sceIoDread));
		mixin(registerd!(0x06A70004, sceIoMkdir));
		mixin(registerd!(0x1117C65F, sceIoRmdir));

		mixin(registerd!(0x89AA9906, sceIoOpenAsync));
		mixin(registerd!(0x71B19E77, sceIoLseekAsync));
		mixin(registerd!(0xFF5940B6, sceIoCloseAsync));
		mixin(registerd!(0xA0B5A7C2, sceIoReadAsync));
		mixin(registerd!(0xB293727F, sceIoChangeAsyncPriority));
		mixin(registerd!(0xE23EEC33, sceIoWaitAsync));
		mixin(registerd!(0x3251EA56, sceIoPollAsync));
		mixin(registerd!(0x0FACAB19, sceIoWriteAsync));
		
		mixin(registerd!(0x63632449, sceIoIoctl));

		mixin(registerd!(0x3C54E908, sceIoReopen));
		mixin(registerd!(0x8E982A74, sceIoAddDrv));
		mixin(registerd!(0xC7F35804, sceIoDelDrv));
	}

	Stream[SceUID] openedStreams;

	Stream getStreamFromFD(SceUID uid) {
		if ((uid in openedStreams) is null) {
			//throw(new Exception(std.string.format("No file opened with FD/UID(%d)", uid)));
			Logger.log(Logger.Level.WARNING, "iofilemgr", "No file opened with FD/UID(%d)", uid);
		}
		return openedStreams[uid];
	}

	/** 
	  * Reads an entry from an opened file descriptor.
	  *
	  * @param fd - Already opened file descriptor (using sceIoDopen)
	  * @param dir - Pointer to an io_dirent_t structure to hold the file information
	  *
	  * @return Read status
	  * -   0 - No more directory entries left
	  * - > 0 - More directory entired to go
	  * - < 0 - Error
	  */
	int sceIoDread(SceUID fd, SceIoDirent *dir) {
		unimplemented();
		return -1;
	}

	/**
	 * Make a directory file
	 *
	 * @param path
	 * @param mode - Access mode.
	 * @return Returns the value 0 if its succesful otherwise -1
	 */
	int sceIoMkdir(string path, SceMode mode) {
		auto vfs = locateParentAndUpdateFile(path);
		try {
			vfs.mkdir(path);
			return 0;
		} catch (Exception e) {
			//throw(e);
			return -1;
		}
	}

	/**
	 * Remove a directory file
	 *
	 * @param path - Removes a directory file pointed by the string path
	 * @return Returns the value 0 if its succesful otherwise -1
	 */
	int sceIoRmdir(string path) {
		unimplemented();
		return -1;
	}

	/**
	 * Change the name of a file
	 *
	 * @param oldname - The old filename
	 * @param newname - The new filename
	 * @return < 0 on error.
	 */
	int sceIoRename(string oldname, string newname) {
		unimplemented();
		return -1;
	}

	/**
	 * Open a directory
	 * 
	 * @par Example:
	 * @code
	 * int dfd;
	 * dfd = sceIoDopen("device:/");
	 * if(dfd >= 0)
	 * { Do something with the file descriptor }
	 * @endcode
	 * @param dirname - The directory to open for reading.
	 * @return If >= 0 then a valid file descriptor, otherwise a Sony error code.
	 */
	SceUID sceIoDopen(string dirname) {
		unimplemented();
		return -1;
	}

	/**
	 * Close an opened directory file descriptor
	 *
	 * @param fd - Already opened file descriptor (using sceIoDopen)
	 * @return < 0 on error
	 */
	int sceIoDclose(SceUID fd) {
		unimplemented();
		return -1;
	}

	/**
	 * Change the current directory.
	 *
	 * @param path - The path to change to.
	 * @return < 0 on error.
	 */
	int sceIoChdir(string path) {
		try {
			fscurdir = path;
			fsroot[fscurdir];
			//unimplemented();
			//return -1;
			return 0;
		} catch (Exception e) {
			//throw(e);
			return -1;
		}
	}

	/** 
	 * Send a devctl command to a device.
	 *
	 * @par Example: Sending a simple command to a device (not a real devctl)
	 * @code
	 * sceIoDevctl("ms0:", 0x200000, indata, 4, NULL, NULL); 
	 * @endcode
	 *
	 * @param dev - String for the device to send the devctl to (e.g. "ms0:")
	 * @param cmd - The command to send to the device
	 * @param indata - A data block to send to the device, if NULL sends no data
	 * @param inlen - Length of indata, if 0 sends no data
	 * @param outdata - A data block to receive the result of a command, if NULL receives no data
	 * @param outlen - Length of outdata, if 0 receives no data
	 * @return 0 on success, < 0 on error
	 */
	int sceIoDevctl(string dev, int cmd, void* indata, int inlen, void* outdata, int outlen) {
		try {
			return devices[dev].sceIoDevctl(cmd, (cast(ubyte*)indata)[0..inlen], (cast(ubyte*)outdata)[0..outlen]);
		} catch (Exception e) {
			writefln("sceIoDevctl: %s", e);
			return -1;
		}
	}

	/**
	 * Delete a descriptor
	 *
	 * @code
	 * sceIoClose(fd);
	 * @endcode
	 *
	 * @param fd - File descriptor to close
	 * @return < 0 on error
	 */
	int sceIoClose(SceUID fd) {
		if (fd < 0) return -1;
		auto stream = getStreamFromFD(fd);
		openedStreams.remove(fd);
		stream.flush();
		stream.close();
		return 0;
	}

	VFS locateParentAndUpdateFile(ref string file) {
		VFS vfs = gameroot;

		// A full path.
		auto index = file.indexOf(":");
		if (index >= 0) {
			vfs = fsroot;
			vfs = vfs[file[0..index + 1]];
			file = file[index + 1..$];
			while (file.length && file[0] == '/') file = file[1..$];
		}
		
		//writefln("\n\n\nSELECTED DIR: %s\n\n", vfs);

		return vfs;
	}

	/**
	 * Open or create a file for reading or writing
	 *
	 * @par Example1: Open a file for reading
	 * @code
	 * if(!(fd = sceIoOpen("device:/path/to/file", O_RDONLY, 0777)) {
	 *	// error
	 * }
	 * @endcode
	 * @par Example2: Open a file for writing, creating it if it doesnt exist
	 * @code
	 * if(!(fd = sceIoOpen("device:/path/to/file", O_WRONLY|O_CREAT, 0777)) {
	 *	// error
	 * }
	 * @endcode
	 *
	 * @param file - Pointer to a string holding the name of the file to open
	 * @param flags - Libc styled flags that are or'ed together
	 * @param mode - File access mode.
	 * @return A non-negative integer is a valid fd, anything else an error
	 */
	SceUID sceIoOpen(/*const*/ string file, int flags, SceMode mode) {
		try {
			FileMode fmode;

			if (flags & PSP_O_RDONLY) fmode |= FileMode.In;
			if (flags & PSP_O_WRONLY) fmode |= FileMode.Out;
			if (flags & PSP_O_APPEND) fmode |= FileMode.Append;
			if (flags & PSP_O_CREAT ) fmode |= FileMode.OutNew;
			
			writefln("Open: Flags:%08X, Mode:%03o, File:'%s'", flags, mode, file);
			
			SceUID fd = 0; foreach (fd_cur; openedStreams.keys) if (fd < fd_cur) fd = fd_cur; fd++;
			openedStreams[fd] = locateParentAndUpdateFile(file).open(file, fmode, 0777);
			return fd;
		} catch (Object o) {
			writefln("sceIoOpen exception: %s", o);
			return -1;
		}
	}

	/**
	 * Read input
	 *
	 * @par Example:
	 * @code
	 * bytes_read = sceIoRead(fd, data, 100);
	 * @endcode
	 *
	 * @param fd - Opened file descriptor to read from
	 * @param data - Pointer to the buffer where the read data will be placed
	 * @param size - Size of the read in bytes
	 * 
	 * @return The number of bytes read
	 */
	int sceIoRead(SceUID fd, void* data, SceSize size) {
		if (fd < 0) return -1;
		if (data is null) return -1;
		auto stream = getStreamFromFD(fd);
		try {
			return stream.read((cast(ubyte *)data)[0..size]);
		} catch (Object o) {
			throw(o);
			return -1;
		}
	}

	/**
	 * Write output
	 *
	 * @par Example:
	 * @code
	 * bytes_written = sceIoWrite(fd, data, 100);
	 * @endcode
	 *
	 * @param fd - Opened file descriptor to write to
	 * @param data - Pointer to the data to write
	 * @param size - Size of data to write
	 *
	 * @return The number of bytes written
	 */
	int sceIoWrite(SceUID fd, /*const*/ void* data, SceSize size) {
		if (fd < 0) return -1;
		if (data is null) return -1;
		auto stream = getStreamFromFD(fd);

		// Less than 256 MB.
		if (stream.position >= 256 * 1024 * 1024) {
			throw(new Exception(std.string.format("Write position over 256MB! There was a prolem with sceIoWrite: position(%d)", stream.position)));
		}

		try {
			return stream.write((cast(ubyte *)data)[0..size]);
		} catch (Object o) {
			throw(o);
			return -1;
		}
	}

	/**
	 * Reposition read/write file descriptor offset
	 *
	 * @par Example:
	 * @code
	 * pos = sceIoLseek(fd, -10, SEEK_END);
	 * @endcode
	 *
	 * @param fd - Opened file descriptor with which to seek
	 * @param offset - Relative offset from the start position given by whence
	 * @param whence - Set to SEEK_SET to seek from the start of the file, SEEK_CUR
	 * seek from the current position and SEEK_END to seek from the end.
	 *
	 * @return The position in the file after the seek. 
	 */
	SceOff sceIoLseek(SceUID fd, SceOff offset, int whence) {
		if (fd < 0) return -1;
		auto stream = getStreamFromFD(fd);
		stream.seek(offset, cast(SeekPos)whence);
		return stream.position;
	}

	/**
	 * Reposition read/write file descriptor offset (32bit mode)
	 *
	 * @par Example:
	 * @code
	 * pos = sceIoLseek32(fd, -10, SEEK_END);
	 * @endcode
	 *
	 * @param fd - Opened file descriptor with which to seek
	 * @param offset - Relative offset from the start position given by whence
	 * @param whence - Set to SEEK_SET to seek from the start of the file, SEEK_CUR
	 * seek from the current position and SEEK_END to seek from the end.
	 *
	 * @return The position in the file after the seek. 
	 */
	int sceIoLseek32(SceUID fd, int offset, int whence) {
		return cast(int)sceIoLseek(fd, offset, whence);
	}

	/** 
	  * Get the status of a file.
	  * 
	  * @param file - The path to the file.
	  * @param stat - A pointer to an io_stat_t structure.
	  * 
	  * @return < 0 on error.
	  */
	int sceIoGetstat(string file, SceIoStat* stat) {
		ScePspDateTime convertTime(d_time timeD) {
			ScePspDateTime dateTimePsp;
			std.date.Date dateTimeD;
			dateTimeD.parse(toUTCString(timeD));
			with (dateTimePsp) {
				year   = cast(ushort)dateTimeD.year;
				month  = cast(ushort)dateTimeD.month;
				day    = cast(ushort)dateTimeD.day;
				hour   = cast(ushort)dateTimeD.hour;
				minute = cast(ushort)dateTimeD.minute;
				second = cast(ushort)dateTimeD.second;
				microsecond = dateTimeD.ms * 1000;
			}
			return dateTimePsp;
		}
		
		try {
			locateParentAndUpdateFile(file).flush();
			auto fentry = locateParentAndUpdateFile(file)[file];
			
			{
				stat.st_mode = 0;
				
				// User access rights mask
				stat.st_mode |= IOAccessModes.FIO_S_IRUSR | IOAccessModes.FIO_S_IWUSR | IOAccessModes.FIO_S_IXUSR;
				// Group access rights mask
				stat.st_mode |= IOAccessModes.FIO_S_IRGRP | IOAccessModes.FIO_S_IWGRP | IOAccessModes.FIO_S_IXGRP;
				// Others access rights mask
				stat.st_mode |= IOAccessModes.FIO_S_IROTH | IOAccessModes.FIO_S_IWOTH | IOAccessModes.FIO_S_IXOTH;

				//stat.st_mode |= FIO_S_IFLNK
				stat.st_mode |= fentry.stats.isdir ? IOAccessModes.FIO_S_IFDIR : IOAccessModes.FIO_S_IFREG;
			}
			{
				stat.st_attr  = 0;
				
				//stat.st_attr |= IOFileModes.FIO_SO_IFLNK;

				stat.st_attr |= fentry.stats.isdir ? IOFileModes.FIO_SO_IFDIR : IOFileModes.FIO_SO_IFREG;
				stat.st_attr |= IOFileModes.FIO_SO_IROTH | IOFileModes.FIO_SO_IWOTH | IOFileModes.FIO_SO_IXOTH; // rwx
			}
			
			stat.st_size  = fentry.stats.size;
			stat.st_ctime = convertTime(fentry.stats.time_c);
			stat.st_atime = convertTime(fentry.stats.time_a);
			stat.st_mtime = convertTime(fentry.stats.time_m);
			return 0;
		} catch (Exception e) {
			writefln("ERROR: STAT!! FAILED: %s", e);
			return -1;
		}
	}

	/** 
	 * Change the status of a file.
	 *
	 * @param file - The path to the file.
	 * @param stat - A pointer to an io_stat_t structure.
	 * @param bits - Bitmask defining which bits to change.
	 *
	 * @return < 0 on error.
	 */
	int sceIoChstat(string file, SceIoStat *stat, int bits) {
		unimplemented();
		return -1;
	}

	/**
	 * Remove directory entry
	 *
	 * @param file - Path to the file to remove
	 * @return < 0 on error
	 */
	int sceIoRemove(string file) {
		unimplemented_notice();
		return 0;
	}

	/**
	 * Open or create a file for reading or writing (asynchronous)
	 *
	 * @param file - Pointer to a string holding the name of the file to open
	 * @param flags - Libc styled flags that are or'ed together
	 * @param mode - File access mode.
	 * @return A non-negative integer is a valid fd, anything else an error
	 */
	SceUID sceIoOpenAsync(string file, int flags, SceMode mode) {
		unimplemented();
		return -1;
	}

	/**
	 * Reposition read/write file descriptor offset (asynchronous)
	 *
	 * @param fd - Opened file descriptor with which to seek
	 * @param offset - Relative offset from the start position given by whence
	 * @param whence - Set to SEEK_SET to seek from the start of the file, SEEK_CUR
	 * seek from the current position and SEEK_END to seek from the end.
	 *
	 * @return < 0 on error. Actual value should be passed returned by the ::sceIoWaitAsync call.
	 */
	int sceIoLseekAsync(SceUID fd, SceOff offset, int whence) {
		unimplemented();
		return -1;
	}

	/**
	 * Delete a descriptor (asynchronous)
	 *
	 * @param fd - File descriptor to close
	 * @return < 0 on error
	 */
	int sceIoCloseAsync(SceUID fd) {
		unimplemented();
		return -1;
	}

	/**
	 * Read input (asynchronous)
	 *
	 * @par Example:
	 * @code
	 * bytes_read = sceIoRead(fd, data, 100);
	 * @endcode
	 *
	 * @param fd - Opened file descriptor to read from
	 * @param data - Pointer to the buffer where the read data will be placed
	 * @param size - Size of the read in bytes
	 * 
	 * @return < 0 on error.
	 */
	int sceIoReadAsync(SceUID fd, void *data, SceSize size) {
		unimplemented();
		return -1;
	}

	/**
	 * Change the priority of the asynchronous thread.
	 *
	 * @param fd - The opened fd on which the priority should be changed.
	 * @param pri - The priority of the thread.
	 *
	 * @return < 0 on error.
	 */
	int sceIoChangeAsyncPriority(SceUID fd, int pri) {
		unimplemented();
		return -1;
	}

	/**
	 * Wait for asyncronous completion.
	 * 
	 * @param fd - The file descriptor which is current performing an asynchronous action.
	 * @param res - The result of the async action.
	 *
	 * @return < 0 on error.
	 */
	int sceIoWaitAsync(SceUID fd, SceInt64* res) {
		unimplemented();
		return -1;
	}

	/**
	 * Poll for asyncronous completion.
	 * 
	 * @param fd - The file descriptor which is current performing an asynchronous action.
	 * @param res - The result of the async action.
	 *
	 * @return < 0 on error.
	 */
	int sceIoPollAsync(SceUID fd, SceInt64 *res) {
		unimplemented();
		return -1;
	}

	/**
	 * Write output (asynchronous)
	 *
	 * @param fd - Opened file descriptor to write to
	 * @param data - Pointer to the data to write
	 * @param size - Size of data to write
	 *
	 * @return < 0 on error.
	 */
	int sceIoWriteAsync(SceUID fd, void* data, SceSize size) {
		unimplemented();
		return -1;
	}

	/**
	 * Perform an ioctl on a device.
	 *
	 * @param fd - Opened file descriptor to ioctl to
	 * @param cmd - The command to send to the device
	 * @param indata - A data block to send to the device, if NULL sends no data
	 * @param inlen - Length of indata, if 0 sends no data
	 * @param outdata - A data block to receive the result of a command, if NULL receives no data
	 * @param outlen - Length of outdata, if 0 receives no data
	 * @return 0 on success, < 0 on error
	 */
	int sceIoIoctl(SceUID fd, uint cmd, void* indata, int inlen, void* outdata, int outlen) {
		unimplemented();
		return -1;
	}

	/**
	 * Reopens an existing file descriptor.
	 *
	 * @param file - The new file to open.
	 * @param flags - The open flags.
	 * @param mode - The open mode.
	 * @param fd - The old filedescriptor to reopen
	 *
	 * @return < 0 on error, otherwise the reopened fd.
	 */
	int sceIoReopen(string file, int flags, SceMode mode, SceUID fd) {
		unimplemented();
		return -1;
	}

	/** 
	 * Adds a new IO driver to the system.
	 * @note This is only exported in the kernel version of IoFileMgr
	 * 
	 * @param drv - Pointer to a filled out driver structure
	 * @return < 0 on error.
	 *
	 * @par Example:
	 * @code
	 * PspIoDrvFuncs host_funcs = { ... };
	 * PspIoDrv host_driver = { "host", 0x10, 0x800, "HOST", &host_funcs };
	 * sceIoDelDrv("host");
	 * sceIoAddDrv(&host_driver);
	 * @endcode
	 */
	int sceIoAddDrv(PspIoDrv* drv) {
		unimplemented();
		return -1;
	}

	/**
	 * Deletes a IO driver from the system.
	 * @note This is only exported in the kernel version of IoFileMgr
	 *
	 * @param drv_name - Name of the driver to delete.
	 * @return < 0 on error
	 */
	int sceIoDelDrv(string drv_name) {
		unimplemented();
		return -1;
	}
}

class IoFileMgrForUser : IoFileMgrForKernel {
}

enum { SEEK_SET = 0, SEEK_CUR = 1, SEEK_END = 2 }

/** Access modes for st_mode in SceIoStat (confirm?). */
enum IOAccessModes {
	/** Format bits mask */
	FIO_S_IFMT		= 0xF000,
	/** Symbolic link */
	FIO_S_IFLNK		= 0x4000,
	/** Directory */
	FIO_S_IFDIR		= 0x1000,
	/** Regular file */
	FIO_S_IFREG		= 0x2000,

	/** Set UID */
	FIO_S_ISUID		= 0x0800,
	/** Set GID */
	FIO_S_ISGID		= 0x0400,
	/** Sticky */
	FIO_S_ISVTX		= 0x0200,

	/** User access rights mask */
	FIO_S_IRWXU		= 0x01C0,	
	/** Read user permission */
	FIO_S_IRUSR		= 0x0100,
	/** Write user permission */
	FIO_S_IWUSR		= 0x0080,
	/** Execute user permission */
	FIO_S_IXUSR		= 0x0040,	

	/** Group access rights mask */
	FIO_S_IRWXG		= 0x0038,	
	/** Group read permission */
	FIO_S_IRGRP		= 0x0020,
	/** Group write permission */
	FIO_S_IWGRP		= 0x0010,
	/** Group execute permission */
	FIO_S_IXGRP		= 0x0008,

	/** Others access rights mask */
	FIO_S_IRWXO		= 0x0007,	
	/** Others read permission */
	FIO_S_IROTH		= 0x0004,	
	/** Others write permission */
	FIO_S_IWOTH		= 0x0002,	
	/** Others execute permission */
	FIO_S_IXOTH		= 0x0001,	
}

/** File modes, used for the st_attr parameter in SceIoStat (confirm?). */
enum IOFileModes {
	/** Format mask */
	FIO_SO_IFMT			= 0x0038,		// Format mask
	/** Symlink */
	FIO_SO_IFLNK		= 0x0008,		// Symbolic link
	/** Directory */
	FIO_SO_IFDIR		= 0x0010,		// Directory
	/** Regular file */
	FIO_SO_IFREG		= 0x0020,		// Regular file

	/** Hidden read permission */
	FIO_SO_IROTH		= 0x0004,		// read
	/** Hidden write permission */
	FIO_SO_IWOTH		= 0x0002,		// write
	/** Hidden execute permission */
	FIO_SO_IXOTH		= 0x0001,		// execute
}

/*
#define FIO_SO_ISLNK(m)	(((m) & FIO_SO_IFMT) == FIO_SO_IFLNK)
#define FIO_SO_ISREG(m)	(((m) & FIO_SO_IFMT) == FIO_SO_IFREG)
#define FIO_SO_ISDIR(m)	(((m) & FIO_SO_IFMT) == FIO_SO_IFDIR)
*/

/** Structure to hold the status information about a file */
struct SceIoStat {
	SceMode         st_mode;
	uint            st_attr;
	/** Size of the file in bytes. */
	SceOff          st_size;
	/** Creation time. */
	ScePspDateTime  st_ctime;
	/** Access time. */
	ScePspDateTime  st_atime;
	/** Modification time. */
	ScePspDateTime  st_mtime;
	/** Device-specific data. */
	uint            st_private[6];
}

enum : uint {
	PSP_O_RDONLY   = 0x0001,
	PSP_O_WRONLY   = 0x0002,
	PSP_O_RDWR     = (PSP_O_RDONLY | PSP_O_WRONLY),
	PSP_O_NBLOCK   = 0x0004,
	PSP_O_DIROPEN  = 0x0008, // Internal use for dopen
	PSP_O_APPEND   = 0x0100,
	PSP_O_CREAT    = 0x0200,
	PSP_O_TRUNC    = 0x0400,
	PSP_O_EXCL     = 0x0800,
	PSP_O_UNKNOWN1 = 0x4000, // something async?
	PSP_O_NOWAIT   = 0x8000,
	PSP_O_UNKNOWN2 = 0xf0000, // seen on Wipeout Pure and Infected
	PSP_O_UNKNOWN3 = 0x2000000, // seen on Puzzle Guzzle, Hammerin' Hero
}

struct SceIoDirent {
	/** File status. */
	SceIoStat 	d_stat;
	/** File name. */
	char 		d_name[256];
	/** Device-specific data. */
	void * 		d_private;
	int 		dummy;
}

enum : uint { PSP_SEEK_SET, PSP_SEEK_CUR, PSP_SEEK_END }

/** Structure passed to the init and exit functions of the io driver system */
struct PspIoDrvArg {
	/** Pointer to the original driver which was added */
	PspIoDrv* drv;
	/** Pointer to a user defined argument (if written by the driver will preseve across calls */
	void* arg;
}

/** Structure passed to the file functions of the io driver system */
struct PspIoDrvFileArg {
	/** Unknown */
	u32 unk1;
	/** The file system number, e.g. if a file is opened as host5:/myfile.txt this field will be 5 */
	u32 fs_num;
	/** Pointer to the driver structure */
	PspIoDrvArg *drv;
	/** Unknown, again */
	u32 unk2;
	/** Pointer to a user defined argument, this is preserved on a per file basis */
	void *arg;
}

/** Structure to maintain the file driver pointers */
struct PspIoDrvFuncs { extern (C):
	int function(PspIoDrvArg* arg) IoInit;
	int function(PspIoDrvArg* arg) IoExit;

	int function(PspIoDrvFileArg* arg, char* file, int flags, SceMode mode) IoOpen;
	int function(PspIoDrvFileArg* arg) IoClose;
	int function(PspIoDrvFileArg* arg, char* data, int len) IoRead;
	int function(PspIoDrvFileArg* arg, const char* data, int len) IoWrite;
	SceOff function(PspIoDrvFileArg* arg, SceOff ofs, int whence) IoLseek;
	int function(PspIoDrvFileArg* arg, uint cmd, void* indata, int inlen, void* outdata, int outlen) IoIoctl;
	int function(PspIoDrvFileArg* arg, const char* name) IoRemove;
	int function(PspIoDrvFileArg* arg, const char* name, SceMode mode) IoMkdir;
	int function(PspIoDrvFileArg* arg, const char* name) IoRmdir;
	int function(PspIoDrvFileArg* arg, const char* dirname) IoDopen;
	int function(PspIoDrvFileArg* arg) IoDclose;
	int function(PspIoDrvFileArg* arg, SceIoDirent* dir) IoDread;
	int function(PspIoDrvFileArg* arg, const char* file, SceIoStat* stat) IoGetstat;
	int function(PspIoDrvFileArg* arg, const char* file, SceIoStat* stat, int bits) IoChstat;
	int function(PspIoDrvFileArg* arg, const char* oldname, const char* newname) IoRename;
	int function(PspIoDrvFileArg* arg, const char* dir) IoChdir;
	int function(PspIoDrvFileArg* arg) IoMount;
	int function(PspIoDrvFileArg* arg) IoUmount;
	int function(PspIoDrvFileArg* arg, const char* devname, uint cmd, void* indata, int inlen, void* outdata, int outlen) IoDevctl;
	int function(PspIoDrvFileArg* arg) IoUnk21;
}

struct PspIoDrv {
	/** The name of the device to add */
	const char* name;
	/** Device type, this 0x10 is for a filesystem driver */
	u32 dev_type;
	/** Unknown, set to 0x800 */
	u32 unk2;
	/** This seems to be the same as name but capitalised :/ */
	const char* name2;
	/** Pointer to a filled out functions table */
	PspIoDrvFuncs* funcs;
}

static this() {
	mixin(Module.registerModule("IoFileMgrForUser"));
	mixin(Module.registerModule("IoFileMgrForKernel"));
}