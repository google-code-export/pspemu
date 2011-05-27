module pspemu.utils.StructUtils;

ubyte[] TA(T)(ref T v) {
	return cast(ubyte[])((&v)[0..1]);
}

void swap(T)(ref T a, ref T b) {
	T t;
	t = a;
	a = b;
	b = t;
}

ushort SwapBytes(ushort v) {
	return cast(ushort)(v >> 8) | cast(ushort)(v << 8);
}