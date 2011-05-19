module pspemu.utils.Utils;

import std.stream, std.stdio, std.path, std.typecons;

private import std.c.windows.windows;
private import std.windows.syserror;

public import pspemu.utils.String;

private import core.thread;

// Signed?
enum : bool { Unsigned, Signed }	
enum Sign : bool { Unsigned, Signed }	

/+
struct InfiniteLoop(int maxCount = 512/*, string file = __FILE__, int line = __LINE__*/) {
	uint count = maxCount;
	void increment(void delegate() callback = null, string file = __FILE__, int line = __LINE__) {
		count--;
		if (count <= 0) {
			count = maxCount;
			writefln("Infinite loop detected at '%s':%d", file, line);
			if (callback !is null) callback();
		}
	}
}

void changeAfter(T)(T* var, int microseconds, T value) {
	(new Thread({
		microsleep(microseconds);
		*var = value;
	})).start();
}

static const changeAfterTimerPausedMicroseconds = "bool paused = true; changeAfter(&paused, delay, false);";
+/

class CircularList(Type, bool CheckAvailable = true) {
	/*
	struct Node {
		Type value;
		Node* next;
	}

	Node* head;
	Node* tail;
	Type[] pool;
	*/

	Type[] list;

	this(uint capacity = 1024) {
		list = new Type[capacity];
	}

	uint readAvailable;
	uint writeAvailable() { return list.length - readAvailable; }

	uint headPosition;
	void headPosition__Inc(int count = 1) {
		static if (CheckAvailable) {
			if (count > 0) {
				assert(readAvailable  >= +count);
			} else {
				assert(writeAvailable >= -count);
			}
		}
		headPosition = (headPosition + 1) % list.length;
		readAvailable -= count;
	}

	uint tailPosition;
	void tailPosition__Inc(int count = 1) {
		static if (CheckAvailable) {
			if (count > 0) {
				assert(writeAvailable >= +count);
			} else {
				assert(readAvailable  >= -count);
			}
		}
		tailPosition = (tailPosition + count) % list.length;
		readAvailable += count;
	}

	ref Type consume() {
		scope (exit) headPosition__Inc(1);
		return list[headPosition];
	}

	ref Type queue(Type value) {
		scope (exit) tailPosition__Inc(1);
		list[tailPosition] = value;
		return list[tailPosition];
	}

	ref Type dequeue() {
		tailPosition__Inc(-1);
		return list[tailPosition];
	}

	ref Type readFromTail(int pos = -1) {
		return list[(tailPosition + pos) % list.length];
	}

	alias consume consumeHead;
}

alias CircularList Queue;

extern (Windows) BOOL SwitchToThread();

void sleep(uint ms) {
	microsleep(ms * 1000);
}

/**
 * Return a microsecond tick.
 */
ulong microSecondsTick() {
	ulong count, frequency;
	QueryPerformanceCounter(cast(long *)&count);
	QueryPerformanceFrequency(cast(long *)&frequency);
	return (count * 1_000_000) / frequency;
}

/*string lowerPriorityForThisScope() { return q{
	int lastPriority = Thread.getThis.priority;
	Thread.getThis.priority = PRIORITY_MIN;
	scope (exit) Thread.getThis.priority = lastPriority;
} }*/

void microsleep(uint microSeconds) {
	if (microSeconds == 0) {
		Sleep(0);
	} else {
		int lastPriority = Thread.getThis.priority; Thread.getThis.priority = Thread.PRIORITY_MIN; scope (exit) Thread.getThis.priority = lastPriority;
		ulong start = microSecondsTick;
		Sleep(microSeconds / 1000);
		while ((microSecondsTick - start) < microSeconds) SwitchToThread();
	}
}

class TaskQueue {
	alias void delegate() Task;
	Task[] tasks;
	Object lock;
	
	this() {
		lock = new Object;
	}
	
	void add(Task task) { synchronized (lock) { tasks ~= task; } }
	void executeAll() { synchronized (lock) { foreach (task; tasks) task(); tasks.length = 0; } }
	void addAndWait(Task task) { add(task); waitExecuted(task); }
	void waitExecuted(Task task) {
		bool inList;
		do {
			synchronized (lock) {
				inList = false;
				foreach (ctask; tasks) if (ctask == task) { inList = true; break; }
			}
			if (!inList) sleep(1);
		} while (inList);
	}
	void waitEmpty() { while (tasks.length) sleep(1); }
	alias executeAll opCall;
}

/+
enum RunningState {
	RUNNING = 0,
	PAUSED  = 1,
	STOPPED = 2,
}

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
+/
