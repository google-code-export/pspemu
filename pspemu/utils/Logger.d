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

	__gshared static Message[] messages;
	//__gshared static Level currentLogLevel = Level.INFO;
	//__gshared static Level currentLogLevel = Level.TRACE;
	__gshared static Level currentLogLevel = Level.NONE;

	static void log(T...)(Level level, string component, T args) {
		if (level == Level.NONE) return;
		
		if (level >= currentLogLevel) {
			auto message = Message(std.c.time.time(null), level, component, std.string.format(args));
			messages ~= message;
			if (component == "sceAudio_driver") return;
			//if (component == "Module") return;
			message.print();
		}
	}
}