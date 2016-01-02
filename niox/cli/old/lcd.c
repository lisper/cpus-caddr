/*
 * lcd.c
 */

#include "diag.h"
#include "lh7a400.h"
#include "eframe.h"

int xres, yres, depth;
int hsync_len, vsync_len;
int right_margin, left_margin;
int upper_margin, lower_margin;
int pcd;

#define VERTICAL_REFRESH	68	/* optimum refresh rate, in Hz. */
#define FB_BASE 0xc5000000

int pixelsPerSecond;
unsigned int pixclock;

int
gpio_mux_lcd(void)
{
	gpioRegs_t *g = (gpioRegs_t *)0x80000e00;

	g->pinmux |= (GPIO_PINMUX_PEOCON | GPIO_PINMUX_PDOCON);
}

int
lcd_disable(void)
{
	CLCDCREGS *lcd = (CLCDCREGS *)0x80003000;
	CLCDICPREGS *lcdicp = (CLCDICPREGS *)0x80001000;

	lcd->control &= ~CLCDC_CTRL_LCDPWR(1);
	lcd->control = 0;
	lcdicp->control = 0;

	return 0;
}


int
lcd_enable_tft(int which)
{
	CLCDCREGS *lcd = (CLCDCREGS *)0x80003000;
	CLCDICPREGS *lcdicp = (CLCDICPREGS *)0x80001000;
	int bpp;

	if (depth == 0)
		depth = 8;

	switch (which) {
	case 1:
		xres = 640;
		yres = 480;

		/* NEC NL6448BC20 */
		right_margin = 16; /* fp */
		hsync_len = 96;
		left_margin = 48;  /* bp */

		lower_margin = 12; /* fp */
		vsync_len = 1;
		upper_margin = 31; /* bp */

		break;
	case 2:
		xres = 800;
		yres = 600;

		hsync_len = 129;
		vsync_len = 2;

		left_margin = 89;
		right_margin = 169;

		upper_margin = 31;
		lower_margin = 23;

		break;
	}


	/* --- */
	pixelsPerSecond =
		(xres + hsync_len + left_margin + right_margin) *
		(yres + vsync_len + upper_margin + lower_margin) *
		VERTICAL_REFRESH;

	pixclock = 1000000000 / (pixelsPerSecond / 1000);
	printf("pixelsPerSecond=%d, pixclock=%d\n",
	       pixelsPerSecond, pixclock);
	/* --- */

	pcd = hclkfreq_get() / 100;
	pcd *= pixclock;
	pcd /= 10000000;
	pcd += 1;	/* make up for integer math truncations */

	printf("pcd %x\n", pcd);

	lcdicp->control = 0;
	lcdicp->setup = CLCDICP_SETUP_CMS(0) | 0xc0;
	lcdicp->timing1 = 0;
	lcdicp->timing2 = 0;

	lcd->timing0 =
		CLCDC_TIM0_HFP(right_margin) +
		CLCDC_TIM0_HBP(left_margin) +
		CLCDC_TIM0_HSW(hsync_len) +
		CLCDC_TIM0_PPL(xres);

	lcd->timing1 =
		CLCDC_TIM1_VBP(upper_margin) +
		CLCDC_TIM1_VFP(lower_margin) +
		CLCDC_TIM1_VSW(vsync_len) +
		CLCDC_TIM1_LPP(yres);

	lcd->timing2 =
	    	CLCDC_TIM2_CPL(xres) |
		CLCDC_TIM2_PCD(pcd);

	lcd->upbase = FB_BASE;
	lcd->overflow = lcd->upbase;
lcd->lpbase = 0;
lcd->overflow = 0;
	lcd->intren = 0;

	switch (depth) {
	case 8: bpp = 3; break;
	case 16: bpp = 4; break;
	case 24: bpp = 5; break;
	}

	/* TFT */

	lcd->control =
		CLCDC_CTRL_BGR(1) |
		CLCDC_CTRL_LCDTFT(1) |
		CLCDC_CTRL_WATERMARK(1) |
		CLCDC_CTRL_LCDBPP(bpp);

	/* gpio */
	gpio_mux_lcd();

	/* cpld */

	lcd->control |= CLCDC_CTRL_LCDPWR(1) | CLCDC_CTRL_LCDEN(1);

	return 0;
}

