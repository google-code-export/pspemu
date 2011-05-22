module pspemu.hle.kd.iofilemgr.FilesAsync;

import pspemu.hle.kd.iofilemgr.Types;

import pspemu.utils.Logger;

template IoFileMgrForKernel_FilesAsync() {
	void initModule_FilesAsync() {
	}
	
	void initNids_FilesAsync() {
		mixin(registerd!(0x89AA9906, sceIoOpenAsync));
		mixin(registerd!(0x71B19E77, sceIoLseekAsync));
		mixin(registerd!(0xFF5940B6, sceIoCloseAsync));
		mixin(registerd!(0xA0B5A7C2, sceIoReadAsync));
		mixin(registerd!(0xB293727F, sceIoChangeAsyncPriority));
		mixin(registerd!(0xE23EEC33, sceIoWaitAsync));
		mixin(registerd!(0x3251EA56, sceIoPollAsync));
		mixin(registerd!(0x0FACAB19, sceIoWriteAsync));
		mixin(registerd!(0x35DBD746, sceIoWaitAsyncCB));
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
		try {
			return hleEmulatorState.uniqueIdFactory.add(_open(file, flags, mode));
		} catch (Throwable o) {
			return 0;
		}
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
		try {
			auto stream = hleEmulatorState.uniqueIdFactory.get!Stream(fd);
			hleEmulatorState.uniqueIdFactory.remove!Stream(fd);
			stream.flush();
			stream.close();
			return 0;
		} catch (Throwable o) {
			logError("sceIoCloseAsync: %s", o);
			return -1;
		}
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
		logWarning("Not implemented sceIoReadAsync(%d, %s, %d)", fd, data, size);
		return 0;
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
		logWarning("Not implemented sceIoPollAsync(%d, %s)", fd, res);
		*res = 0;
		//unimplemented();
		return 0;
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
}