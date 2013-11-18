
#include <stdio.h>
#include <stdlib.h>
#include <signal.h>

#include <SDL/SDL.h>

typedef unsigned int u32;

#define HH 768
#define VV 896
u32 fb[32768/*(HH/32)*VV*/];

static SDL_Surface *screen;

int debug;

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
	int do_window, do_set, do_full, do_show, do_vram, do_tv, do_extract;

	do_window = 1;
	do_set = 1;
	do_full = 1;
	do_show = 0;
	do_vram = 0;
	do_tv = 1;
	do_extract = 0;

	for (i = 1; i < argc; i++) {
		if (argv[i][0] == '-')
			switch (argv[i][1]) {
			case 'n': do_window = 0; break;
			case 'f': do_full = 0; break;
			case 's': do_show = 1; break;
			case 'v': do_vram = 1; do_tv = 0; break;
			case 'x': do_set = 0; break;
			case 'e': do_extract = 1; do_tv = 0; break;
			case 'd': debug++; break;
			}
	}

	if (do_window)
		sdl_init();

	ps = screen ? screen->pixels : NULL;

	while (fgets(line, sizeof(line), stdin)) {

		if (do_show)
			printf("%s", line);

		if (do_vram) {
			if (line[0] == 'v' && line[1] == 'r' && line[2] == 'a')
				;
			else
				continue;

			if (line[6] == 'W') {
				sscanf(line, "vram: W addr %o <- %o;",
				       &addr, &bits);
			} else
				continue;
		}

		if (do_tv) {
			if (line[0] == 't' && line[1] == 'v')
				;
			else
				continue;

			if (debug) printf("%s", line);

			if (line[4] == 'r')
				continue;

			if (line[4] == 'w') {
				sscanf(line, "tv: write @%o <- %o\n",
				       &addr, &bits);
				continue;
			} else {
				sscanf(line, "tv: (%d, %d) <- %o\n",
				       &h, &v, &bits);
			}
		}

		if (do_extract) {
			sscanf(line, "%o %o", &addr, &bits);
		}

		aoffset = addr & 077777;
		fb[aoffset] = bits;

		v = aoffset / (HH/32);
		h = aoffset % (HH/32);
		h *= 32;

		offset = (v * HH) + h;

		/* only look at writes which have some bits set */
		if (!do_full) {
			if (bits != 0 && bits != 0xffffffff)
				show = 1;
			else {
				show = 0;
				continue;
			}
		}

		if (do_show) show = 1;

		if (show) {
			printf("addr=%o, offset=%o v=%o, h=%o bits=%o\n",
			       addr, aoffset, v, h, bits);
			//printf("line: %s\n", line);
		}

		if (!ps)
			continue;
		
		for (i = 0; i < 32; i++) {
			if (do_set)
				ps[offset + i] = (bits & 1) ? 0xff : 0;
//				ps[offset + i] = (bits & 1) ? 0x0 : 0xff;
//				ps[offset + i] ^= (bits & 1) ? 0x0 : 0xff;
			else
				ps[offset + i] += (bits & 1) ? 1 : 2;

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