int
lcd_enable_stn(void)
{
	CLCDCREGS *lcd = (CLCDCREGS *)0x80003000;
	CLCDICPREGS *lcdicp = (CLCDICPREGS *)0x80001000;

	xres = 640;
	yres = 484;

	hsync_len = 129;
hsync_len = 2;
	vsync_len = 2;

	left_margin = 89;
	right_margin = 169;
left_margin = 10;
right_margin = 10;

	upper_margin = 0;
	lower_margin = 0;

	/* --- */
	pixelsPerSecond =
		(xres + hsync_len + left_margin + right_margin) *
		(yres + vsync_len + upper_margin + lower_margin) *
		70 /*VERTICAL_REFRESH*/;

	pixclock = 1000000000 / (pixelsPerSecond / 1000);
	printf("pixelsPerSecond=%d, pixclock=%d\n",
	       pixelsPerSecond, pixclock);
	/* --- */

	printf("hclk %d\n", hclkfreq_get());

	pcd = hclkfreq_get() / 100;
	pcd *= pixclock;
	pcd /= 10000000;
	pcd += 1;	/* make up for integer math truncations */

	printf("pcd %x\n", pcd);

#if 1
	pcd = (3*pcd)/8;
	printf("3/8*pcd %x\n", pcd);
#else
	pcd /= 2;
#endif

	if (pcd <= 0) pcd = 1;

	lcdicp->control = 0;
	lcdicp->setup = CLCDICP_SETUP_CMS(0) | 0xc0;
	lcdicp->timing1 = 0;
	lcdicp->timing2 = 0;

	lcd->timing0 =
		CLCDC_TIM0_HFP(right_margin) |
		CLCDC_TIM0_HBP(left_margin) |
		CLCDC_TIM0_HSW(hsync_len) |
		CLCDC_TIM0_PPL(xres);

	lcd->timing1 =
		CLCDC_TIM1_VBP(upper_margin) |
		CLCDC_TIM1_VFP(lower_margin) |
		CLCDC_TIM1_VSW(vsync_len) |
		CLCDC_TIM1_LPP(yres);

	lcd->timing2 =
	    	CLCDC_TIM2_CPL( (3*xres)/8 ) |
	    	CLCDC_TIM2_ACB(16) |
		CLCDC_TIM2_PCD(pcd);

	lcd->upbase = FB_BASE;
	lcd->overflow = lcd->upbase;
	lcd->intren = 0;

	/* STN */

	lcd->control =
		CLCDC_CTRL_BGR(0) |
		CLCDC_CTRL_WATERMARK(1) |
		CLCDC_CTRL_LCDBPP(3); /* 8bpp */

	/* cpld */

	lcd->control |= CLCDC_CTRL_LCDPWR(1) | CLCDC_CTRL_LCDEN(1);

	return 0;
}

unsigned int pallete[256];

int
lcd_colormap(int which)
{
	u32 *p, *pl;
	int i;

	p = (u32 *)0x80003200;
#define PAL_RGB(r, g, b, i) ( ((i) << 15) | ((b) << 10) | ((g) << 5) | (r) )

	switch (which) {
	case 0:
		for (i = 0; i < 256; i++)
			pallete[i] = PAL_RGB(0,0,0,0) ;
		break;
	case 1:
		for (i = 0; i < 256; i++)
			pallete[i] = PAL_RGB(i>>3,0,0,0);
		break;
	case 2:
		for (i = 0; i < 256; i++)
			pallete[i] = PAL_RGB(0,i>>3,0,0);
		break;
	case 3:
		for (i = 0; i < 256; i++)
			pallete[i] = PAL_RGB(0,0,i>>3,0);
		break;
	case 4:
		for (i = 0; i < 256; i++)
			pallete[i] = PAL_RGB(i>>3,i>>3,i>>3,0);
		break;
	case 5:
		for (i = 0; i < 256; i++) {
			int r, g, b;
			r = ((i&0x07)<<3)&0x1f;
			g = ((i&0x38)<<0)&0x1f;
			b = ((i&0xc0)>>3)&0x1f;
			pallete[i] = PAL_RGB(r,g,b,0);
		}
		break;
	}

	printf("setting lcd color map #%d\n", which);

	printf("palette %4x %4x %4x %4x\n",
	       pallete[0], pallete[1], pallete[2], pallete[3]);
	printf("...     %4x %4x %4x %4x\n",
	       pallete[252], pallete[254], pallete[254], pallete[255]);

	for (i = 0; i < 128; i++)
		p[i] = (pallete[i*2] << 16) | pallete[i*2+1];

	return 0;
}

