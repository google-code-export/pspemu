module pspemu.utils.Stack;

struct Stack(T, int maxSize) {
	protected T[maxSize] _values;
	protected uint cursor;
	
	T[] values() {
		return _values[0..cursor];
	}
	
	void push(T value) {
		_values[cursor++] = value;
	}
	
	T pop() {
		return _values[--cursor];		
	}
}