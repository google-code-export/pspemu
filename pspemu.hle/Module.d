module pspemu.hle.Module;

//public import pspemu.All;
debug = DEBUG_SYSCALL;
//debug = DEBUG_ALL_SYSCALLS;

//debug = DEBUG_MODULE_DELEGATE;

// http://dsource.org/projects/minid/browser/trunk/minid/bind.d
/+
void putStringz(T)(ref T ptr, string s) {
	ptr[0..s.length] = s;
	ptr[s.length] = 0;
}

bool isArrayType(alias T)() { return is(typeof(T[0])) && is(typeof(T.sort)); }
bool isPointerType(alias T)() { return is(typeof(*T)) && !isArrayType!(T); }
bool isArrayType(T)() { return is(typeof(T[0])) && is(typeof(T.sort)); }
bool isPointerType(T)() { static if (is(T == void*)) return true; return is(typeof(*T)) && !isArrayType!(T); }
bool isClassType(T)() { return is(T == class); }
bool isString(T)() { return is(T == string); }
string FunctionName(alias f)() { return (&f).stringof[2 .. $]; }
string FunctionName(T)() { return T.stringof[2 .. $]; }
string stringOf(T)() { return T.stringof; }
static string classInfoBaseName(ClassInfo ci) {
	auto index = ci.name.lastIndexOf('.');
	if (index == -1) index = 0; else index++;
	return ci.name[index..$];
	//return std.string.split(ci.name, ".")[$ - 1];
}

string getModuleMethodDelegate(alias func, uint nid = 0)() {
	string functionName = FunctionName!(func);
	string r = "";
	alias ReturnType!(func) return_type;
	bool return_value = !is(ReturnType!(func) == void);
	string _parametersString() {
		string r = "";
		int paramIndex = 0;
		foreach (param; ParameterTypeTuple!(func)) {
			if (paramIndex > 0) r ~= ", ";
			if (isString!(param)) {
				r ~= "paramsz(" ~ tos(paramIndex) ~ ")";
			} else if (isPointerType!(param)) {
				r ~= "cast(" ~ param.stringof ~ ")param_p(" ~ tos(paramIndex) ~ ")";
			} else if (isClassType!(param)) {
				r ~= "cast(" ~ param.stringof ~ ")param_p(" ~ tos(paramIndex) ~ ")";
				//pragma(msg, "class!");
			} else if (param.sizeof == 8) {
				// TODO. FIXME!
				if (paramIndex % 2) paramIndex++; // PADDING
				r ~= "cast(" ~ param.stringof ~ ")param64(" ~ tos(paramIndex) ~ ")";
				paramIndex++; // extra incremnt
			} else {
				r ~= "cast(" ~ param.stringof ~ ")param(" ~ tos(paramIndex) ~ ")";
			}
			paramIndex++;
		}
		return r;
	}
	string _parametersPrototypeString() {
		string r = "";
		int paramIndex = 0;
		foreach (param; ParameterTypeTuple!(func)) {
			if (paramIndex > 0) r ~= ", ";
			if (isString!(param)) {
				r ~= "\\\"%s\\\"";
			} else {
				r ~= "%s";
			}
			paramIndex++;
		}
		return r;
	}
	r ~= "delegate void() { ";
	{
		r ~= "currentExecutingNid = " ~ tos(nid) ~ ";";
		r ~= "setReturnValue = true;";
		r ~= "current_vparam = 0;";
		string parametersString = _parametersString;
		string parametersPrototypeString = _parametersPrototypeString;
		debug (DEBUG_ALL_SYSCALLS) { } else { r ~= "debug (DEBUG_SYSCALL)"; }
		r ~= "{";
		r ~= ".writef(\"%s; PC=%08X; \", moduleManager.currentThreadName, executionState.registers.PC);";
		debug (DEBUG_ALL_SYSCALLS) {
			r ~= ".writef(\"" ~ functionName ~ "()\"); ";
		} else {
			if (parametersPrototypeString.length) {
				r ~= ".writef(\"" ~ functionName ~ "(" ~ _parametersPrototypeString ~ ")\", " ~ parametersString ~ "); ";
			} else {
				r ~= ".writef(\"" ~ functionName ~ "()\"); ";
			}
		}
		r ~= "}";
		if (return_value) r ~= "auto retval = ";
		r ~= "this." ~ functionName ~ "(" ~ parametersString ~ ");";
		if (return_value) {
			r ~= "if (setReturnValue) {";
			if (isPointerType!(ReturnType!(func))) {
				r ~= "executionState.registers.V0 = executionState.memory.getPointerReverseOrNull(cast(void *)retval);";
			} else {
				r ~= "executionState.registers.V0 = (cast(uint *)&retval)[0];";
				if (ReturnType!(func).sizeof == 8) {
					r ~= "executionState.registers.V1 = (cast(uint *)&retval)[1];";
				}
			}
			r ~= "}";
		}
		debug (DEBUG_ALL_SYSCALLS) { } else { r ~= "debug (DEBUG_SYSCALL)"; }
		r ~= "{";
		if (return_value) {
			if (isPointerType!(ReturnType!(func)) || isClassType!(ReturnType!(func))) {
				r ~= ".writefln(\" = 0x%08X\", executionState.registers.V0); ";
			} else {
				r ~= ".writefln(\" = %s\", retval); ";
			}
		} else {
			r ~= ".writefln(\" = <void>\"); ";
		}
		r ~= "}";
	}
	r ~= " }";
	return r;
}

