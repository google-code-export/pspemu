module pspemu.utils.Logger;

import std.string;
import std.format;
import std.stdio;
import std.conv;

class Logger {
	enum Level : ubyte { TRACE, DEBUG, INFO, WARNING, ERROR, CRITICAL }

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
	__gshared static Level currentLogLevel = Level.INFO;

	/*
	static void log(Level level, string component, string text)() {
		wstring text;
		void put(dchar c) { text ~= c; }
		std.format.doFormat(&put, _arguments, _argptr);
		auto message = Message(std.c.time.time(null), level, component, text);
		messages ~= message;
		//if (level >= Level.WARNING) {
		if (level >= Level.INFO) {
		//if (level >= Level.DEBUG) {
			message.print();
		}
	}
	*/
	
	static void log(T...)(Level level, string component, T args) {
		if (level >= currentLogLevel) {
			auto message = Message(std.c.time.time(null), level, component, std.string.format(args));
			messages ~= message;
			message.print();
		}
	}
}