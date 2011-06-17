module pspemu.utils.sync.WaitObject;

public import std.conv;
public import std.string;

public import std.c.windows.windows;

abstract class WaitObject {
	public string name;
	public HANDLE handle;
	public void delegate(Object) callback;
	public Object object;
	
	~this() {
		CloseHandle(handle); 
	}
	
	public WaitObject wait(uint timeoutMilliseconds = uint.max) {
		final switch (WaitForSingleObject(handle, timeoutMilliseconds)) {
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
	
	public void callCallback(Object object) {
		if (callback !is null) callback(object);
	}
}