module pspemu.hle.vfs.MountableVirtualFileSystem;

import std.stdio;
import std.string;

public import pspemu.hle.vfs.VirtualFileSystem;
public import pspemu.hle.vfs.ProxyVirtualFileSystem;

class MountableVirtualFileSystem : ProxyVirtualFileSystem {
	protected VirtualFileSystem[string] mounts;
	
	this(VirtualFileSystem parentVirtualFileSystem) {
		super(parentVirtualFileSystem);
	}
	
	void mount(string path, VirtualFileSystem virtualFileSystemToMount) {
		mounts[path] = virtualFileSystemToMount;
	}

	void umount(string path) {
		mounts.remove(path);
	}
	
	VirtualFileSystem rewriteFileSystemAndPath(VirtualFileSystem virtualFileSystem, ref string path) {
		foreach (mountName, mountedVirtualFileSystem; mounts) {
			//if (path.)
			if (std.string.indexOf(path, mountName) == 0) {
				writefln("%s", path);
				path = path[mountName.length..$];
				writefln("%s", path);
				return mountedVirtualFileSystem;
			}
		}
		path = path;
		return virtualFileSystem;
	}
	
	FileEntry rewriteFileEntry(FileEntry fileEntry) {
		//fileEntry.name = 
		return fileEntry;
	}
}