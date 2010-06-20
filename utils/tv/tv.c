
#include <stdio.h>
#include <stdlib.h>
#include <signal.h>

#include <SDL/SDL.h>

typedef unsigned int u32;

#define HH 768
#define VV 896
u32 fb[(HH/32)*VV];

static SDL_Surface *screen;

int sdl_init(void)
{
	int flags, rows, cols;

	cols = HH;
	rows = VV;

	flags = SDL_INIT_VIDEO | SDL_INIT_NOPARACHUTE;

	if (SDL_Init(flags)) {
		printf("SDL initialization failed\n");
		return -1;
	}

	/* NOTE: we still want Ctrl-C to work - undo the SDL redirections*/
	signal(SIGINT, SIG_DFL);
	signal(SIGQUIT, SIG_DFL);

	flags = SDL_HWSURFACE|SDL_ASYNCBLIT|SDL_HWACCEL;
	
	screen = SDL_SetVideoMode(cols, rows+8, 8, flags);

	if (!screen) {
		printf("Could not open SDL display\n");
		return -1;
	}

	SDL_WM_SetCaption("tv", "tv");

	return 0;
}

void sdl_update(int h, int v)
{
	if (!screen)
		return;

	SDL_UpdateRect(screen, h, v, 32, 1);
}

void sdl_update_all(void)
{
	if (!screen)
		return;

	SDL_UpdateRect(screen, 0, 0, HH, VV);
}

void sdl_poll(void)
{
	SDL_Event ev1, *ev = &ev1;
	if (screen)
		SDL_PollEvent(ev);
}
	      
main(int argc, char *argv[])
{
	char line[1024];
	unsigned int i, h, v, bits, aoffset, offset, addr, show;
	unsigned char *ps;

	if (argc <= 1)
		sdl_init();

	ps = screen ? screen->pixels : NULL;

	while (fgets(line, sizeof(line), stdin)) {

		if (line[0] == 't' && line[1] == 'v')
			;
		else
			continue;

		if (line[4] == 'w') {
			sscanf(line, "tv: write @%o\n", &addr);
			continue;
		} else {
			sscanf(line, "tv: (%d, %d) <- %o\n",
			       &h, &v, &bits);
		}

		aoffset = addr & 077777;
		fb[aoffset] = bits;

		v = aoffset / (HH/32);
		h = aoffset % (HH/32);
		h *= 32;

		offset = (v * HH) + h;

//		if (bits != 0 && bits != 0xffffffff)
//			show = 1;
//		else {
//			show = 0;
//			continue;
//		}

		if (ps) show = 0; else show = 1;

		if (show) printf("addr=%o, offset=%o v=%o, h=%o bits=%o\n",
				 addr, aoffset, v, h, bits);

		if (!ps)
			continue;

		for (i = 0; i < 32; i++) {
			ps[offset + i] = (bits & 1) ? 0 : 0xff;
			bits >>= 1;
		}

		sdl_update(h, v);
	}

	printf("done!\n");
	sdl_update_all();

	while (screen) {
		sdl_poll();
	}

	exit(0);
}

