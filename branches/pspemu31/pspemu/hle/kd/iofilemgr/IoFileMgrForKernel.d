module pspemu.hle.kd.iofilemgr.IoFileMgrForKernel; // kd/iofilemgr.prx (sceIOFileManager)

//debug = DEBUG_SYSCALL;

import std.stdio;

import std.datetime;
import std.stream;
import std.file;
import std.string;
import std.conv;

//import pspemu.core.cpu.Interrupts;

import pspemu.hle.ModuleNative;

import pspemu.utils.Utils;
import pspemu.utils.Path;
import pspemu.utils.Logger;
import pspemu.utils.VirtualFileSystem;

import pspemu.hle.kd.iofilemgr.Types;
import pspemu.hle.kd.iofilemgr.Devices;

import pspemu.Emulator;

class IoFileMgrForKernel : ModuleNative {
	VFS fsroot() {
		return hleEmulatorState.rootFileSystem.fsroot;
	}

	void initModule() {
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
		mixin(registerd!(0x35DBD746, sceIoWaitAsyncCB));
	}

	/*
	Stream[SceUID] openedStreams;

	Stream getStreamFromFD(SceUID uid) {
		if ((uid in openedStreams) is null) {
			throw(new Exception(std.string.format("No file opened with FD/UID(%d)", uid)));
			//Logger.log(Logger.Level.WARNING, "iofilemgr", "No file opened with FD/UID(%d)", uid);
		}
		return openedStreams[uid];
	}
	*/

