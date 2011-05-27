module pspemu.utils.sync.WaitMultipleObjects;

import pspemu.utils.sync.WaitObject;

import core.thread;

class WaitMultipleObjects {
	WaitObject[] waitObjects;
	public Object object;
	
	this(Object object = null) {
		this.object = object;
	}
	
	public void add(WaitObject waitObject) {
		this.waitObjects ~= waitObject;
	}
	
	public WaitObject waitAny(uint timeoutMilliseconds = uint.max) {
		if (waitObjects.length) {
			scope handles = new HANDLE[this.waitObjects .length]; 
			foreach (index, waitObject; waitObjects) handles[index] = waitObject.handle;
			uint result;
			switch (result = WaitForMultipleObjects(handles.length, handles.ptr, false, timeoutMilliseconds)) {
				case WAIT_ABANDONED:
				break;
				case WAIT_TIMEOUT:
				break;
				case WAIT_FAILED:
				break;
				default:
					WaitObject waitObject = this.waitObjects[result - WAIT_OBJECT_0];
					waitObject.callCallback(object);
					return waitObject;
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