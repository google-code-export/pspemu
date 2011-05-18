module pspemu.utils.Math;

enum : bool { Unsigned, Signed }	
enum Sign : bool { Unsigned, Signed }

// Reinterpret.
// float -> int
int   F_I(float v) { return *cast(int   *)&v; }
// int -> float
float I_F(int   v) { return *cast(float *)&v; }	

T1 reinterpret(T1, T2)(T2 v) { return *cast(T1 *)&v; }

T min(T)(T l, T r) { return (l < r) ? l : r; }
T max(T)(T l, T r) { return (l > r) ? l : r; }

T xabs(T)(T v) { return (v >= 0) ? v : -v; }
T sign(T)(T v) { if (v == 0) return 0; return (v > 0) ? 1 : -1; }

T clamp(T)(T v, T l = 1.0, T r = 1.0) {
	if (v < l) v = l;
	if (v > r) v = r;
	return v;
}
