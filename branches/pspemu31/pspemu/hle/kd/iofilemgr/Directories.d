module pspemu.hle.kd.iofilemgr.Directories;

import pspemu.hle.kd.iofilemgr.Types;

import pspemu.utils.Logger;

template IoFileMgrForKernel_Directories() {
	void initModule_Directories() {
	}
	
	void initNids_Directories() {
		mixin(registerd!(0x55F4717D, sceIoChdir));
		mixin(registerd!(0xB29DDF9C, sceIoDopen));
		mixin(registerd!(0xEB092469, sceIoDclose));
		mixin(registerd!(0xE3EB004C, sceIoDread));
		mixin(registerd!(0x06A70004, sceIoMkdir));
		mixin(registerd!(0x1117C65F, sceIoRmdir));
	}
	
	DirectoryIterator[SceUID] openedDirectories;
	
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
}