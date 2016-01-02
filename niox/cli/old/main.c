/*
 * main.c
 *
 * $Id: main.c,v 1.3 2005/03/10 14:07:05 brad Exp $
 */

#include "serial-lh7a400.h"
#include "lh7a400.h"
#include "diag.h"
#include "eframe.h"

SMCREGS *smc;
int ttynum;

#if 0
#define BCR0 (SMC_BCR_MW16|SMC_BCR_WST2(9) |SMC_BCR_WST1(17)|SMC_BCR_IDCY(9))
#else
#define BCR0 (SMC_BCR_MW16|SMC_BCR_WST2(32) |SMC_BCR_WST1(32)|SMC_BCR_IDCY(0))
#endif

//#define BCR2 (SMC_BCR_MW16|SMC_BCR_WST2(12)|SMC_BCR_WST1(12)|SMC_BCR_IDCY(6))
//#define BCR2 (SMC_BCR_MW16|SMC_BCR_WST2(32)|SMC_BCR_WST1(32)|SMC_BCR_IDCY(6))
#define BCR2 (SMC_BCR_MW32|SMC_BCR_WST2(32)|SMC_BCR_WST1(32)|SMC_BCR_IDCY(6))

//#define BCR3 (SMC_BCR_MW16|SMC_BCR_WST2(32)|SMC_BCR_WST1(32)|SMC_BCR_IDCY(0))
//#define BCR3 (SMC_BCR_MW32|SMC_BCR_WST2(32)|SMC_BCR_WST1(32)|SMC_BCR_IDCY(0))
#define BCR3 (SMC_BCR_MW32|SMC_BCR_WST2(32)|SMC_BCR_WST1(32)|SMC_BCR_IDCY(16))

#define BCR6 (SMC_BCR_MW32|SMC_BCR_WST2(32)|SMC_BCR_WST1(32)|SMC_BCR_IDCY(16))
#define BCR7 (SMC_BCR_MW32|SMC_BCR_WST2(32)|SMC_BCR_WST1(32)|SMC_BCR_IDCY(0)) 

void
setup_csx(void)
{
	smc = (SMCREGS *)0x80002000;

	xprintf("setup BCR's\n");
	/* bank 0 nCS0	0x00000000 Flash */
	smc->bcr0 = BCR0;

	/* bank 2 nCS2	0x20000000 CF */
	smc->bcr2 = BCR2;

	/* bank 3 nCS3	0x30000000 CPLD */
	smc->bcr3 = BCR3;

	/* bank 6 nCS6	0x60000000 expbrd ethernet */
	smc->bcr6 = BCR6;
	
	/* bank 7 nCS7	0x70000000 expbrd control register */
	smc->bcr7 = BCR7;
}

unsigned long expbrd_reg;

u32
get_expbrd_reg(void)
{
	return expbrd_reg;
}

void
set_expbrd_reg(u32 reg)
{
	volatile u32 *lp = (volatile u32 *)0x70000000;
	expbrd_reg = reg;
	*lp = expbrd_reg;
}

void
set_expbrd_7seg(int what)
{
	u32 reg;

	reg = (get_expbrd_reg() & 0xff00) | (what & 0x00ff);

	set_expbrd_reg(reg);
}

static unsigned char dig_map[] =
{ 0x40, 0xf9, 0xa4, 0x30, 0x19, 0x12, 0x02, 0xf8, 0x00, 0x18, 0xff };

void
set_expbrd_7seg_dig(int dig)
{
	set_expbrd_7seg(dig_map[dig]);
}

void
clear_bss(void)
{
	u_char *p;
	extern u_char __bss_start__, __bss_end__;

	for (p = &__bss_start__; p < &__bss_end__;)
		*p++ = 0;
}


#define TTY1

main()
{
	clear_bss();

        ttynum = 1;
	serial_set(ttynum);
	serial_init(baud_9600);

	puts("\nhello!\n");
	puts("diag 0.2 ");
	puts(__DATE__);
	puts("\n");

	setup_csx();

	cli_init();
	set_expbrd_7seg_dig(ttynum);

	cli();

	while (1);
}


/*
 * Local Variables:
 * indent-tabs-mode:nil
 * c-basic-offset:4
 * End:
*/
