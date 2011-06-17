module pspemu.hle.vfs.IsoFileSystem;

import std.stdio;
import std.stream;
import std.string;
import std.array;
import std.datetime;
import std.conv;

import pspemu.utils.Expression;

import pspemu.core.exceptions.NotImplementedException;

public import pspemu.formats.iso.Iso;
public import pspemu.hle.vfs.VirtualFileSystem;

FileStat isoNodeToFileStat(IsoFileSystem isoFileSystem, Iso.IsoNode isoNode) {
	if (isoNode is null) return null;
	FileStat stat = new FileStat(isoFileSystem);
	stat.permissions  = octal!777;
	stat.isDir  = isoNode.isDir;
	stat.isRoot = false;
	stat.size  = isoNode.directoryRecord.size.l;
	stat.ctime = SysTime(isoNode.directoryRecord.date.toDateTime());
	stat.atime = SysTime(isoNode.directoryRecord.date.toDateTime());
	stat.mtime = SysTime(isoNode.directoryRecord.date.toDateTime());
	stat.sectorOffset = isoNode.directoryRecord.extent.l;
	return stat;	
}

FileEntry isoNodeToFileEntry(IsoFileSystem isoFileSystem, Iso.IsoNode isoNode) {
	if (isoNode is null) return null;
	FileEntry fileEntry = new FileEntry(isoFileSystem);
	fileEntry.name = isoNode.name;
	fileEntry.stat = isoNodeToFileStat(isoFileSystem, isoNode);
	return fileEntry;
}

class IsoFileHandle : FileHandle {
	Iso.IsoNode isoNode;
	Stream stream;
	
	public this(VirtualFileSystem virtualFileSystem, Stream stream) {
		super(virtualFileSystem);
		this.stream = stream;
	}
	
	public this(VirtualFileSystem virtualFileSystem, Iso.IsoNode isoNode) {
		super(virtualFileSystem);
		this.isoNode = isoNode;
		this.stream = isoNode.open;
	}
}

class IsoDirHandle : DirHandle {
	Iso.IsoNode isoNode;
	int currentIndex;

	this(VirtualFileSystem virtualFileSystem, Iso.IsoNode isoNode) {
		super(virtualFileSystem);
		this.isoNode = isoNode;
		this.currentIndex = 0;
	}
	
	bool hasMore() {
		return (currentIndex < isoNode.childs.length);
	}
	
	Iso.IsoNode next() {
		if (currentIndex < isoNode.childs.length) {
			return isoNode.childs[currentIndex++];
		} else {
			//return null;
			throw(new Exception("No more entries"));
		}
	}
}

class IsoFileSystem : VirtualFileSystem {
	Iso iso;

	public this(Iso iso) {
		this.iso = iso;
	}
	
	Stream getStreamFromHandle(FileHandle handle) {
		return handle.get!IsoFileHandle(this).stream;
	}
	
	override FileHandle open(string file, FileOpenMode flags, FileAccessMode mode) {
		//writefln("ISO_OPEN: %s", file);
		
		// sce_lbn0x5fa0_size0x1428
		
		if ((file.length >= 4) && (file[0..4] == "sce_")) {
			string[] parts = split(file, "_");
			uint lbn = 0, size = 0;
			foreach (part; parts[1..$]) {
				if (part.length >= 3 && part[0..3] == "lbn") {
					lbn = cast(uint)parseString(part[3..$], 0);
				} else if (part.length >= 4 && part[0..4] == "size") {
					size = cast(uint)parseString(part[4..$], 0);
				}
			}
			ulong start = lbn * Iso.SECTOR_SIZE;
			ulong end   = start + size * Iso.SECTOR_SIZE;
			writefln("%s : %08X, %08X", parts, start, end);
			return new IsoFileHandle(this, new SliceStream(iso.stream, start, end));
		}
		
		return new IsoFileHandle(this, iso.locate(file));
	}
	
	override void close(FileHandle handle) {
		//getStreamFromHandle(handle).close();
	}
	
	override int read(FileHandle handle, ubyte[] data) {
		return getStreamFromHandle(handle).read(data);
	}
	
	override long seek(FileHandle handle, long offset, Whence whence) {
		return getStreamFromHandle(handle).seek(offset, cast(SeekPos)whence);
	}
	
	override DirHandle dopen(string file) {
		return new IsoDirHandle(this, iso.locate(file));
	}

	override void dclose(DirHandle handle) {
	}
	
	override FileEntry dread(DirHandle handle) {
		IsoDirHandle isoDirHandle = cast(IsoDirHandle)handle;
		if (isoDirHandle.hasMore) {
			return isoNodeToFileEntry(this, isoDirHandle.next());
		} else {
			return null;
		}
	}
	
	override FileStat getstat(string file) {
		return isoNodeToFileStat(this, iso.locate(file));
	}
}