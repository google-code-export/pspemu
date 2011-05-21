module pspemu.core.RunningState;

import pspemu.utils.Event;
import pspemu.utils.Logger;

import pspemu.core.exceptions.HaltException;

public import pspemu.utils.sync.WaitEvent;

class RunningState {
	/**
	 * @deprecated use stopEvent instead.
	 */
	public bool running = true;

	/**
	 * @deprecated use stopEvent instead.
	 */
	Event onStop;
	
	/**
	 * Will trigger when the execution is being stopped.
	 */
	WaitEvent stopEvent;
	
	this() {
		stopEvent = new WaitEvent("stopEvent");
		stopEvent.callback = delegate(Object object) {
			throw(new HaltException("Halt"));
		};
	}
	
	public void reset() {
		this.running = true;
		onStop.reset();
	}

	public void stop() {
		Logger.log(Logger.Level.INFO, "RunningState.stop");
		onStop();
		running = false;
		stopEvent.signal();
	}
}