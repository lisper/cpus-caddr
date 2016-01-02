/*
 * cpld.c
 */

#include "types.h"
#include "diag.h"
#include "eframe.h"
#include "lh7a400.h"

unsigned long expbrd_reg;

u32
get_cpld_ctrl_reg(void)
{
	volatile u32 *cr = (volatile u32 *)CPLD_RESET_CTRL_BITS;
	return *cr;
}

u32
reset_cpld_ctrl_reg(int v)
{
	volatile u32 *cr = (volatile u32 *)CPLD_RESET_CTRL_BITS;
	*cr = v;
}

u32
set_cpld_ctrl_reg(int v)
{
	volatile u32 *cr = (volatile u32 *)CPLD_SET_CTRL_BITS;
	*cr = v;
}

/* --- */

int
get_cpld_int_reg(void)
{
	volatile u32 *cr = (volatile u32 *)CPLD_RESET_INT_BITS;
	return *cr;
}

u32
reset_cpld_int_reg(int v)
{
	volatile u32 *cr = (volatile u32 *)CPLD_RESET_INT_BITS;
	*cr = v;
}

u32
set_cpld_int_reg(int v)
{
	volatile u32 *cr = (volatile u32 *)CPLD_SET_INT_BITS;
	*cr = v;
}

/* --- */

int
get_cpld_ack_reg(void)
{
	volatile u32 *cr = (volatile u32 *)CPLD_RESET_ACK_BITS;
	return *cr;
}

u32
set_cpld_ack_reg(int v)
{
	volatile u32 *cr = (volatile u32 *)CPLD_SET_ACK_BITS;
	*cr = v;
}

u32
reset_cpld_ack_reg(int v)
{
	volatile u32 *cr = (volatile u32 *)CPLD_RESET_ACK_BITS;
	*cr = v;
}

/* -- */

void
set_cpld_ctrl_reg_bit(int bit)
{
	volatile u32 *cr = (volatile u32 *)CPLD_SET_CTRL_BITS;
	*cr = 1 << bit;
}

void
reset_cpld_ctrl_reg_bit(int bit)
{
	volatile u32 *cr = (volatile u32 *)CPLD_RESET_CTRL_BITS;
	*cr = 1 << bit;
}

void
set_cpld_int_reg_bit(int bit)
{
	volatile u32 *cr = (volatile u32 *)CPLD_SET_INT_BITS;
	*cr = 1 << bit;
}

void
reset_cpld_int_reg_bit(int bit)
{
	volatile u32 *cr = (volatile u32 *)CPLD_RESET_INT_BITS;
	*cr = 1 << bit;
}

void
reset_cpld_ack_reg_bit(int bit)
{
	volatile u32 *cr = (volatile u32 *)CPLD_RESET_ACK_BITS;
	*cr = 1 << bit;
}

void
set_cpld_ack_reg_bit(int bit)
{
	volatile u32 *cr = (volatile u32 *)CPLD_SET_ACK_BITS;
	*cr = 1 << bit;
}



void
show_cpld_bits(void)
{
	u32 v = get_cpld_ctrl_reg();
	int p;

	printf("cpld: (%8x) ", v);

	/* high byte of cpld reg read */
	if (v & CPLD_CTRL_FLASH_READY) printf("flash-ready ");
	if (v & CPLD_CTRL_CF_CD) printf("cf-cd ");
	if (v & CPLD_CTRL_CF_WAIT) printf("cf-wait ");
	if (v & CPLD_CTRL_MMC_CD) printf("mmc-cd ");
	if (v & CPLD_CTRL_MMC_WP) printf("mmc-wp ");
	if (v & CPLD_CTRL_EXP_INT_1) printf("exp-int-1 ");
	if (v & CPLD_CTRL_EXP_INT_2) printf("exp-int-2 ");
	if (v & CPLD_CTRL_EXP_INT_3) printf("exp-int-3 ");

	/* low byte */
	if (v & (1 << CPLD_CTRL_LCDPWR_BIT)) printf("lp+ ");
	if (v & (1 << CPLD_CTRL_BACKLIGHT_BIT)) printf("bl+ ");
	if (v & (1 << CPLD_CTRL_LCD_OE_BIT)) printf("lo+ ");

	p = (v >> CPLD_CTRL_PCMCIA_PWR1_BIT) & 0x03;
	switch (p) {
	case 0: printf("pcmcia=0v "); break;
	case 1: printf("pcmcia=5v "); break;
	case 2: printf("pcmcia=3.3v "); break;
	case 3: printf("pcmcia=?v "); break;
	}

	if (v & (1 << CPLD_CTRL_CF_RESET_BIT)) printf("cr+ ");

	printf("\n");
}

