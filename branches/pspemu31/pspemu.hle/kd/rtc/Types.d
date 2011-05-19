module pspemu.hle.kd.rtc.Types;

import std.stdio;

import pspemu.hle.kd.Types;
import std.datetime;

// d_time has milliseconds resolution.

alias uint time_t;

alias ScePspDateTime pspTime;

//alias ulong pspTick;

ulong systime_to_tick(SysTime systime) {
	return convert!("hnsecs", "usecs")(systime.stdTime - unixTimeToStdTime(0));
}


SysTime tick_to_systime(ulong ticks) {
	return SysTime(convert!("usecs", "hnsecs")(ticks) + unixTimeToStdTime(0), UTC());
}


/* Date and time. */
struct ScePspDateTime {
	ushort	year;
	ushort 	month;
	ushort 	day;
	ushort 	hour;
	ushort 	minute;
	ushort 	second;
	uint 	microsecond;

	ulong tick() {
		/*
		writefln("%d-%d-%d :: %d:%d:%d.%d", year, month, day, hour, minute, second, microsecond);
		writefln("THIS_DATETIME: %s", SysTime(DateTime(year, month, day, hour, minute, second), UTC()).stdTime);
		writefln("TIMESTAMP(0) : %s", unixTimeToStdTime(0));
		writefln("TICKS        : %s", systime_to_tick(SysTime(DateTime(year, month, day, hour, minute, second), UTC())) + microsecond);
		*/
		
		//if (year == 0 && month == 0 && day == 0 && hour == 0 && minute == 0 && second == 0 && microsecond == 0) return 0;
		return systime_to_tick(SysTime(DateTime(year, month, day, hour, minute, second), UTC())) + microsecond;
	}
	
	bool parse(SysTime systime) {
		year        = cast(ushort)systime.year;
		month       = cast(ushort)systime.month;
		day         = cast(ushort)systime.day;
		hour        = cast(ushort)systime.hour;
		minute      = cast(ushort)systime.minute;
		second      = cast(ushort)systime.second;
		microsecond = cast(uint  )systime.fracSec.usecs;

		return true;
	}

	bool parse(ulong tick) {
		return parse(tick_to_systime(tick));
	}
	
	static assert (this.sizeof == 16);
}
