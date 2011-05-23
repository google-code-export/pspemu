module pspemu.hle.vfs.VirtualFileSystem;

//import std.stdio;
//import std.stream;
import std.datetime;

import pspemu.core.exceptions.NotImplementedException;

enum FileOpenMode {
	In     = 1,
	Out    = 2,
	OutNew = 4 | 2,
	Append = 8 | 2,
}

enum Whence {
	Set    = 0,
	Cursor = 1,
	End    = 2,
}

class FileStat {
	VirtualFileSystem virtualFileSystem;
	uint mode;
	uint attr;
	ulong size;
	DateTime ctime;
	DateTime atime;
	DateTime mtime;
}

class FileEntry {
	VirtualFileSystem virtualFileSystem;
	FileStat stat;
	string name;
	
	this(VirtualFileSystem virtualFileSystem) {
		this.virtualFileSystem = virtualFileSystem;
	}
}

class FileHandle {
	VirtualFileSystem virtualFileSystem;
	
	this(VirtualFileSystem virtualFileSystem) {
		this.virtualFileSystem = virtualFileSystem;
	}
	
	T get(T = FileHandle)(VirtualFileSystem virtualFileSystem = null) {
		if (virtualFileSystem !is null) {
			if (this.virtualFileSystem != virtualFileSystem) throw(new Exception("Invalid filesystem"));
		}
		return cast(T)this;
	}
}

class DirHandle {
	VirtualFileSystem virtualFileSystem;

	this(VirtualFileSystem virtualFileSystem) {
		this.virtualFileSystem = virtualFileSystem;
	}
}

class VirtualFileSystem {
	void init() {
	}
	
	void exit() {
	}
	
	string getInternalPath(string path) {
		return path;
	}
	
	FileHandle open(string file, int flags, FileOpenMode mode) {
		throw(new NotImplementedException("VirtualFileSystem.open"));
	}
	
	void close(FileHandle handle) {
		throw(new NotImplementedException("VirtualFileSystem.close"));
	}

	int read(FileHandle handle, ubyte[] data) {
		throw(new NotImplementedException("VirtualFileSystem.read"));
	}

	void write(FileHandle handle, ubyte[] data) {
		throw(new NotImplementedException("VirtualFileSystem.write"));
	}

	long seek(FileHandle handle, long offset, Whence whence) {
		throw(new NotImplementedException("VirtualFileSystem.seek"));
	}
	
	void unlink(string file) {
		throw(new NotImplementedException("VirtualFileSystem.unlink"));
	}

	void mkdir(string file) {
		throw(new NotImplementedException("VirtualFileSystem.mkdir"));
	}

	void rmdir(string file) {
		throw(new NotImplementedException("VirtualFileSystem.rmdir"));
	}

	DirHandle dopen(string file) {
		throw(new NotImplementedException("VirtualFileSystem.dopen"));
	}

	void dclose(DirHandle handle) {
		throw(new NotImplementedException("VirtualFileSystem.dclose"));
	}
	
	FileEntry dread(DirHandle handle) {
		throw(new NotImplementedException("VirtualFileSystem.drrad"));
	}
	
	FileStat getstat(string file) {
		throw(new NotImplementedException("VirtualFileSystem.getstat"));
	}

	void setstat(string file, FileStat stat) {
		throw(new NotImplementedException("VirtualFileSystem.getstat"));
	}
	
	void rename(string oldname, string newname) {
		throw(new NotImplementedException("VirtualFileSystem.rename"));
	}

	void ioctl(uint cmd, ubyte[] indata, ubyte[] outdata) {
		throw(new NotImplementedException("VirtualFileSystem.ioctl"));
	}

	void devctl(string devname, uint cmd, ubyte[] indata, ubyte[] outdata) {
		throw(new NotImplementedException("VirtualFileSystem.devctl"));
	}	
}