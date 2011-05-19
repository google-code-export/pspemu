module pspemu.core.display.Display;

import core.thread;
import pspemu.core.Memory;
import derelict.sdl.sdl;
import std.process;
import std.stdio;
//import std.signals;

import core.sync.mutex;
import core.sync.condition;

import pspemu.utils.Event;

class Display {
	public Memory memory;
	protected Thread thread;
	protected bool running = true;
	Event onStop;
	Condition vblankStartCondition;

	int  mode;
	int  width, height;
	uint topaddr;
	uint bufferwidth;
	uint pixelformat;
	uint sync;
	uint VBLANK_COUNT;
	
	this(Memory memory) {
		this.memory = memory;
		this.vblankStartCondition = new Condition(new Mutex);
		this.onStop += delegate() {
			running = false;
		};
	}

	public void sceDisplaySetMode(int mode = 0, int width = 480, int height = 272) {
		this.mode   = mode;
		this.width  = width;
		this.height = height;
		//writefln("sceDisplaySetMode(%d, %d, %d)", mode, width, height);
	}
	
	public void sceDisplaySetFrameBuf(uint topaddr, uint bufferwidth, uint pixelformat, uint sync) {
		this.topaddr     = topaddr;
		this.bufferwidth = bufferwidth;
		this.pixelformat = pixelformat;
		this.sync        = sync;
		//writefln("sceDisplaySetFrameBuf(%08X, %d, %d, %d)", topaddr, bufferwidth, pixelformat, sync);
	}
	
	public void start() {
		this.thread = new Thread(&this.run);
		this.thread.start();
	}
	
	public void waitVblank() {
		vblankStartCondition.wait();
	}
	
	protected void run() {
		environment["SDL_VIDEO_WINDOW_POS"] = "";
		environment["SDL_VIDEO_CENTERED"] = "1";
		
		DerelictSDL.load();
		SDL_Init(SDL_INIT_VIDEO);
		auto screen = SDL_SetVideoMode(480, 272, 32, 0);
		
		sceDisplaySetMode(0, 480, 272);
		sceDisplaySetFrameBuf(0x44000000, 512, 3, 1);
		
		//for (int n = 0; n < 512 * 272 * 4; n++) memory.frameBuffer[n] = 0xFF;
		
		enum PspDisplayPixelFormats {
			PSP_DISPLAY_PIXEL_FORMAT_565 = 0,
			PSP_DISPLAY_PIXEL_FORMAT_5551,
			PSP_DISPLAY_PIXEL_FORMAT_4444,
			PSP_DISPLAY_PIXEL_FORMAT_8888
		}
		
		uint makebits(int disp, int nbits) {
			return ((1 << nbits) - 1) << disp;
		}
		
		while (running) {
			SDL_Event event;
			SDL_PollEvent(&event);
			switch (event.type) {
				case SDL_KEYUP, SDL_QUIT:
					onStop();
				break;
				default:
				break;
			}
			
			SDL_Surface* display;
			switch (cast(PspDisplayPixelFormats)this.pixelformat) {
				case PspDisplayPixelFormats.PSP_DISPLAY_PIXEL_FORMAT_565:
					display = SDL_CreateRGBSurfaceFrom(memory.getPointer(this.topaddr), this.width, this.height, 16, this.bufferwidth * 2, makebits(0, 5), makebits(5, 6), makebits(11, 5), 0x00000000);
				break;
				case PspDisplayPixelFormats.PSP_DISPLAY_PIXEL_FORMAT_5551:
					//display = SDL_CreateRGBSurfaceFrom(memory.getPointer(this.topaddr), this.width, this.height, 16, this.bufferwidth * 2, makebits(0, 5), makebits(5, 5), makebits(10, 5), makebits(15, 1));
					display = SDL_CreateRGBSurfaceFrom(memory.getPointer(this.topaddr), this.width, this.height, 16, this.bufferwidth * 2, makebits(0, 5), makebits(5, 5), makebits(10, 5), 0);
				break;
				case PspDisplayPixelFormats.PSP_DISPLAY_PIXEL_FORMAT_4444:
					//display = SDL_CreateRGBSurfaceFrom(memory.getPointer(this.topaddr), this.width, this.height, 16, this.bufferwidth * 2, makebits(0, 4), makebits(4, 4), makebits(8, 4), makebits(12, 4));
					display = SDL_CreateRGBSurfaceFrom(memory.getPointer(this.topaddr), this.width, this.height, 16, this.bufferwidth * 2, makebits(0, 4), makebits(4, 4), makebits(8, 4), 0);
				break;
				default:
				case PspDisplayPixelFormats.PSP_DISPLAY_PIXEL_FORMAT_8888:
					display = SDL_CreateRGBSurfaceFrom(memory.getPointer(this.topaddr), this.width, this.height, 32, this.bufferwidth * 4, 0x000000FF, 0x0000FF00, 0x00FF0000, 0x00000000);
				break;
			}
			
			/*
				PspDisplayPixelFormats { PSP_DISPLAY_PIXEL_FORMAT_565 = 0, PSP_DISPLAY_PIXEL_FORMAT_5551, PSP_DISPLAY_PIXEL_FORMAT_4444, PSP_DISPLAY_PIXEL_FORMAT_8888 }
			*/
			SDL_BlitSurface(display, null, screen, null);
			SDL_Flip(screen);
			
			SDL_FreeSurface(display);

			this.vblankStartCondition.notifyAll();
			VBLANK_COUNT++;
			
			SDL_Delay(1000 / 60);
		}
		
		writefln("Display.run::ended");
	}
}