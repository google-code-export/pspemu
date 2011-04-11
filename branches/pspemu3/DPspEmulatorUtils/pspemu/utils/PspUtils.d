module pspemu.utils.PspUtils;

private import core.thread;

private import pspemu.utils.Utils;

enum RunningState {
	RUNNING = 0,
	PAUSED  = 1,
	STOPPED = 2,
}

class HaltException : Exception { this(string type = "HALT") { super(type); } }

abstract class PspHardwareComponent {
	Thread thread;
	RunningState runningState = RunningState.STOPPED;
	bool componentInitialized = false;

	void start() {
		if ((thread !is null) && thread.isRunning) return;

		componentInitialized = false;
		runningState = RunningState.RUNNING;
		thread = new Thread(&run);
		thread.start();
		waitStart();
	}
	
	abstract void run();

	/**
	 * Pauses emulation.
	 */
	void pause() {
		runningState = RunningState.PAUSED;
	}

	/**
	 * Resumes emulation.
	 */
	void resume() {
		runningState = RunningState.RUNNING;
	}

	/**
	 * Stops emulation.
	 */
	void stop() {
		runningState = RunningState.STOPPED;
	}

	void stopAndWait() {
		stop();
		while (running) sleep(1);
	}

	void init() {
	}

	void reset() {
	}

	bool running() {
		return (runningState == RunningState.RUNNING) && (thread && thread.isRunning);
	}

	void waitStart() {
		InfiniteLoop!(1024) loop;
		while (!componentInitialized && (runningState == RunningState.RUNNING)) {
			loop.increment();
			sleep(1);
		}
	}

	void waitUntilResume() {
		while (runningState != RunningState.RUNNING) {
			if (runningState == RunningState.STOPPED) throw(new HaltException("RunningState.STOPPED"));
			sleep(1);
		}
	}

	void waitEnd() {
		while (runningState == RunningState.RUNNING) {
			sleep(1);
		}
	}
}
