module pspemu.hle.kd.iofilemgr.FilesAsync;

import std.stream;

import pspemu.utils.AsyncStream;

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
		mixin(registerd!(0x35DBD746, sceIoWaitAsyncCB));
		mixin(registerd!(0x3251EA56, sceIoPollAsync));
		mixin(registerd!(0x0FACAB19, sceIoWriteAsync));
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
		logWarning("sceIoOpenAsync('%s':%d, %d, %d)", file, file !is null, flags, mode);
		if (file == "") {
			return hleEmulatorState.uniqueIdFactory.add(new AsyncStream(new MemoryStream()));
		}
		try {
			SceUID ret = hleEmulatorState.uniqueIdFactory.add(_open(file, flags, mode));
			logInfo("sceIoOpenAsync():%d", ret);
			return ret;
		} catch (Throwable o) {
			logError("Error: %s", o);
			return -1;
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
			logError("sceIoCloseAsync(%d)", fd);
			auto asyncStream = hleEmulatorState.uniqueIdFactory.get!AsyncStream(fd);
			hleEmulatorState.uniqueIdFactory.remove!AsyncStream(fd);
			asyncStream.stream.flush();
			asyncStream.stream.close();
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
	int sceIoReadAsync(SceUID fd, ubyte *data, SceSize size) {
		logInfo("sceIoReadAsync(%d, %s, %d)", fd, data, size);
		if (fd < 0) return -1;
		if (data is null) return -1;
		//writefln("[1]");
		auto asyncStream = hleEmulatorState.uniqueIdFactory.get!AsyncStream(fd);
		//writefln("[2]");
		try {
			//writefln("[3]");
			asyncStream.lastOperation = asyncStream.stream.read(data[0..size]);
			//writefln("[4]");
		} catch (Throwable o) {
			logError("sceIoReadAsync %s", o);
			return -1;
		}
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
	
	int _sceIoWaitAsyncCB(SceUID fd, SceInt64* res, bool callbacks) {
		AsyncStream asyncStream = hleEmulatorState.uniqueIdFactory.get!AsyncStream(fd);
		*res = asyncStream.lastOperation;
		return 0;
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
		return _sceIoWaitAsyncCB(fd, res, false);
	}
	
	int sceIoWaitAsyncCB(SceUID fd, SceInt64* res) {
		return _sceIoWaitAsyncCB(fd, res, true);
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
		try {
			AsyncStream asyncStream = hleEmulatorState.uniqueIdFactory.get!AsyncStream(fd);
			*res = asyncStream.lastOperation;
			//unimplemented();
			return 0;
		} catch (Throwable o) {
			logWarning("sceIoPollAsync: %s", o);
			return 0;
		}
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