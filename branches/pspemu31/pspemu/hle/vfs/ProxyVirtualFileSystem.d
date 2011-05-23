module pspemu.hle.vfs.ProxyVirtualFileSystem;

public import pspemu.hle.vfs.VirtualFileSystem;

class ProxyVirtualFileSystem : VirtualFileSystem {
	VirtualFileSystem parentVirtualFileSystem;
	
	this(VirtualFileSystem parentVirtualFileSystem) {
		this.parentVirtualFileSystem = parentVirtualFileSystem;
	}
	
	VirtualFileSystem rewriteFileSystemAndPath(VirtualFileSystem virtualFileSystem, ref string path) {
		path = path;
		return virtualFileSystem;
	}
	
	FileStat rewriteReadedFileStat(FileStat fileStat) {
		return fileStat;
	}

	FileStat rewriteFileStatToWrite(FileStat fileStat) {
		return fileStat;
	}
	
	FileHandle open(string file, int flags, FileOpenMode mode) {
		VirtualFileSystem newFileSystem = rewriteFileSystemAndPath(parentVirtualFileSystem, file);
		return newFileSystem.open(file, flags, mode);
	}

	void close(FileHandle handle) {
		handle.virtualFileSystem.close(handle);
	}

	int read(FileHandle handle, ubyte[] data) {
		return handle.virtualFileSystem.read(handle, data);
	}

	void write(FileHandle handle, ubyte[] data) {
		return handle.virtualFileSystem.write(handle, data);
	}

	long seek(FileHandle handle, long offset, Whence whence) {
		return handle.virtualFileSystem.seek(handle, offset, whence);
	}

	void unlink(string file) {
		VirtualFileSystem newFileSystem = rewriteFileSystemAndPath(parentVirtualFileSystem, file);
		newFileSystem.unlink(file);
	}

	void mkdir(string file) {
		VirtualFileSystem newFileSystem = rewriteFileSystemAndPath(parentVirtualFileSystem, file);
		newFileSystem.mkdir(file);
	}

	void rmdir(string file) {
		VirtualFileSystem newFileSystem = rewriteFileSystemAndPath(parentVirtualFileSystem, file);
		newFileSystem.rmdir(file);
	}

	DirHandle dopen(string file) {
		VirtualFileSystem newFileSystem = rewriteFileSystemAndPath(parentVirtualFileSystem, file);
		return newFileSystem.dopen(file);
	}

	void dclose(DirHandle handle) {
		handle.virtualFileSystem.dclose(handle);
	}
	
	FileEntry dread(DirHandle handle) {
		return handle.virtualFileSystem.dread(handle);
	}
	
	FileStat getstat(string file) {
		VirtualFileSystem newFileSystem = rewriteFileSystemAndPath(parentVirtualFileSystem, file);
		return newFileSystem.getstat(file);
	}

	void setstat(string file, FileStat stat) {
		VirtualFileSystem newFileSystem = rewriteFileSystemAndPath(parentVirtualFileSystem, file);
		return newFileSystem.setstat(file, rewriteFileStatToWrite(stat));
	}
	
	void rename(string oldname, string newname) {
		VirtualFileSystem newFileSystem = rewriteFileSystemAndPath(parentVirtualFileSystem, oldname);
		return newFileSystem.rename(oldname, newname);
	}

	void ioctl(uint cmd, ubyte[] indata, ubyte[] outdata) {
		parentVirtualFileSystem.ioctl(cmd, indata, outdata);
	}

	void devctl(string devname, uint cmd, ubyte[] indata, ubyte[] outdata) {
		parentVirtualFileSystem.devctl(devname, cmd, indata, outdata);
	}
}