module pspemu.utils.UniqueIdFactory;

alias uint UID;

class UniqueIdFactory {
	UniqueIdTypeFactory[string] factoryPerType;
	
	public UID add(string type, Object value) {
		if ((type in factoryPerType) is null) factoryPerType[type] = new UniqueIdTypeFactory(type);
		return factoryPerType[type].newUid(value);
	}
	
	public T get(T)(string type, UID uid) {
		return factoryPerType[type].get!(T)(uid);
	}
}

class UniqueIdTypeFactory {
	string type;
	uint last = 0;
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
}