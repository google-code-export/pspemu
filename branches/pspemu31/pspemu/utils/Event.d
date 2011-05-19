module pspemu.utils.Event;

struct Event {
	void delegate()[] callbacks;
	
	void opAddAssign(void delegate() callback) {
		callbacks ~= callback;
	}
	
	void opCall() {
		foreach (callback; callbacks) {
			callback();
		}
	}
}