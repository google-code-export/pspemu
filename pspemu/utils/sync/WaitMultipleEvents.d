module pspemu.utils.sync.WaitMultipleEvents;

import pspemu.utils.sync.WaitEvent;

import core.thread;

class WaitMultipleEvents {
	WaitEvent[] events;
	public Object object;
	
	public void add(WaitEvent event) {
		this.events ~= event;
	}
	
	public WaitEvent waitAny(uint timeoutMilliseconds = uint.max) {
		if (events.length) {
			scope handles = new HANDLE[events.length]; 
			foreach (k, event; events) handles[k] = event.handle;
			uint result;
			switch (result = WaitForMultipleObjects(handles.length, handles.ptr, false, timeoutMilliseconds)) {
				case WAIT_ABANDONED:
				break;
				case WAIT_TIMEOUT:
				break;
				case WAIT_FAILED:
				break;
				default:
					WaitEvent event = events[result - WAIT_OBJECT_0];
					event.callCallback(object);
					return event;
				break;
			}
		} else {
			if (timeoutMilliseconds == uint.max) {
				Thread.sleep(long.max);
			} else {
				Thread.sleep(timeoutMilliseconds);
			}
		}
		return null;
	}
}