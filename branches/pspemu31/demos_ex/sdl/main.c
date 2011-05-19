#include <pspkernel.h>
#include <pspthreadman.h>
#include <pspdebug.h>
#include <stdio.h>
#include <string.h>

PSP_MODULE_INFO("SDL TEST", 0, 1, 1);
PSP_MAIN_THREAD_ATTR(THREAD_ATTR_USER | THREAD_ATTR_VFPU);

#include <SDL/SDL.h>

void SDL_putpixel(SDL_Surface *surface, int x, int y, Uint32 color) {
	*((Uint32 *)(surface->pixels + y * surface->pitch + x * sizeof(Uint32))) = color;
}

int main(int argc, char *argv[]) {
	SDL_Surface* screen;
	int x, y;

	SDL_Init(SDL_INIT_VIDEO);
	screen = SDL_SetVideoMode(480, 272, 32, SDL_HWSURFACE);
	for (y = 0; y < 272; y++) {
		for (x = 0; x < 480; x++) {
			SDL_putpixel(screen, x, y, 0xFFFFFFFF);
		}
	}

	return 0;
}