int
cmd_tcpld(int argc, char *argv[])
{
	int i;
	u32 v, c;

	printf("testing CPLD registers\n");

	printf("CTRL: reset all\n");
	for (i = 0; i < 8; i++)
		reset_cpld_ctrl_reg_bit(i);

	printf("get ctrl %08x\n", get_cpld_ctrl_reg());

	printf("set ctrl one at a time\n");
	c = 0;
	for (i = 0; i < 8; i++) {
		set_cpld_ctrl_reg_bit(i);
		v = get_cpld_ctrl_reg() & 0xff;
		c = 1 << i;
		printf("set #%d -> %04x ", i, v);
		if (c != v) printf("FAILED\n");
		else printf("ok\n");
		reset_cpld_ctrl_reg_bit(i);
	}

	printf("set ctrl one by one\n");
	c = 0;
	for (i = 0; i < 8; i++) {
		set_cpld_ctrl_reg_bit(i);
		v = get_cpld_ctrl_reg() & 0xff;
		c |= 1 << i;
		printf("set #%d -> %04x ", i, v);
		if (c != v) printf("FAILED\n");
		else printf("ok\n");
	}

	printf("clear ctrl one by one\n");
	c = 0xff;
	for (i = 0; i < 8; i++) {
		reset_cpld_ctrl_reg_bit(i);
		v = get_cpld_ctrl_reg() & 0xff;
		c &= ~(1 << i);
		printf("reset #%d -> %04x ", i, v);
		if (c != v) printf("FAILED\n");
		else printf("ok\n");
	}

	printf("clear all\n");
	for (i = 0; i < 8; i++)
		reset_cpld_ctrl_reg_bit(i);
	v = get_cpld_ctrl_reg() & 0xff;
	printf("cleared %04x ", v);
	if (v != 0) printf("FAILED\n");
	else printf("ok\n");

	printf("set all\n");
	for (i = 0; i < 8; i++)
		set_cpld_ctrl_reg_bit(i);

	v = get_cpld_ctrl_reg() & 0xff;
	printf("set %08x ", v);
	if (v != 0xff) printf("FAILED\n");
	else printf("ok\n");

	/* reset to zero */
	reset_cpld_ctrl_reg(0xff);
	printf("CTRL: done\n");

/* ---- */

	printf("ACK: reset all\n");
	for (i = 0; i < 8; i++)
		reset_cpld_ack_reg_bit(i);

	printf("get ack %08x\n", get_cpld_ack_reg());

	printf("set ack one at a time\n");
	c = 0;
	for (i = 0; i < 8; i++) {
		set_cpld_ack_reg_bit(i);
		v = get_cpld_ack_reg() & 0xff;
		c = 1 << i;
		printf("set #%d -> %08x ", i, v);
		if (c != v) printf("FAILED\n");
		else printf("ok\n");
		reset_cpld_ack_reg_bit(i);
	}

	printf("clear ack one by one\n");
	c = 0x7f;
	set_cpld_ack_reg(0xff);
	for (i = 0; i < 8; i++) {
		reset_cpld_ack_reg_bit(i);
		v = get_cpld_ack_reg() & 0xff;
		c &= ~(1 << i);
		printf("reset #%d -> %08x ", i, v);
		if (c != v) printf("FAILED\n");
		else printf("ok\n");
	}

	/* reset to zero */
	reset_cpld_ack_reg(0xff);
	printf("ACK: done\n");

	return 0;
}

int
cmd_tcpld_int(int argc, char *argv[])
{
	gpioRegs_t *gpio = (gpioRegs_t *)0x80000e00;
	int i;
	u32 v, c;

	printf("testing CPLD interrupt\n");

#define GPIO_F1_BIT	(1<<1)

	gpio->gpiointen = 0;
	gpio->inttype1 = GPIO_F1_BIT;	/* edge triggered */
	gpio->inttype2 = 0;
	gpio->gpiofeoi = GPIO_F1_BIT;	/* clear all interrupts */

	printf("pfddr %08x\n", gpio->pfddr);
	/* set all input */
	gpio->pfddr = 0;

	printf("pfdr %08x, pfpindr %08x\n", gpio->pfdr, gpio->pfpindr);

	printf("reset cpld ints\n");
	reset_cpld_int_reg(0xff);
	reset_cpld_ack_reg(0xff);
	printf("pfdr %08x, pfpindr %08x\n", gpio->pfdr, gpio->pfpindr);

	printf("set cpld int\n");
//	set_cpld_ack_reg(0x01);
	set_cpld_ack_reg_bit(0);
	printf("ack reg %04x\n", get_cpld_ack_reg());
	printf("pfdr %08x, pfpindr %08x\n", gpio->pfdr, gpio->pfpindr);

	printf("enable cpld int\n");
//	set_cpld_int_reg(0x01);
	set_cpld_int_reg_bit(0);
	printf("pfdr %08x, pfpindr %08x\n", gpio->pfdr, gpio->pfpindr);
	if (gpio->pfpindr & GPIO_F1_BIT) printf("ok\n");
	else printf("FAILED\n");

	printf("ack cpld int\n");
	reset_cpld_ack_reg_bit(0);	
	printf("pfdr %08x, pfpindr %08x\n", gpio->pfdr, gpio->pfpindr);
	if (gpio->pfpindr & GPIO_F1_BIT) printf("FAILED\n");
	else printf("ok\n");

	return 0;
}

