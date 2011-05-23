module pspemu.hle.vfs.LocalFileSystem;

public import pspemu.hle.vfs.VirtualFileSystem;

import std.string;
import std.array;
import std.stream;

class LocalFileHandle : FileHandle {
	Stream stream;
	
	public this(VirtualFileSystem virtualFileSystem, Stream stream) {
		super(virtualFileSystem);
		this.stream = stream;
	}
}

class LocalDirHandle : DirHandle {
	this(VirtualFileSystem virtualFileSystem) {
		super(virtualFileSystem);
	}
}

class LocalFileSystem : VirtualFileSystem {
	string rootPath;

	this(string rootPath) {
		this.rootPath = rootPath;
	}
	
	FileMode openModeToDMode(FileOpenMode mode) {
		return cast(FileMode)mode;
	}
	
	string getInternalPath(string path) {
		path = std.array.replace(path, r"\", "/");
		string[] parts;
		foreach (part; path.split("/")) {
			if (part == "") continue;
			if (part == ".") continue;
			if (part == "..") {
				if (parts.length) parts.length = parts.length - 1;
				continue;
			}
			parts ~= part;
		}
		return rootPath ~ "/" ~ std.string.join(parts, "/"); 
	}
	
	FileHandle open(string file, int flags, FileOpenMode mode) {
		return new LocalFileHandle(this, new File(getInternalPath(file), openModeToDMode(mode)));
	}
	
	Stream getStreamFromHandle(FileHandle handle) {
		return handle.get!LocalFileHandle(this).stream;
	}

	void close(FileHandle handle) {
		getStreamFromHandle(handle).close();
	}
	
	int read(FileHandle handle, ubyte[] data) {
		return getStreamFromHandle(handle).read(data);
	}

}