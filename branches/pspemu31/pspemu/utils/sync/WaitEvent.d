module pspemu.utils.sync.WaitEvent;

public import std.conv;
public import std.string;

public import std.c.windows.windows;

extern (System) {
	HANDLE CreateEventA(LPSECURITY_ATTRIBUTES lpEventAttributes, BOOL bManualReset, BOOL bInitialState, LPCTSTR lpName);
	void SetEvent(HANDLE event);
}

class WaitEvent {
	public string name;
	public HANDLE handle;
	public void delegate(Object) callback;
	public Object object;
	
	this(string name = null, bool initiallySignaled = false) {
		this.name = name;
		this.handle = CreateEventA(
            null,              // default security attributes
            false,             // auto-reset event object
            initiallySignaled, // initial state is nonsignaled
            toStringz(name)    // name of the event
        );
	}

	~this() {
		CloseHandle(handle); 
	}
	
	public void callCallback(Object object) {
		if (callback !is null) callback(object);
	}
	
	public WaitEvent wait(uint timeoutMilliseconds = uint.max) {
		switch (WaitForSingleObject(handle, timeoutMilliseconds)) {
			case WAIT_ABANDONED:
			break;
			case WAIT_OBJECT_0:
				callCallback(object);
				return this;
			break;
			case WAIT_TIMEOUT:
			break;
			case WAIT_FAILED:
			break;
		}
		return null;
	}
	
	public void signal() {
		SetEvent(handle);
	}
}