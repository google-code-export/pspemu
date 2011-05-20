module pspemu.core.display.Display;

import core.thread;
import std.stdio;
//import std.signals;

import core.sync.mutex;
import core.sync.condition;

import std.datetime;

import pspemu.core.Memory;

import pspemu.utils.Logger;

import pspemu.core.RunningState;
public import pspemu.hle.kd.display.Types;

/*
http://lan.st/archive/index.php/t-1103.html

Very sexy stuff, great work ;).
	
VSYNC freq of native psp lcd == (approx) 59.94Hz
	
or precisely (pixel_clk_freq * cycles_per_pixel)/(row_pixels * column_pixel)
so (9MHz * 1)/(525 * 286) == 59.9400599........ etc. etc.
	
HSYNC freq == (appox) 17.142KHz
	
or precisely (pixel_clk_freq * cycles_per_pixel)/(row_pixels)
so (9MHz * 1)/(525) == 17142.85714........ etc. etc.
*/
class Display {
	public RunningState runningState;
	public Memory memory;
	
	protected Thread thread;
	Condition drawRow0Condition;
	Condition vblankStartCondition;

	/**
	 * Mode of the screen.
	 * Usually it's 0.
	 */
	int  mode;
	int  width;
	int  height;
	uint topaddr;
	uint bufferwidth;
	
	/**
	 * Format of every pixel on the screen.
	 */
	PspDisplayPixelFormats pixelformat;
	PspDisplaySetBufSync sync;
	uint VBLANK_COUNT;
	
	const real processed_pixels_per_second = 9_000_000; // hz
	const real cycles_per_pixel            = 1;
	const real pixels_in_a_row             = 525;
	const real vsync_row                   = 272;
	const real number_of_rows              = 286;
	
	const real hsync_hz = (processed_pixels_per_second * cycles_per_pixel) / pixels_in_a_row;
	const real vsync_hz = hsync_hz / number_of_rows;
	
	bool enableWaitVblank = true;
	
	this(RunningState runningState, Memory memory) {
		this.runningState = runningState;
		this.memory       = memory;
		this.drawRow0Condition    = new Condition(new Mutex);
		this.vblankStartCondition = new Condition(new Mutex);
		
		sceDisplaySetMode(0, 480, 272);
		sceDisplaySetFrameBuf(0x44000000, 512, PspDisplayPixelFormats.PSP_DISPLAY_PIXEL_FORMAT_8888, PspDisplaySetBufSync.PSP_DISPLAY_SETBUF_IMMEDIATE);
	}

	public void sceDisplaySetMode(int mode = 0, int width = 480, int height = 272) {
		Logger.log(Logger.Level.TRACE, "Display", "sceDisplaySetMode(%d, %d, %d)", mode, width, height);
		this.mode   = mode;
		this.width  = width;
		this.height = height;
	}
	
	public void sceDisplaySetFrameBuf(uint topaddr, uint bufferwidth, PspDisplayPixelFormats pixelformat, PspDisplaySetBufSync sync) {
		this.topaddr     = topaddr;
		this.bufferwidth = bufferwidth;
		this.pixelformat = pixelformat;
		this.sync        = sync;
		Logger.log(Logger.Level.TRACE, "Display", "sceDisplaySetFrameBuf(%08X, %d, %d, %d)", topaddr, bufferwidth, pixelformat, sync);
	}
	
	public void start() {
		this.thread = new Thread(&this.run);
		this.thread.name = "DisplayThread";
		this.thread.start();
	}
	
	public void waitVblank() {
		if (enableWaitVblank) vblankStartCondition.wait();
	}

	protected void run() {
		StopWatch stopWatch;
		
		while (this.runningState.running) {
			this.drawRow0Condition.notifyAll();
			Thread.sleep(dur!"usecs"(cast(ulong)(1_000_000 * (vsync_row / hsync_hz))));

			this.vblankStartCondition.notifyAll();
			VBLANK_COUNT++;
			Thread.sleep(dur!"usecs"(cast(ulong)(1_000_000 * ((number_of_rows - vsync_row) / hsync_hz))));
		}
		
		Logger.log(Logger.Level.TRACE, "Display", "Display.run::ended");
	}
}