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
import pspemu.utils.CircularList;

import pspemu.hle.kd.ctrl.Types;

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
		this.thread.name = "DisplayThread";
		this.thread.start();
	}
	
	public void waitVblank() {
		vblankStartCondition.wait();
	}
	
	SceCtrlData sceCtrlData;
	CircularList!(SceCtrlData) sceCtrlDataFrames;
	
	protected void run() {
		sceCtrlDataFrames = new CircularList!(SceCtrlData)();
		
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
		
		bool[SDLK_LAST] keyIsPressed;
		
		PspCtrlButtons[SDLK_LAST] buttonMask;
		
		buttonMask[SDLK_UP    ] = PspCtrlButtons.PSP_CTRL_UP;
		buttonMask[SDLK_DOWN  ] = PspCtrlButtons.PSP_CTRL_DOWN; 
		buttonMask[SDLK_LEFT  ] = PspCtrlButtons.PSP_CTRL_LEFT;
		buttonMask[SDLK_RIGHT ] = PspCtrlButtons.PSP_CTRL_RIGHT;
		buttonMask[SDLK_w     ] = PspCtrlButtons.PSP_CTRL_TRIANGLE;
		buttonMask[SDLK_a     ] = PspCtrlButtons.PSP_CTRL_SQUARE;
		buttonMask[SDLK_s     ] = PspCtrlButtons.PSP_CTRL_CROSS;
		buttonMask[SDLK_d     ] = PspCtrlButtons.PSP_CTRL_CIRCLE;
		buttonMask[SDLK_q     ] = PspCtrlButtons.PSP_CTRL_LTRIGGER;
		buttonMask[SDLK_e     ] = PspCtrlButtons.PSP_CTRL_RTRIGGER;
		buttonMask[SDLK_RETURN] = PspCtrlButtons.PSP_CTRL_START;
		buttonMask[SDLK_SPACE ] = PspCtrlButtons.PSP_CTRL_SELECT;
		
		while (running) {
			SDL_Event event;
			SDL_PollEvent(&event);
			//SDL_EnableKeyRepeat(SDL_DEFAULT_REPEAT_DELAY, SDL_DEFAULT_REPEAT_INTERVAL);
			switch (event.type) {
				case SDL_KEYDOWN, SDL_KEYUP: {
					bool Pressed = (event.type == SDL_KEYDOWN);
					int sym = event.key.keysym.sym;

					keyIsPressed[sym] = Pressed;
					sceCtrlData.SetPressedButton(buttonMask[sym], Pressed);
					
					if (sym == SDLK_F2 && !Pressed) {
						writefln("Threads(%d):", Thread.getAll.length);
						foreach (thread; Thread.getAll) {
							writefln("  - Thread: '%s', running:%d, priority:%d", thread.name, thread.isRunning, thread.priority);
						}
					}

					//sceCtrlData.x = cast(float)sceCtrlData.IsPressedButton2(PspCtrlButtons.PSP_CTRL_LEFT, PspCtrlButtons.PSP_CTRL_RIGHT);
					//sceCtrlData.y = cast(float)sceCtrlData.IsPressedButton2(PspCtrlButtons.PSP_CTRL_UP  , PspCtrlButtons.PSP_CTRL_DOWN );
				} break;
				case SDL_QUIT:
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
			
			if (sceCtrlData.IsPressedButton(PspCtrlButtons.PSP_CTRL_LEFT)) {
				sceCtrlData.x = sceCtrlData.x - 0.1;
			} else if (sceCtrlData.IsPressedButton(PspCtrlButtons.PSP_CTRL_RIGHT)) {
				sceCtrlData.x = sceCtrlData.x + 0.1;
			} else {
				sceCtrlData.x = sceCtrlData.x / 10.0;
			}

			if (sceCtrlData.IsPressedButton(PspCtrlButtons.PSP_CTRL_UP)) {
				sceCtrlData.y = sceCtrlData.y - 0.1;
			} else if (sceCtrlData.IsPressedButton(PspCtrlButtons.PSP_CTRL_DOWN)) {
				sceCtrlData.y = sceCtrlData.y + 0.1;
			} else {
				sceCtrlData.y = sceCtrlData.y / 10.0;
			}
			
			//writefln("%.4f, %.4f", sceCtrlData.x, sceCtrlData.y);
			
			sceCtrlData.TimeStamp++;
			//.writefln("%s", sceCtrlData);
			sceCtrlDataFrames.enqueue(sceCtrlData);
			
			SDL_Delay(1000 / 60);
		}
		
		writefln("Display.run::ended");
	}
}