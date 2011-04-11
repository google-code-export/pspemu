module main;

import std.stdio;

class Test {
	void a() {
	}
}

int main(string[] argv)
{
	auto test = new Test();
	test.a();
	
	writeln("Hello D-World!");
	readln();
	
	return 0;
}
