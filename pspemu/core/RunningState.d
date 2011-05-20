module pspemu.core.RunningState;

import pspemu.utils.Event;
import pspemu.utils.Logger;

class RunningState {
	public bool running = true;
	Event onStop;
	
	this() {
		
	}

	public void stop() {
		Logger.log(Logger.Level.INFO, "RunningState.stop");
		onStop();
		running = false;
	}
}