module pspemu.hle.kd.sysmem.KDebugForKernel; // kd/sysmem.prx (sceSystemMemoryManager)

import std.stdio;

import pspemu.hle.ModuleNative;

class KDebugForKernel : ModuleNative {
	void initNids() {
		mixin(registerd!(0x7CEB2C09, sceKernelRegisterKprintfHandler));
		mixin(registerd!(0x84F370BC, Kprintf));
	}

	void sceKernelRegisterKprintfHandler() { unimplemented(); }
	void Kprintf(string format, ...) {
		string outstr = "";
		void output(string s) {
			outstr ~= s;
			//writef("%s", s);
		}
		int parampos = 0;
		bool hasfloat = false;
		//int paramposf = 0;
		current_vparam = 1;
		for (int n = 0; n < format.length; n++) {
			if (format[n] == '%') {
				int longcount = 0;
				int m = n;
				while (++n < format.length) {
					switch (format[n]) {
						case 's':
							output(std.string.format(format[m..n + 1], readparam!(string)));
							goto endwhile;
						break;
						case 'u', 'x', 'X':
							if (longcount >= 2) {
								output(std.string.format(format[m..n + 1], readparam!(ulong)));
							} else {
								output(std.string.format(format[m..n + 1], readparam!(uint)));
							}
							goto endwhile;
						break;
						case 'd':
							if (longcount >= 2) {
								output(std.string.format(format[m..n + 1], readparam!(long)));
							} else {
								output(std.string.format(format[m..n + 1], readparam!(int)));
							}
							goto endwhile;
						break;
						case 'f': {
							//if (longcount >= 2) {
							if (true) {
								output(std.string.format(format[m..n + 1], readparam!(double))); 
							} else {
								output(std.string.format(format[m..n + 1], readparam!(float))); 
							}
							goto endwhile;
						} break;
						case 'l':
							longcount++;
						break;
						default:
						break;
					}
				}
				endwhile:;
			} else {
				output(format[n..n + 1]);
			}
		}
		writef("%s", outstr);
		//unimplemented();
	}
}

static this() {
	mixin(ModuleNative.registerModule("KDebugForKernel"));
}
