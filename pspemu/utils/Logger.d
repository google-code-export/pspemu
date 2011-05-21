module pspemu.utils.Logger;

import std.string;
import std.format;
import std.stdio;
import std.conv;

class Logger {
	enum Level : ubyte { TRACE, DEBUG, INFO, WARNING, ERROR, CRITICAL, NONE }

	struct Message {
		uint   time;
		Level  level;
		string component;
		string text;
		void print() {
			.writefln("%-8s: %-10d: '%s'::'%s'", to!string(level), time, component, text);
		}
	}

	//__gshared Message[] messages;
	__gshared Level currentLogLevel = Level.NONE;
	
	static public void setLevel(Level level) {
		currentLogLevel = level;
	}

	static void log(T...)(Level level, string component, T args) {
		if (level == Level.NONE) return;

		//std.string.format
	
		if (level >= currentLogLevel) {
			auto message = Message(std.c.time.time(null), level, component, std.string.format(args));
			//messages ~= message;
			if (component == "sceAudio_driver") return;
			if (component == "sceAudio") return;
			if (component == "IoFileMgrForUser") return;
			if (component == "ThreadManForUser") return;
			if (component == "sceHprm") return;
			if (component == "sceCtrl") return;
			//if (component == "Module") return;
			message.print();
		}
	}
}