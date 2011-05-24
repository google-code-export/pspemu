module pspemu.utils.UniqueIdFactory;

import std.string;

alias uint UID;

class UniqueIdFactory {
	UniqueIdTypeFactory[string] factoryPerType;
	
	public UID add(T)(T value) {
		if ((T.stringof in factoryPerType) is null) factoryPerType[T.stringof] = new UniqueIdTypeFactory(T.stringof);
		return factoryPerType[T.stringof].newUid(value);
	}

	public UID set(T)(UID uid, T value) {
		if ((T.stringof in factoryPerType) is null) factoryPerType[T.stringof] = new UniqueIdTypeFactory(T.stringof);
		return factoryPerType[T.stringof].set(uid, value);
	}
	
	public T get(T)(UID uid) {
		return factoryPerType[T.stringof].get!(T)(uid);
	}
	
	public void remove(T)(UID uid) {
		factoryPerType[T.stringof].remove(uid);
	}
}

class UniqueIdTypeFactory {
	string type;
	uint last = 1;
	//uint last = 0;
	Object[UID] values;
	
	this(string type) {
		this.type = type;
	}
	
	public UID set(UID uid, Object value) {
		values[uid] = value;
		return uid;
	}

	public UID newUid(Object value) {
		UID current = last++;
		values[current] = value;
		return current;
	}

	public T get(T)(UID uid) {
		if (uid !in values) throw(new Exception(std.string.format("Can't find %s:%d", type, uid)));
		return cast(T)values[uid];
	}
	
	public void remove(UID uid) {
		values.remove(uid);
	}
}