int
lcd_pattern_8bit(int which)
{
	u32 *p, *pl;
	int i, j, n, c;

	printf("8 bit pattern %d\n", which);

	p = (u32 *)FB_BASE;
	switch (which) {
	case 0:
		pl = p;
		for (i = 0; i < yres; i++)
			for (j = 0; j < xres; j += 4)
				*pl++ = 0;
		break;
	case 1:
		pl = p;
		for (i = 0; i < 100; i++) {
			for (j = 0; j < 100; j++) {
				pl[j] = 0xffffffff;
			}
			pl += xres/4;
		}
		break;
	case 2:
		pl = p;
		c = xres/4;
		for (i = 0; i < yres; i++) {
			int a, b;
			if (i & 128) {
				a = 0;
				b = 0xffffffff;
			} else {
				a = 0xffffffff;
				b = 0;
			}

			for (j = 0; j < c; j += 4)
				*pl++ = a;
			for (j = c; j < c*2; j += 4)
				*pl++ = b;
			for (j = c*2; j < c*3; j += 4)
				*pl++ = a;
			for (j = c*3; j < xres; j += 4)
				*pl++ = b;
		}
		break;
	case 3:
	case 4:
		pl = p;
		c = xres/4;
		for (i = 0; i < yres; i++) {
			for (j = 0; j < c; j += 4)
				*pl++ = 0;
			for (j = c; j < c*2; j += 4)
				*pl++ = 0x20202020;
			for (j = c*2; j < c*3; j += 4)
				*pl++ = 0x80808080;
			for (j = c*3; j < xres; j += 4)
				*pl++ = 0xffffffff;
		}
		break;
	case 5:
		pl = p;
		n = 0;
		for (i = 0; i < yres; i++) {
			for (j = 0; j < xres; j += 4)
				*pl++ = n++;
		}
		break;
	}

	return 0;
}

int
lcd_pattern_16bit(int which)
{
	u16 *p, *ph;
	int i, j, n, c;

	printf("16 bit pattern %d\n", which);

	p = (u16 *)FB_BASE;
	switch (which) {
	case 0:
		ph = p;
		for (i = 0; i < yres; i++)
			for (j = 0; j < xres; j++)
				*ph++ = 0;
		break;
	case 1:
		ph = p;
		for (i = 0; i < 100; i++) {
			for (j = 0; j < 100; j++) {
				ph[j] = PAL_RGB(31,31,31,0);
			}
			ph += xres;
		}
		break;
	case 2:
		ph = p;
		c = xres/4;
		for (i = 0; i < yres; i++) {
			int a, b;
			if (i & 128) {
				a = 0;
				b = PAL_RGB(31,31,31,0);
			} else {
				a = PAL_RGB(31,31,31,0);
				b = 0;
			}

			for (j = 0; j < c; j++)
				*ph++ = a;
			for (j = c; j < c*2; j++)
				*ph++ = b;
			for (j = c*2; j < c*3; j++)
				*ph++ = a;
			for (j = c*3; j < xres; j++)
				*ph++ = b;
		}
		break;
	case 3:
		ph = p;
		c = xres/4;
		for (i = 0; i < yres; i++) {
			for (j = 0; j < c; j++)
				*ph++ = PAL_RGB(0,0,0,0);
			for (j = c; j < c*2; j++)
				*ph++ = PAL_RGB(10,10,10,0);
			for (j = c*2; j < c*3; j++)
				*ph++ = PAL_RGB(20,20,20,0);
			for (j = c*3; j < xres; j++)
				*ph++ = PAL_RGB(31,31,31,0);
		}
		break;
	case 4:
		ph = p;
		c = xres/4;
		for (i = 0; i < yres; i++) {
			for (j = 0; j < c; j++)
				*ph++ = PAL_RGB(31,0,0,0);
			for (j = c; j < c*2; j++)
				*ph++ = PAL_RGB(0,31,0,0);
			for (j = c*2; j < c*3; j++)
				*ph++ = PAL_RGB(0,0,31,0);
			for (j = c*3; j < xres; j++)
				*ph++ = PAL_RGB(31,31,31,0);
		}
		break;
	case 5:
		ph = p;
		n = 0;
		for (i = 0; i < yres; i++) {
			for (j = 0; j < xres; j++)
				*ph++ = n++;
		}
		break;
	}

	return 0;
}

int
lcd_pattern_24bit(int which)
{
	printf("24 bit pattern %d\n", which);

	return 0;
}

int
lcd_pattern(int which)
{
	switch (depth) {
	case 8:
		return lcd_pattern_8bit(which);
	case 16:
		return lcd_pattern_16bit(which);
	case 24:
		return lcd_pattern_24bit(which);
	}
	return -1;
}

int
lcd_depth(int deep)
{
	switch (deep) {
	case 8:
	case 16:
	case 24:
		depth = deep;
		break;
	}

	printf("lcd depth %d\n", depth);
	return 0;
}
