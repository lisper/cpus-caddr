
#include "diag.h"
#include "font8x8_basic.h"

/*static*/ int tv_h, tv_v;

#define FRAME_BUFFER	0xf00000

#define TV_H_MIN	0
#define TV_V_MIN	0

#define TV_H_STRIDE	768
#define TV_V_LINES	896

#define TV_H_MAX	(TV_H_STRIDE)
#define TV_V_MAX	(TV_V_LINES)

#define TV_H_BITS_PW	(32)
#define TV_H_WORDS	(TV_H_STRIDE / TV_H_BITS_PW)

#define TV_H_STEP	8
#define TV_V_STEP	8

void tv_blob(void)
{
	vu32 *pfb;
	int h;
	pfb = (vu32 *)FRAME_BUFFER;
	h = 0;

	pfb[h] = 0xff; h += TV_H_WORDS;
	pfb[h] = 0xff; h += TV_H_WORDS;
	pfb[h] = 0xff; h += TV_H_WORDS;
	pfb[h] = 0xff; h += TV_H_WORDS;
	pfb[h] = 0xff; h += TV_H_WORDS;
	pfb[h] = 0xff; h += TV_H_WORDS;
	pfb[h] = 0xff; h += TV_H_WORDS;
	pfb[h] = 0xff; h += TV_H_WORDS;
	pfb[h] = 0xff; h += TV_H_WORDS;
}

void tv_clear(void)
{
	vu32 *pfb;
	int h, v;
	pfb = (vu32 *)FRAME_BUFFER;
	for (v = 0; v <TV_V_MAX; v++)
		for (h = 0; h < TV_H_WORDS; h++)
			*pfb++ = 0;
}

void tv_init(void)
{
	tv_h = TV_H_MIN;
	tv_v = TV_V_MIN;
	tv_clear();
}

void tv_render(int h, int v, char ch)
{
	char *p;
	vu32 *pfb;
	int i, offset, shift;
	u32 mask, bits;

	if (ch > 0x7f)
		return;

	p = &font8x8_basic[ch][0];

	/*
	  off  %
	  0    0
	  8    8
	  16   16
	  24   24
	  32   0 
	*/

	offset = (v * TV_H_WORDS) + (h / TV_H_BITS_PW);
	shift = h % TV_H_BITS_PW;
	mask = 0xff << shift;

	pfb = ((vu32 *)FRAME_BUFFER) + offset;

	for (i = 0; i < 8; i++) {
		bits = *p++ << shift;
		*pfb = (*pfb & ~mask) | bits;
		pfb += TV_H_WORDS;
	}
}

void tv_scroll(int vc)
{
	vu32 *pfb_f, *pfb_t;
	int h, v;

	pfb_f = (vu32 *)FRAME_BUFFER;
	pfb_t = pfb_f;

	/* start = base + vc*TV_V_STEP */
	pfb_f += TV_H_WORDS * TV_V_STEP * vc;

	/* scroll up vc lines */
	for (v = vc*TV_V_STEP; v < TV_V_MAX; v++) {
		for (h = 0; h < TV_H_WORDS; h++)
			*(pfb_t + h) = *(pfb_f + h);

		pfb_f += TV_H_WORDS;
		pfb_t += TV_H_WORDS;
	}

	/* clear bottom */
	for (v = 0; v < vc*TV_V_STEP; v++) {
		for (h = 0; h < TV_H_WORDS; h++)
			*(pfb_t + h) = 0;
		pfb_t += TV_H_WORDS;
	}
}

void tv_advance(int hc, int vc)
{
	if (hc > 0) {
		tv_h += TV_H_STEP*hc;
	}
	if (hc == -1) {
		if (tv_h > TV_H_MIN)
			tv_h -= TV_H_STEP;
	}
	if (hc == -2) {
		tv_h = TV_H_MIN;
	}

	if (vc > 0) {
		tv_v += TV_V_STEP*vc;
		if (tv_v >= TV_V_MAX) {
			tv_scroll(1);
			tv_v = TV_V_MAX - TV_V_STEP;
		}
	}
	if (vc < 0) {
		tv_v = TV_V_MIN;
	}
}

int next_tabstop(int col)
{
	int stop;

	//9;17;25;33;41;49;57;65;73;81
	stop = ( (col/8)+1 )*8+1;
	return stop;
}

void tv_write(char ch)
{
	if (ch >= ' ' && ch <= '~') {
		tv_render(tv_h, tv_v, ch);
		tv_advance(1, 0);
	} else {
		int col, tab;
		switch (ch) {
		case '\t':
			col = tv_h / TV_H_STEP;
			tab = next_tabstop(col);
			tv_advance(tab - col, 0);
			break;
		case '\r':
			tv_advance(-2, 0);
			break;
		case '\n':
			tv_advance(0, 1);
			break;
		case '\b':
			tv_advance(-1, 0);
			break;
		}
	}
}
