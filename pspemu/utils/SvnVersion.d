module pspemu.utils.SvnVersion;

import std.string;
import std.array;
import std.xml;
import std.conv;
import pspemu.utils.net.SimpleHttp;
import std.regex;

class SvnVersion {
	__gshared string svnversionString = import("svn_version.txt");

	static int revision() {
		string[] parts = std.string.split(svnversionString, ":");
		string part = parts[$ - 1];
		part = replace(part, "M", "");
		part = replace(part, "S", "");
		part = replace(part, "P", "");
		return to!int(part);
	}
	
	static int getLastOnlineVersion() {
		auto data = SimpleHttp.downloadFile("http://code.google.com/p/pspemu/");
		auto m = match(cast(char[])data, regex("Current version is <a href=\"(.*)\">r(\\d+)</a>"));
		return to!int(m.captures[2]);
	}

	
	/*
	__gshared string xmlString = import("svn_info.xml");
	__gshared std.xml.Document xmlDocument; 
	
	static this() {
		xmlDocument = new Document(xmlString);
	}
	
	static int revision() {
		return to!int(xmlDocument.elements[0].tag.attr["revision"]);
	}
	*/
}