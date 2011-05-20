module pspemu.utils.UniqueIdFactory;

alias uint UID;

class UniqueIdFactory {
	UniqueIdTypeFactory[string] factoryPerType;
	
	public UID add(T)(T value) {
		if ((T.stringof in factoryPerType) is null) factoryPerType[T.stringof] = new UniqueIdTypeFactory(T.stringof);
		return factoryPerType[T.stringof].newUid(value);
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
	Object[UID] values;
	
	this(string type) {
		this.type = type;
	}

	public UID newUid(Object value) {
		UID current = last++;
		values[current] = value;
		return current;
	}

	public T get(T)(UID uid) {
		return cast(T)values[uid];
	}
	
	public void remove(UID uid) {
		values.remove(uid);
	}
}