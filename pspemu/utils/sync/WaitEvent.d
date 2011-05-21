module pspemu.utils.sync.WaitEvent;

public import pspemu.utils.sync.WaitObject;

extern (System) {
	HANDLE CreateEventA(LPSECURITY_ATTRIBUTES lpEventAttributes, BOOL bManualReset, BOOL bInitialState, LPCTSTR lpName);
	void SetEvent(HANDLE event);
}

class WaitEvent : WaitObject {
	this(string name = null, bool initiallySignaled = false) {
		this.name = name;
		this.handle = CreateEventA(null, false, initiallySignaled, toStringz(name));
	}

	public void signal() {
		SetEvent(handle);
	}
}