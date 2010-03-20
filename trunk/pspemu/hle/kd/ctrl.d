module pspemu.hle.kd.ctrl; // kd/ctrl.prx (sceController_Service)

//debug = DEBUG_SYSCALL;

import pspemu.hle.Module;

class sceCtrl_driver : Module {
	this() {
		mixin(registerd!(0x6A2774F3, sceCtrlSetSamplingCycle));
		mixin(registerd!(0x1F4011E6, sceCtrlSetSamplingMode));
		mixin(registerd!(0x1F803938, sceCtrlReadBufferPositive));
		mixin(registerd!(0x3A622550, sceCtrlPeekBufferPositive));
	}

	void readBufferedFrames(ref SceCtrlData sceCtrlData, int count = 1, bool positive = true) {
		static uint frame = 0;
		sceCtrlData.TimeStamp = frame++;
		sceCtrlData.Buttons = 0;
		sceCtrlData.x = 0;
		sceCtrlData.y = 0;
		sceCtrlData.Rsrv[] = 0;
		// Negate.
		if (!positive) sceCtrlData.Buttons = ~sceCtrlData.Buttons;
	}

	/**
	 * Read buffer positive
	 *
	 * @par Example:
	 * @code
	 * SceCtrlData pad;

	 * sceCtrlSetSamplingCycle(0);
	 * sceCtrlSetSamplingMode(1);
	 * sceCtrlReadBufferPositive(&pad, 1);
	 * // Do something with the read controller data
	 * @endcode
	 *
	 * @param pad_data - Pointer to a ::SceCtrlData structure used hold the returned pad data.
	 * @param count - Number of ::SceCtrlData buffers to read.
	 */
	int sceCtrlReadBufferPositive(SceCtrlData* pad_data, int count) {
		readBufferedFrames(*pad_data, count, true);
		return 0;
	}

	int sceCtrlPeekBufferPositive(SceCtrlData* pad_data, int count) {
		readBufferedFrames(*pad_data, count, true);
		return 0;
	}

	/**
	 * Set the controller cycle setting.
	 *
	 * @param cycle - Cycle.  Normally set to 0.
	 *
	 * @return The previous cycle setting.
	 */
	int sceCtrlSetSamplingCycle(int cycle) {
		return 0;
	}

	/**
	 * Set the controller mode.
	 *
	 * @param mode - One of ::PspCtrlMode.
	 *
	 * @return The previous mode.
	 */
	int sceCtrlSetSamplingMode(int mode) {
		return 0;
	}
}

class sceCtrl : sceCtrl_driver {
}

/**
 * Enumeration for the digital controller buttons.
 *
 * @note PSP_CTRL_HOME, PSP_CTRL_NOTE, PSP_CTRL_SCREEN, PSP_CTRL_VOLUP, PSP_CTRL_VOLDOWN, PSP_CTRL_DISC, PSP_CTRL_WLAN_UP, PSP_CTRL_REMOTE, PSP_CTRL_MS can only be read in kernel mode
 */
enum PspCtrlButtons {
	/** Select button. */
	PSP_CTRL_SELECT     = 0x000001,
	/** Start button. */
	PSP_CTRL_START      = 0x000008,
	/** Up D-Pad button. */
	PSP_CTRL_UP         = 0x000010,
	/** Right D-Pad button. */
	PSP_CTRL_RIGHT      = 0x000020,
	/** Down D-Pad button. */
	PSP_CTRL_DOWN      	= 0x000040,
	/** Left D-Pad button. */
	PSP_CTRL_LEFT      	= 0x000080,
	/** Left trigger. */
	PSP_CTRL_LTRIGGER   = 0x000100,
	/** Right trigger. */
	PSP_CTRL_RTRIGGER   = 0x000200,
	/** Triangle button. */
	PSP_CTRL_TRIANGLE   = 0x001000,
	/** Circle button. */
	PSP_CTRL_CIRCLE     = 0x002000,
	/** Cross button. */
	PSP_CTRL_CROSS      = 0x004000,
	/** Square button. */
	PSP_CTRL_SQUARE     = 0x008000,
	/** Home button. In user mode this bit is set if the exit dialog is visible. */
	PSP_CTRL_HOME       = 0x010000,
	/** Hold button. */
	PSP_CTRL_HOLD       = 0x020000,
	/** Music Note button. */
	PSP_CTRL_NOTE       = 0x800000,
	/** Screen button. */
	PSP_CTRL_SCREEN     = 0x400000,
	/** Volume up button. */
	PSP_CTRL_VOLUP      = 0x100000,
	/** Volume down button. */
	PSP_CTRL_VOLDOWN    = 0x200000,
	/** Wlan switch up. */
	PSP_CTRL_WLAN_UP    = 0x040000,
	/** Remote hold position. */
	PSP_CTRL_REMOTE     = 0x080000,	
	/** Disc present. */
	PSP_CTRL_DISC       = 0x1000000,
	/** Memory stick present. */
	PSP_CTRL_MS         = 0x2000000,
}

/** Controller mode. */
enum PspCtrlMode {
	/* Digitial. */
	PSP_CTRL_MODE_DIGITAL = 0,
	/* Analog. */
	PSP_CTRL_MODE_ANALOG
}

/** Returned controller data */
struct SceCtrlData {
	/** The current read frame. */
	uint 	TimeStamp;
	/** Bit mask containing zero or more of ::PspCtrlButtons. */
	uint 	Buttons;
	/** Analogue stick, X axis. */
	ubyte 	Lx;
	/** Analogue stick, Y axis. */
	ubyte 	Ly;
	/** Reserved. */
	ubyte 	Rsrv[6];

	// D additions.
	float x() { return (cast(float)Lx / 255.0) - 0.5; }
	float y() { return (cast(float)Ly / 255.0) - 0.5; }
	float x(float x) { Lx = cast(ubyte)((x + 0.5) * 255.0); return x; }
	float y(float y) { Ly = cast(ubyte)((y + 0.5) * 255.0); return y; }
}

static this() {
	mixin(Module.registerModule("sceCtrl"));
	mixin(Module.registerModule("sceCtrl_driver"));
}