module pspemu.hle.kd.ctrl.Types; // kd/ctrl.prx (sceController_Service)

import std.string;
import pspemu.utils.MathUtils;

/**
 * Enumeration for the digital controller buttons.
 *
 * @note PSP_CTRL_HOME, PSP_CTRL_NOTE, PSP_CTRL_SCREEN, PSP_CTRL_VOLUP, PSP_CTRL_VOLDOWN, PSP_CTRL_DISC, PSP_CTRL_WLAN_UP, PSP_CTRL_REMOTE, PSP_CTRL_MS can only be read in kernel mode
 */
enum PspCtrlButtons : uint { // Set
	PSP_CTRL_NONE      = 0x_0000000,
	PSP_CTRL_SELECT    = 0x_0000001, /// Select button.
	PSP_CTRL_START     = 0x_0000008, /// Start button.
	PSP_CTRL_UP        = 0x_0000010, /// Up D-Pad button.
	PSP_CTRL_RIGHT     = 0x_0000020, /// Right D-Pad button.
	PSP_CTRL_DOWN      = 0x_0000040, /// Down D-Pad button.
	PSP_CTRL_LEFT      = 0x_0000080, /// Left D-Pad button.
	PSP_CTRL_LTRIGGER  = 0x_0000100, /// Left trigger.
	PSP_CTRL_RTRIGGER  = 0x_0000200, /// Right trigger.
	PSP_CTRL_TRIANGLE  = 0x_0001000, /// Triangle button.
	PSP_CTRL_CIRCLE    = 0x_0002000, /// Circle button.
	PSP_CTRL_CROSS     = 0x_0004000, /// Cross button.
	PSP_CTRL_SQUARE    = 0x_0008000, /// Square button.
	PSP_CTRL_HOME      = 0x_0010000, /// Home button. In user mode this bit is set if the exit dialog is visible.
	PSP_CTRL_HOLD      = 0x_0020000, /// Hold button.
	PSP_CTRL_WLAN_UP   = 0x_0040000, /// Wlan switch up.
	PSP_CTRL_REMOTE    = 0x_0080000, /// Remote hold position.
	PSP_CTRL_VOLUP     = 0x_0100000, /// Volume up button.
	PSP_CTRL_VOLDOWN   = 0x_0200000, /// Volume down button.
	PSP_CTRL_SCREEN    = 0x_0400000, /// Screen button.
	PSP_CTRL_NOTE      = 0x_0800000, /// Music Note button.
	PSP_CTRL_DISC      = 0x_1000000, /// Disc present.
	PSP_CTRL_MS        = 0x_2000000, /// Memory stick present.
}

/**
 * Controller mode.
 */
enum PspCtrlMode {
	PSP_CTRL_MODE_DIGITAL = 0, /// Digitial.
	PSP_CTRL_MODE_ANALOG  = 1, /// Analog.
}

/**
 * Controller latch.
 */
struct SceCtrlLatch {
	PspCtrlButtons uiMake;    /// A bit fields of buttons just pressed (since last call?)
	PspCtrlButtons uiBreak;   /// A bit fields of buttons just released (since last call?)
	PspCtrlButtons uiPress;   /// Same has SceCtrlData.Buttons?
	PspCtrlButtons uiRelease; /// A bit field of buttons released 
}

/** Returned controller data */
struct SceCtrlData {
	uint 	TimeStamp = 0; /// The current read frame.
	uint 	Buttons = 0;   /// Bit mask containing zero or more of ::PspCtrlButtons.
	ubyte 	Lx = 127;      /// Analogue stick, X axis.
	ubyte 	Ly = 127;      /// Analogue stick, Y axis.
	ubyte 	Rsrv[6];       /// Reserved.
	
	public bool IsPressedButton(PspCtrlButtons pspCtrlButton) {
		return (Buttons & pspCtrlButton) != 0;
	}

	public int IsPressedButton2(PspCtrlButtons pspCtrlButton1, PspCtrlButtons pspCtrlButton2) {
		if (IsPressedButton(pspCtrlButton1)) return -1;
		if (IsPressedButton(pspCtrlButton2)) return +1;
		return 0;
	}
	
	public void SetPressedButton(PspCtrlButtons pspCtrlButton, bool Pressed) {
		if (Pressed) {
			Buttons |= pspCtrlButton; 
		} else {
			Buttons &= ~pspCtrlButton;
		}
	}
	
	static string component(string v) {
		return 
			"@property real " ~ v ~ "() { return cast(real)(L" ~ v ~ " - 127) / 127; }"
			"@property real " ~ v ~ "(real value) { int v = (cast(int)(value * 127) + 127); L" ~ v ~ " = cast(ubyte)clamp(v, 0, 255); return " ~ v ~ "; }"
		;
	}
	
	mixin(component("x"));
	mixin(component("y"));
	
	string toString() {
		return std.string.format("SceCtrlData(TimeStamp=%d, Buttons=%032b, x=%.3f, y=%.3f)", TimeStamp, Buttons, x, y);
	}

	static assert(this.sizeof == 16);
}