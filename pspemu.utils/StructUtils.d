module pspemu.utils.StructUtils;

ubyte[] TA(T)(ref T v) {
	return cast(ubyte[])((&v)[0..1]);
}