	/**
	 * Make a directory file
	 *
	 * @param path -
	 * @param mode - Access mode.
	 *
	 * @return Returns the value 0 if its succesful otherwise -1
	 */
	int sceIoMkdir(string path, SceMode mode) {
		logInfo("sceIoMkdir('%s, %d)", path, mode);
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
	 *
	 * @return Returns the value 0 if its succesful otherwise -1
	 */
	int sceIoRmdir(string path) {
		logInfo("sceIoRmdir('%s)", path);
		unimplemented();
		return -1;
	}

	/**
	 * Change the name of a file
	 *
	 * @param oldname - The old filename
	 * @param newname - The new filename
	 *
	 * @return < 0 on error.
	 */
	int sceIoRename(string oldname, string newname) {
		logInfo("sceIoRename('%s', '%s')", oldname, newname);
		unimplemented();
		return -1;
	}

	class DirectoryIterator {
		string dirname;
		uint pos;
		VFS vfs;
		VFS[] children;
		this(string dirname) {
			this.dirname = dirname;
			this.pos = 0;
			this.vfs = fsroot[dirname];
			foreach (child; this.vfs) children ~= child;
		}
		uint left() { return children.length - pos; }
		VFS extract() {
			return children[pos++];
		}
	}

	DirectoryIterator[SceUID] openedDirectories;

	/**
	 * Open a directory
	 * 
	 * @par Example:
	 * <code>
	 *     int dfd;
	 *     dfd = sceIoDopen("device:/");
	 *     if (dfd >= 0) { Do something with the file descriptor }
	 * </code>
	 *
	 * @param dirname - The directory to open for reading.
	 *
	 * @return If >= 0 then a valid file descriptor, otherwise a Sony error code.
	 */
	SceUID sceIoDopen(string dirname) {
		logInfo("sceIoDopen('%s')", dirname);
		try {
			SceUID uid = openedDirectories.length + 1;
			openedDirectories[uid] = new DirectoryIterator(dirname);
			return uid;
		} catch (Throwable o) {
			.writefln("sceIoDopen: %s", o);
			return -1;
		}
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
		logInfo("sceIoDread('%d')", fd);
		if (fd !in openedDirectories) return -1;
		auto cdir = openedDirectories[fd];
		uint lastLeft = cdir.left;
		if (lastLeft) {
			auto entry = cdir.extract;

			fillStats(&dir.d_stat, entry.stats);
			putStringz(dir.d_name, entry.name);
			dir.d_private = null;
			dir.dummy = 0;
			//writefln(""); writefln("sceIoDread:'%s':'%s'", entry.name, dir.d_name[0]);
		}
		return lastLeft;
	}

	/**
	 * Close an opened directory file descriptor
	 *
	 * @param fd - Already opened file descriptor (using sceIoDopen)
	 *
	 * @return < 0 on error
	 */
	int sceIoDclose(SceUID fd) {
		logInfo("sceIoDclose('%d')", fd);
		if (fd !in openedDirectories) return -1;
		openedDirectories.remove(fd);
		return 0;
	}

	/**
	 * Change the current directory.
	 *
	 * @param path - The path to change to.
	 *
	 * @return < 0 on error.
	 */
	int sceIoChdir(string path) {
		logInfo("sceIoChdir('%s')", path);
		try {
			fsroot.access(path);
			hleEmulatorState.rootFileSystem.fscurdir = path;
			return 0;
		} catch (Throwable o) {
			.writefln("sceIoChdir: %s", o);
			return -1;
		}
	}

	/** 
	 * Send a devctl command to a device.
	 *
	 * @par Example: Sending a simple command to a device (not a real devctl)
	 * <code>
	 *     sceIoDevctl("ms0:", 0x200000, indata, 4, NULL, NULL); 
	 * </code>
	 *
	 * @param dev     - String for the device to send the devctl to (e.g. "ms0:")
	 * @param cmd     - The command to send to the device
	 * @param indata  - A data block to send to the device, if NULL sends no data
	 * @param inlen   - Length of indata, if 0 sends no data
	 * @param outdata - A data block to receive the result of a command, if NULL receives no data
	 * @param outlen  - Length of outdata, if 0 receives no data
	 *
	 * @return 0 on success, < 0 on error
	 */
	int sceIoDevctl(string dev, int cmd, void* indata, int inlen, void* outdata, int outlen) {
		logInfo("sceIoDevctl('%s', %d)", dev, cmd);
		try {
			return hleEmulatorState.rootFileSystem.devices[dev].sceIoDevctl(cmd, (cast(ubyte*)indata)[0..inlen], (cast(ubyte*)outdata)[0..outlen]);
		} catch (Exception e) {
			writefln("sceIoDevctl: %s", e);
			return -1;
		}
	}

	/**
	 * Delete a descriptor
	 *
	 * <code>
	 *     sceIoClose(fd);
	 * </code>
	 *
	 * @param fd - File descriptor to close
	 * @return < 0 on error
	 */
	int sceIoClose(SceUID fd) {
		logInfo("sceIoClose('%d')", fd);
		if (fd < 0) return -1;
		try {
			auto stream = hleEmulatorState.uniqueIdFactory.get!Stream(fd);
			hleEmulatorState.uniqueIdFactory.remove!Stream(fd);
			stream.flush();
			stream.close();
			return 0;
		} catch (Throwable o) {
			.writefln("sceIoClose(%d) : %s", fd, o);
			return -1;
		}
	}
	
	string getAbsolutePathFromRelative(string relativePath) {
		auto indexHasDevice = relativePath.indexOf(":/");
		if (indexHasDevice >= 0) {
			return relativePath;
		} else {
			throw(new Exception("Not supporting relative paths"));
		}
	}

	VFS locateParentAndUpdateFile(ref string file) {
		VFS vfs;
		auto indexLastSeparator = file.lastIndexOf("/");
		if (indexLastSeparator >= 0) {
			auto path = getAbsolutePathFromRelative(file);
			path = file[0..indexLastSeparator];
			file = file[indexLastSeparator + 1..$];
			vfs = fsroot.access(path);
		} else {
			writefln(" :: %s", hleEmulatorState.rootFileSystem.fscurdir);
			writefln(" :: %s", fsroot);
			vfs = fsroot.access(hleEmulatorState.rootFileSystem.fscurdir);
		}
		
		//writefln("locateParentAndUpdateFile('%s', '%s')", vfs, file);

		return vfs;
	}

	/**
	 * Open or create a file for reading or writing
	 *
	 * @par Example1: Open a file for reading
	 * <code>
	 * if(!(fd = sceIoOpen("device:/path/to/file", O_RDONLY, 0777)) {
	 *	// error
	 * }
	 * </code>
	 * @par Example2: Open a file for writing, creating it if it doesnt exist
	 * <code>
	 * if(!(fd = sceIoOpen("device:/path/to/file", O_WRONLY|O_CREAT, 0777)) {
	 *	// error
	 * }
	 * </code>
	 *
	 * @param file  - Pointer to a string holding the name of the file to open
	 * @param flags - Libc styled flags that are or'ed together
	 * @param mode  - File access mode.
	 *
	 * @return A non-negative integer is a valid fd, anything else is an error
	 */
	SceUID sceIoOpen(/*const*/ string file, int flags, SceMode mode) {
		VFS vfs;
		FileMode fmode;
		try {
			if (flags & PSP_O_RDONLY) fmode |= FileMode.In;
			if (flags & PSP_O_WRONLY) fmode |= FileMode.Out;
			if (flags & PSP_O_APPEND) fmode |= FileMode.Append;
			if (flags & PSP_O_CREAT ) fmode |= FileMode.OutNew;
			
			//.writefln("Open: Flags:%08X, Mode:%03o, File:'%s'", flags, mode, file);
			
			vfs = locateParentAndUpdateFile(file);
			logInfo("sceIoOpen('%s':'%s', %d, %d)", file, vfs.full_name, flags, mode);
			//.writefln("%d", fmode);
			return hleEmulatorState.uniqueIdFactory.add(vfs.open(file, fmode, mode));
		} catch (Throwable o) {
			logInfo("sceIoOpen failed to open '%s' for '%d' : '%s'", file, fmode, o);
			return -1;
		}
	}

	/**
	 * Read input
	 *
	 * @par Example:
	 * <code>
	 *     bytes_read = sceIoRead(fd, data, 100);
	 * </code>
	 *
	 * @param fd   - Opened file descriptor to read from
	 * @param data - Pointer to the buffer where the read data will be placed
	 * @param size - Size of the read in bytes
	 * 
	 * @return The number of bytes read
	 */
	int sceIoRead(SceUID fd, void* data, SceSize size) {
		logInfo("sceIoRead(%d, %d)", fd, size);
		if (fd < 0) return -1;
		if (data is null) return -1;
		auto stream = hleEmulatorState.uniqueIdFactory.get!Stream(fd);
		try {
			return stream.read((cast(ubyte *)data)[0..size]);
		} catch (Throwable o) {
			throw(o);
			return -1;
		}
	}

	/**
	 * Write output
	 *
	 * @par Example:
	 * <code>
	 *     bytes_written = sceIoWrite(fd, data, 100);
	 * </code>
	 *
	 * @param fd   - Opened file descriptor to write to
	 * @param data - Pointer to the data to write
	 * @param size - Size of data to write
	 *
	 * @return The number of bytes written
	 */
	int sceIoWrite(SceUID fd, /*const*/ void* data, SceSize size) {
		logInfo("sceIoWrite(%d, %d)", fd, size);
		if (fd < 0) return -1;
		if (data is null) return -1;
		auto stream = hleEmulatorState.uniqueIdFactory.get!Stream(fd);

		// Less than 256 MB.
		if (stream.position >= 256 * 1024 * 1024) {
			throw(new Exception(std.string.format("Write position over 256MB! There was a prolem with sceIoWrite: position(%d)", stream.position)));
		}

		try {
			return stream.write((cast(ubyte *)data)[0..size]);
		} catch (Throwable o) {
			Logger.log(Logger.Level.WARNING, "IoFileMgrForKernel", "sceIoWrite.ERROR :: %s", o);
			return -1;
		}
	}

	/**
	 * Reposition read/write file descriptor offset
	 *
	 * @par Example:
	 * <code>
	 *     pos = sceIoLseek(fd, -10, SEEK_END);
	 * </code>
	 *
	 * @param fd     - Opened file descriptor with which to seek
	 * @param offset - Relative offset from the start position given by whence
	 * @param whence - Set to SEEK_SET to seek from the start of the file, SEEK_CUR
	 *                 seek from the current position and SEEK_END to seek from the end.
	 *
	 * @return The position in the file after the seek. 
	 */
	SceOff sceIoLseek(SceUID fd, SceOff offset, int whence) {
		logInfo("sceIoLseek(%d, %d, %d)", fd, offset, whence);
		if (fd < 0) return -1;
		auto stream = hleEmulatorState.uniqueIdFactory.get!Stream(fd);
		stream.seek(offset, cast(SeekPos)whence);
		return stream.position;
	}

	/**
	 * Reposition read/write file descriptor offset (32bit mode)
	 *
	 * @par Example:
	 * <code>
	 *     pos = sceIoLseek32(fd, -10, SEEK_END);
	 * </code>
	 *
	 * @param fd     - Opened file descriptor with which to seek
	 * @param offset - Relative offset from the start position given by whence
	 * @param whence - Set to SEEK_SET to seek from the start of the file, SEEK_CUR
	 *                 seek from the current position and SEEK_END to seek from the end.
	 *
	 * @return The position in the file after the seek. 
	 */
	int sceIoLseek32(SceUID fd, int offset, int whence) {
		logInfo("sceIoLseek32(%d, %d, %d)", fd, offset, whence);
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
		logInfo("sceIoGetstat('%s')", file);
		string fileIni = file;
		try {
			auto vfs = locateParentAndUpdateFile(file);
			vfs.flush();
			auto fentry = vfs[file];
			
			fillStats(stat, fentry.stats);
			return 0;
		} catch (Throwable e) {
			Logger.log(Logger.Level.DEBUG, "IoFileMgrForKernel", "ERROR: STAT(%s)!! FAILED: %s", fileIni, e);
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
	 *
	 * @return < 0 on error
	 */
	int sceIoRemove(string file) {
		unimplemented_notice();
		return 0;
	}

	/**
	 * Open or create a file for reading or writing (asynchronous)
	 *
	 * @param file  - Pointer to a string holding the name of the file to open
	 * @param flags - Libc styled flags that are or'ed together
	 * @param mode  - File access mode.
	 *
	 * @return A non-negative integer is a valid fd, anything else an error
	 */
	SceUID sceIoOpenAsync(string file, int flags, SceMode mode) {
		unimplemented();
		return -1;
	}

	/**
	 * Reposition read/write file descriptor offset (asynchronous)
	 *
	 * @param fd     - Opened file descriptor with which to seek
	 * @param offset - Relative offset from the start position given by whence
	 * @param whence - Set to SEEK_SET to seek from the start of the file, SEEK_CUR
	 *                 seek from the current position and SEEK_END to seek from the end.
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
	
	int sceIoWaitAsyncCB(SceUID fd, SceInt64* res) {
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
	 * @param file  - The new file to open.
	 * @param flags - The open flags.
	 * @param mode  - The open mode.
	 * @param fd    - The old filedescriptor to reopen
	 *
	 * @return < 0 on error, otherwise the reopened fd.
	 */
	int sceIoReopen(string file, int flags, SceMode mode, SceUID fd) {
		Logger.log(Logger.Level.WARNING, "IoFileMgrForKernel", "Not implemented sceIoReopen");
		Logger.log(Logger.Level.INFO, "IoFileMgrForKernel", "sceIoReopen('%s', %d, %d, %d)", file, flags, mode, cast(int)fd);
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
		string name  = to!string(cast(char *)currentCpuThread().memory.getPointer(cast(uint)drv.name));
		string name2 = to!string(cast(char *)currentCpuThread().memory.getPointer(cast(uint)drv.name2));
		Logger.log(Logger.Level.WARNING, "IoFileMgrForKernel", "sceIoAddDrv('%s', '%s', ...)", name, name2);
		return 0;
	}

	/**
	 * Deletes a IO driver from the system.
	 * @note This is only exported in the kernel version of IoFileMgr
	 *
	 * @param drv_name - Name of the driver to delete.
	 * @return < 0 on error
	 */
	int sceIoDelDrv(string drv_name) {
		Logger.log(Logger.Level.WARNING, "IoFileMgrForKernel", "Not implemented: sceIoDelDrv('%s')", drv_name);
		return 0;
	}
}

void fillStats(SceIoStat* psp_stats, VFS.Stats vfs_stats) {
	{
		psp_stats.st_mode = 0;
		
		// User access rights mask
		psp_stats.st_mode |= IOAccessModes.FIO_S_IRUSR | IOAccessModes.FIO_S_IWUSR | IOAccessModes.FIO_S_IXUSR;
		// Group access rights mask
		psp_stats.st_mode |= IOAccessModes.FIO_S_IRGRP | IOAccessModes.FIO_S_IWGRP | IOAccessModes.FIO_S_IXGRP;
		// Others access rights mask
		psp_stats.st_mode |= IOAccessModes.FIO_S_IROTH | IOAccessModes.FIO_S_IWOTH | IOAccessModes.FIO_S_IXOTH;

		//psp_stats.st_mode |= FIO_S_IFLNK
		psp_stats.st_mode |= vfs_stats.isdir ? IOAccessModes.FIO_S_IFDIR : IOAccessModes.FIO_S_IFREG;
	}
	{
		//psp_stats.st_attr |= IOFileModes.FIO_SO_IFLNK;
		if (vfs_stats.isdir) {
			psp_stats.st_attr = IOFileModes.FIO_SO_IFDIR;
		} else {
			psp_stats.st_attr  = cast(IOFileModes)0;
			psp_stats.st_attr |= IOFileModes.FIO_SO_IFREG;
			psp_stats.st_attr |= IOFileModes.FIO_SO_IROTH | IOFileModes.FIO_SO_IWOTH | IOFileModes.FIO_SO_IXOTH; // rwx
		}
	}
	
	psp_stats.st_size = vfs_stats.size;
	psp_stats.st_ctime.parse(vfs_stats.time_c);
	psp_stats.st_atime.parse(vfs_stats.time_a);
	psp_stats.st_mtime.parse(vfs_stats.time_m);

	psp_stats.st_private[] = 0;
}


static this() {
	mixin(ModuleNative.registerModule("IoFileMgrForKernel"));
}
