module pspemu.hle.kd.ctrl.sceCtrl_driver; // kd/ctrl.prx (sceController_Service)

//debug = DEBUG_SYSCALL;
//debug = DEBUG_CONTROLLER;

import pspemu.hle.Module;

//import pspemu.models.IController;
//import pspemu.utils.Utils;

import pspemu.hle.ModuleNative;
import pspemu.hle.kd.ctrl.Types;

// http://forums.qj.net/psp-development-forum/141207-using-analog-stick-c-question.html

class sceCtrl_driver : ModuleNative {
	void initNids() {
		mixin(registerd!(0x6A2774F3, sceCtrlSetSamplingCycle));
		mixin(registerd!(0x1F4011E6, sceCtrlSetSamplingMode));
		mixin(registerd!(0x1F803938, sceCtrlReadBufferPositive));
		mixin(registerd!(0x3A622550, sceCtrlPeekBufferPositive));
		mixin(registerd!(0x0B588501, sceCtrlReadLatch));
		mixin(registerd!(0xB1D0E5CD, sceCtrlPeekLatch));
		mixin(registerd!(0xA7144800, sceCtrlSetIdleCancelThresholdFunction));
	}

	void readBufferedFrames(SceCtrlData* pad_data, int count = 1, bool positive = true) {
		SceCtrlData empty;
		with (empty) {
			Ly = Lx = 127;
		}
		for (int n = 0; n < count; n++) {
			//pad_data[n] = currentEmulatorState.controller.frameRead(n);
			pad_data[n] = empty;

			debug (DEBUG_CONTROLLER) {
				writefln("readBufferedFrames: %s", pad_data[n]);
			}

			// Negate.
			if (!positive) pad_data[n].Buttons = ~pad_data[n].Buttons;
		}
	}

	/**
	 * Read buffer positive
	 *
	 * @par Example:
	 * <code>
	 *     SceCtrlData pad;
	 *
	 *     sceCtrlSetSamplingCycle(0);
	 *     sceCtrlSetSamplingMode(1);
	 *     sceCtrlReadBufferPositive(&pad, 1);
	 *     // Do something with the read controller data
	 * </code>
	 *
	 * @param pad_data - Pointer to a ::SceCtrlData structure used hold the returned pad data.
	 * @param count    - Number of ::SceCtrlData buffers to read.
	 *
	 * @return Count?
	 */
	// sceCtrlReadBufferPositive () is blocking and waits for vblank (slower).
	int sceCtrlReadBufferPositive(SceCtrlData* pad_data, int count) {
		readBufferedFrames(pad_data, count, true);
		// @TODO: Wait for vblank.
		return count;
	}

	// sceCtrlPeekBufferPositive () is non-blocking (faster)
	int sceCtrlPeekBufferPositive(SceCtrlData* pad_data, int count) {
		readBufferedFrames(pad_data, count, true);
		return count;
	}

	/**
	 * Set the controller cycle setting.
	 *
	 * @param cycle - Cycle. Normally set to 0.
	 *
	 * @TODO Unknown what this means exactly.
	 *
	 * @return The previous cycle setting.
	 */
	int sceCtrlSetSamplingCycle(int cycle) {
		/*
		int previousCycle = currentEmulatorState.controller.samplingCycle;
		currentEmulatorState.controller.samplingCycle = cycle;
		if (cycle != 0) writefln("sceCtrlSetSamplingCycle != 0! :: %d", cycle);
		return previousCycle;
		*/
		writefln("NOTIMPLEMENTED: sceCtrlSetSamplingCycle(%d)", cycle);
		return -1;
	}

	/**
	 * Set the controller mode.
	 *
	 * @param mode - One of ::PspCtrlMode.
	 *             - PSP_CTRL_MODE_DIGITAL = 0
	 *             - PSP_CTRL_MODE_ANALOG  = 1
	 *
	 * PSP_CTRL_MODE_DIGITAL is the same as PSP_CTRL_MODE_ANALOG
	 * except that doesn't update Lx and Ly values. Setting them to 0x80.
	 *
	 * @return The previous mode.
	 */
	int sceCtrlSetSamplingMode(int mode) {
		writefln("NOTIMPLEMENTED: sceCtrlSetSamplingMode(%d)", mode);
		/*
		uint previouseMode = cast(int)cpu.controller.samplingMode;
		cpu.controller.samplingMode = cast(Controller.Mode)mode;
		return previouseMode;
		*/
		return -1;
	}
	
	SceCtrlLatch lastLatch;
	
	/**
	 * Obtains information about currentLatch.
	 *
	 * @param currentLatch - Pointer to SceCtrlLatch to store the result.
	 *
	 * @return 
	 */
	int sceCtrlReadLatch(SceCtrlLatch* currentLatch) {
		SceCtrlData pad;
		readBufferedFrames(&pad, 1, true);
		
		currentLatch.uiPress   = cast(PspCtrlButtons)pad.Buttons;
		currentLatch.uiRelease = cast(PspCtrlButtons)~pad.Buttons;
		currentLatch.uiMake    = (lastLatch.uiRelease ^ currentLatch.uiRelease) & lastLatch.uiRelease;
		currentLatch.uiBreak   = (lastLatch.uiPress   ^ currentLatch.uiPress  ) & lastLatch.uiPress;

		//unimplemented_notice();
		lastLatch = *currentLatch;

		return 0;
	}

	/**
	 * Obtains information about currentLatch.
	 *
	 * @param currentLatch - Pointer to SceCtrlLatch to store the result.
	 *
	 * @return 
	 */
	int sceCtrlPeekLatch(SceCtrlLatch* currentLatch) {
		SceCtrlData pad;
		readBufferedFrames(&pad, 1, true);
		
		currentLatch.uiPress   = cast(PspCtrlButtons)pad.Buttons;
		currentLatch.uiRelease = cast(PspCtrlButtons)~pad.Buttons;
		currentLatch.uiMake    = (lastLatch.uiRelease ^ currentLatch.uiRelease) & lastLatch.uiRelease;
		currentLatch.uiBreak   = (lastLatch.uiPress   ^ currentLatch.uiPress  ) & lastLatch.uiPress;

		//unimplemented_notice();
		lastLatch = *currentLatch;

		return 0;
	}

	void sceCtrlSetIdleCancelThresholdFunction() {
		unimplemented();
	}
}

static this() {
	mixin(ModuleNative.registerModule("sceCtrl_driver"));
}