int
show_cpld_ints(void)
{
	u32 v1, v2;

	v1 = get_cpld_int_reg();
	v2 = get_cpld_ack_reg();

	printf("int reg %4x\n", v1);
	if (v1 & CPLD_INT_CF_CD) printf("CF-cd ");
	if (v1 & CPLD_INT_PCMCIA_CD) printf("PCMCIA-cd ");
	if (v1 & CPLD_INT_MMC_CD) printf("MMC-cd ");
	if (v1 & CPLD_INT_CF_INT) printf("CF-int ");
	if (v1 & CPLD_INT_EXT_INT_1) printf("EXT-1 ");

	printf("ack reg %4x\n", v2);

	return 0;
}

int
cmd_cpld(int argc, char *argv[])
{
	if (argc < 2) {
		printf("usage: cpld "
		       "{ lp+ | lp- | bl+ | bl- | lo+ | lo- | p0 | p1 | p2 | p3 | cr+ | cr- }\n");
		return -1;
	}

	if (strcmp(argv[1], "lp+") == 0)
		set_cpld_ctrl_reg_bit(CPLD_CTRL_LCDPWR_BIT);
	if (strcmp(argv[1], "lp-") == 0)
		reset_cpld_ctrl_reg_bit(CPLD_CTRL_LCDPWR_BIT);

	if (strcmp(argv[1], "bl+") == 0)
		set_cpld_ctrl_reg_bit(CPLD_CTRL_BACKLIGHT_BIT);
	if (strcmp(argv[1], "bl-") == 0)
		reset_cpld_ctrl_reg_bit(CPLD_CTRL_BACKLIGHT_BIT);

	if (strcmp(argv[1], "lo+") == 0)
		set_cpld_ctrl_reg_bit(CPLD_CTRL_LCD_OE_BIT);
	if (strcmp(argv[1], "lo-") == 0)
		reset_cpld_ctrl_reg_bit(CPLD_CTRL_LCD_OE_BIT);

	if (strcmp(argv[1], "p0") == 0) {
		reset_cpld_ctrl_reg_bit(CPLD_CTRL_PCMCIA_PWR1_BIT);
		reset_cpld_ctrl_reg_bit(CPLD_CTRL_PCMCIA_PWR2_BIT);
		printf("power off\n");
	}
	if (strcmp(argv[1], "p1") == 0) {
		reset_cpld_ctrl_reg_bit(CPLD_CTRL_PCMCIA_PWR2_BIT);
		set_cpld_ctrl_reg_bit(CPLD_CTRL_PCMCIA_PWR1_BIT);
		printf("power +5v\n");
	}
	if (strcmp(argv[1], "p2") == 0) {
		reset_cpld_ctrl_reg_bit(CPLD_CTRL_PCMCIA_PWR1_BIT);
		set_cpld_ctrl_reg_bit(CPLD_CTRL_PCMCIA_PWR2_BIT);
		printf("power +3.3v\n");
	}
	if (strcmp(argv[1], "p3") == 0) {
		set_cpld_ctrl_reg_bit(CPLD_CTRL_PCMCIA_PWR1_BIT);
		set_cpld_ctrl_reg_bit(CPLD_CTRL_PCMCIA_PWR2_BIT);
	}

	if (strcmp(argv[1], "cr+") == 0)
		set_cpld_ctrl_reg_bit(CPLD_CTRL_CF_RESET_BIT);
	if (strcmp(argv[1], "cr-") == 0)
		reset_cpld_ctrl_reg_bit(CPLD_CTRL_CF_RESET_BIT);

	if (strcmp(argv[1], "ie") == 0) {
		set_cpld_int_reg(0xff);
	}

	if (strcmp(argv[1], "ia") == 0) {
		reset_cpld_ack_reg(0xff);
	}

	show_cpld_bits();
	show_cpld_ints();

	return 0;
}