abstract class Module {
	static struct Function {
		Module pspModule;
		uint nid;
		string name;
		void delegate() func;
		string toString() {
			return std.string.format("0x%08X:'%s.%s'", nid, pspModule.baseName, name);
		}
	}
	alias uint Nid;
	Cpu cpu;
	Function[Nid] nids;
	Function[string] names;
	ModuleManager moduleManager;
	Nid currentExecutingNid;
	bool setReturnValue;
	
	ExecutionState executionState() {
		return ExecutionState.forCurrentThread;
	}

	void avoidAutosetReturnValue() {
		setReturnValue = false;
	}

	// Will avoid obtaining the value from function.
	void returnValue(uint value) {
		executionState.registers.V0 = value;
	}
	
	this() {
		Logger.log(Logger.Level.DEBUG, "Module", "Loading '%s'...", typeid(this));
	}

	final void init() {
		try {
			initNids();
			initModule();
		} catch (Object o) {
			writefln("Error initializing module: '%s'", o);
			throw(o);
		}
	}

	abstract void initNids();
	void initModule() { }
	void shutdownModule() { }
	
	template Parameters() {
		void* vparam_ptr(T)(int n) {
			if (n >= 8) {
				return executionState.memory.getPointer(executionState.registers.SP + (n - 8) * 4);
			} else {
				return &executionState.registers.R[4 + n];
			}
		}
		T vparam_value(T)(int n) {
			static if (is(T == string)) {
				uint v = vparam_value!(uint)(n);
				//writefln("---------%08X(%d)", v, n);
				auto ptr = cast(char*)executionState.memory.getPointer(v);
				return cast(string)ptr[0..std.c.string.strlen(ptr)];
			} else {
				return *cast(T *)vparam_ptr!(T)(n);
			}
		}
		ulong param64(int n) { return vparam_value!(ulong)(n); }
		uint  param  (int n) { return vparam_value!(uint )(n); }
		float paramf (int n) { return vparam_value!(float)(n); }
		
		int current_vparam = 0;
		T readparam(T)(int set = -1) {
			int _align = T.sizeof / 4;
			static if (is(T == string)) _align = 1;
			if (set >= 0) current_vparam = set;
			while (current_vparam % _align) current_vparam++;
			auto ret = vparam_value!(T)(current_vparam);
			current_vparam += _align;
			return ret;
		}
		
		void* param_p(int n) {
			uint v = param(n);
			if (v != 0) {
				try {
					return executionState.memory.getPointer(v);
				} catch (Object o) {
					// @TODO: Reenable?
					throw(o);
					return null;
				}
			} else {
				return null;
			}
		}
		char* paramszp(int n) { return cast(char *)param_p(n); }
		//string paramsz(int n) { auto ptr = paramszp(n); return cast(string)ptr[0..std.c.string.strlen(ptr)]; }
		string paramsz(int n) { return vparam_value!(string)(n); }
	}
	
	template Registration() {
		__gshared static ClassInfo[] registeredModules;

		static string register(uint id, string name) {
			return "names[\"" ~ name ~ "\"] = nids[" ~ tos(id) ~ "] = Function(this, " ~ tos(id) ~ ", \"" ~ name ~ "\", &this." ~ name ~ ");";
		}

		static string registerd(uint id, alias func)() {
			debug (DEBUG_MODULE_DELEGATE) {
				pragma(msg, "{{{{");
				pragma(msg, "");
				pragma(msg, getModuleMethodDelegate!(func)());
				pragma(msg, "");
				pragma(msg, "}}}}");
			}

			return "names[\"" ~ FunctionName!(func) ~ "\"] = nids[" ~ tos(id) ~ "] = Function(this, " ~ tos(id) ~ ", \"" ~ FunctionName!(func) ~ "\", " ~ getModuleMethodDelegate!(func, id) ~ ");";
		}

		static string registerModule(string moduleName) {
			return "Module.registeredModules ~= " ~ moduleName ~ ".classinfo;";
		}

		static string registerModule(TypeInfo_Class moduleClass) {
			//writefln("%s", moduleClass);
			assert(0);
			return "";
		}

		static void dumpRegisteredModules() {
			writefln("RegisteredModules {");
			foreach (_module; registeredModules) {
				writefln("  '%s'", classInfoBaseName(_module));
			}
			writefln("}");
		}

		static ClassInfo getModule(string moduleName) {
			foreach (_module; registeredModules) if (classInfoBaseName(_module) == moduleName) return _module;
			throw(new Exception(std.string.format("Can't find module '%s'", moduleName)));
		}
	}
	
	mixin Parameters;
	mixin Registration;

	Function* getFunctionByName(string functionName) {
		return functionName in names;
	}

	/*void opDispatch(string s)() {
		writefln("Module.opDispatch('%s.%s')", this.baseName, s);
		throw(new Exception(std.string.format("Not implemented %s.%s", this.baseName, s)));
	}*/
	
	string baseName() { return classInfoBaseName(typeid(this)); }
	string toString() { return std.string.format("Module(%s)", baseName); }

	void unimplemented(string file = __FILE__, int line = __LINE__)() {
		throw(new Exception(std.string.format("Unimplemented '%s' at '%s:%d'", onException(nids[currentExecutingNid].name, "<unknown>"), file, line)));
	}
	
	void unimplemented_notice(string file = __FILE__, int line = __LINE__)() {
		writefln("Unimplemented '%s' at '%s:%d'", onException(nids[currentExecutingNid].name, "<unknown>"), file, line);
	}
}
+/