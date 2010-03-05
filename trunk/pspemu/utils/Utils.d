module pspemu.utils.Utils;

import std.stream, std.stdio;

ubyte[] TA(T)(ref T v) {
	return cast(ubyte[])((&v)[0..1]);
}

T read(T)(Stream stream, long position = -1) {
	T t;
	if (position >= 0) stream = new SliceStream(stream, position, position + (1 << 24));
	stream.read(TA(t));
	return t;
}

T readInplace(T)(ref T t, Stream stream, long position = -1) {
	if (position >= 0) stream.position = position;
	stream.read(TA(t));
	return t;
}

void writeZero(Stream stream, uint count) {
	ubyte[1024] block;
	while (count > 0) {
		int w = min(count, block.length);
		stream.write(block[0..w]);
		count -= w;
	}
}

string readStringz(Stream stream, long position = -1) {
	string s;
	char c;
	if (position >= 0) {
		//writefln("SetPosition:%08X", position);
		stream = new SliceStream(stream, position, position + (1 << 24));
	}
	while (!stream.eof) {
		stream.read(c);
		if (c == 0) break;
		s ~= c;
	} 
	return s;
}

T min(T)(T l, T r) { return (l < r) ? l : r; }
T max(T)(T l, T r) { return (l > r) ? l : r; }

string tos(T)(T v, int base = 10) {
	if (v == 0) return "0";
	const digits = "0123456789abdef";
	assert(base <= digits.length);
	string r;
	bool sign = (v < 0);
	if (sign) v = -v;
	while (v != 0) {
		r = digits[v % base] ~ r;
		v /= base;
	}
	if (sign) r = "-" ~ r;
	return r;
}

unittest {
	assert(tos(100) == "100");
	assert(tos(-99) == "-99");
}