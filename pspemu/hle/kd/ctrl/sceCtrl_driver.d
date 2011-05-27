module pspemu.hle.kd.ctrl.sceCtrl_driver; // kd/ctrl.prx (sceController_Service)

//debug = DEBUG_SYSCALL;
//debug = DEBUG_CONTROLLER;

import std.stdio;

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
		for (int n = 0; n < count; n++) {
			pad_data[n] = currentEmulatorState.controller.readAt(n);
			
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
		currentEmulatorState().display.waitVblank();
		readBufferedFrames(pad_data, count, true);
		logTrace("sceCtrlReadBufferPositive(%d):%s", count, *pad_data);
		return count;
	}

	// sceCtrlPeekBufferPositive () is non-blocking (faster)
	int sceCtrlPeekBufferPositive(SceCtrlData* pad_data, int count) {
		readBufferedFrames(pad_data, count, true);
		logTrace("sceCtrlPeekBufferPositive(%d):%s", count, *pad_data);
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
		logInfo("sceCtrlSetSamplingCycle(%d)", cycle);
		int previousCycle = currentEmulatorState.controller.samplingCycle;
		currentEmulatorState.controller.samplingCycle = cycle;
		return previousCycle;
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
	PspCtrlMode sceCtrlSetSamplingMode(PspCtrlMode mode) {
		logInfo("sceCtrlSetSamplingMode(%d)", mode);
		PspCtrlMode previouseMode = currentEmulatorState.controller.samplingMode;
		currentEmulatorState.controller.samplingMode = mode;
		return previouseMode;
	}
	
	SceCtrlLatch lastLatch;
	
	int _sceCtrlReadLatch(SceCtrlLatch* currentLatch) {
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
	int sceCtrlReadLatch(SceCtrlLatch* currentLatch) {
		currentEmulatorState().display.waitVblank();
		logInfo("sceCtrlReadLatch()");
		return _sceCtrlReadLatch(currentLatch);
	}

	/**
	 * Obtains information about currentLatch.
	 *
	 * @param currentLatch - Pointer to SceCtrlLatch to store the result.
	 *
	 * @return 
	 */
	int sceCtrlPeekLatch(SceCtrlLatch* currentLatch) {
		logInfo("sceCtrlPeekLatch()");
		return _sceCtrlReadLatch(currentLatch);
	}

	void sceCtrlSetIdleCancelThresholdFunction() {
		unimplemented_notice();
	}
}

static this() {
	mixin(ModuleNative.registerModule("sceCtrl_driver"));
}