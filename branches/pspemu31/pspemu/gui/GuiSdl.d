module pspemu.gui.GuiSdl;

import std.stdio;
import core.thread;
import derelict.sdl.sdl;
import std.process;

import pspemu.gui.GuiBase;
import pspemu.utils.MathUtils;

import pspemu.core.cpu.CpuThreadBase;

class GuiSdl : GuiBase {
	bool[SDLK_LAST] keyIsPressed;
	PspCtrlButtons[SDLK_LAST] buttonMask;
	SDL_Surface *screenSurface;
	
	this(EmulatorState emulatorState) {
		super(emulatorState);
	}

	public void init() {
		environment["SDL_VIDEO_WINDOW_POS"] = "";
		environment["SDL_VIDEO_CENTERED"] = "1";
		
		DerelictSDL.load();
		SDL_Init(SDL_INIT_VIDEO);
		screenSurface = SDL_SetVideoMode(480, 272, 32, 0);
		
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
	}
	
	public void loopStep() {
		this.drawScreen();
		this.pollEvents();
	}
	
	protected void pollEvents() {
		SceCtrlData *sceCtrlData = &this.controller.sceCtrlData;
		
		SDL_Event event;
		SDL_PollEvent(&event);
		//SDL_EnableKeyRepeat(SDL_DEFAULT_REPEAT_DELAY, SDL_DEFAULT_REPEAT_INTERVAL);
		switch (event.type) {
			case SDL_KEYDOWN, SDL_KEYUP: {
				bool Pressed = (event.type == SDL_KEYDOWN);
				int sym = event.key.keysym.sym;

				keyIsPressed[sym] = Pressed;
				sceCtrlData.SetPressedButton(buttonMask[sym], Pressed);
				
				if (!Pressed) {
					switch (sym) {
						case SDLK_F2:
							try {
								writefln("Threads(%d):", Thread.getAll.length);
								foreach (thread; Thread.getAll) {
									writefln("  - Thread: '%s', running:%d, priority:%d", thread.name, thread.isRunning, thread.priority);
								}
								writefln("CpuThreads(%d):", emulatorState.cpuThreads.length);
								foreach (CpuThreadBase cpuThread; emulatorState.cpuThreads.keys.dup) {
									writef("  - CpuThread:");
									try {
										writef("%s", cpuThread);
									} catch {
										
									}
									writefln("");
									//int callStackPosEnd   = min(cast(int)cpuThread.threadState.registers.CallStackPos, cast(int)cpuThread.threadState.registers.CallStack.length);
									//int callStackPosStart = max(0, callStackPosEnd - 10);
	
									try {								
										//foreach (k, pc; cpuThread.threadState.registers.CallStack[callStackPosStart..callStackPosEnd])
										foreach (k, pc; cpuThread.threadState.registers.CallStack[0..cpuThread.threadState.registers.CallStackPos]) {
											writefln("    - %d - 0x%08X", k, pc);
										}
									} catch (Throwable o) {
										
									}
								}
							} catch (Throwable o) {
								
							}
						break;
						case SDLK_F3:
							this.display.enableWaitVblank = !this.display.enableWaitVblank; 
						break;
						default:
						break;
					}
				}
				
				//sceCtrlData.x = cast(float)sceCtrlData.IsPressedButton2(PspCtrlButtons.PSP_CTRL_LEFT, PspCtrlButtons.PSP_CTRL_RIGHT);
				//sceCtrlData.y = cast(float)sceCtrlData.IsPressedButton2(PspCtrlButtons.PSP_CTRL_UP  , PspCtrlButtons.PSP_CTRL_DOWN );
			} break;
			case SDL_QUIT:
				this.display.runningState.stop();
			break;
			default:
			break;
		}
		
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
		
		this.controller.push();
	}
	
	protected void drawScreen() {
		uint makebits(int disp, int nbits) {
			return ((1 << nbits) - 1) << disp;
		}

		int pixelWidth = 4;
		uint RMASK, GMASK, BMASK, AMASK;
		switch (this.display.pixelformat) {
			case PspDisplayPixelFormats.PSP_DISPLAY_PIXEL_FORMAT_565:
				pixelWidth = 2;
				RMASK = makebits(0        , 5);
				GMASK = makebits(0 + 5    , 6);
				BMASK = makebits(0 + 5 + 6, 5);
				AMASK = 0;
			break;
			case PspDisplayPixelFormats.PSP_DISPLAY_PIXEL_FORMAT_5551:
				pixelWidth = 2;
				RMASK = makebits(0 * 5, 5);
				GMASK = makebits(1 * 5, 5);
				BMASK = makebits(2 * 5, 5);
				AMASK = makebits(3 * 5, 1);
			break;
			case PspDisplayPixelFormats.PSP_DISPLAY_PIXEL_FORMAT_4444:
				pixelWidth = 2;
				RMASK = makebits(0 * 4, 4);
				GMASK = makebits(1 * 4, 4);
				BMASK = makebits(2 * 4, 4);
				AMASK = makebits(3 * 4, 4);
			break;
			case PspDisplayPixelFormats.PSP_DISPLAY_PIXEL_FORMAT_8888:
				pixelWidth = 4;
				RMASK = makebits(0 * 8, 8);
				GMASK = makebits(1 * 8, 8);
				BMASK = makebits(2 * 8, 8);
				AMASK = makebits(3 * 8, 8);
			break;
		}
		
		SDL_Surface* displaySurface = SDL_CreateRGBSurfaceFrom(this.display.memory.getPointer(this.display.topaddr), this.display.width, this.display.height, 8 * pixelWidth, this.display.bufferwidth * pixelWidth, RMASK, GMASK, BMASK, 0);
		{
			SDL_BlitSurface(displaySurface, null, screenSurface, null);
			SDL_Flip(screenSurface);
		}
		SDL_FreeSurface(displaySurface);
	}
}