/*
 * testing.c
 */

#include "diag.h"
#include "lh7a400.h"
#include "eframe.h"
//#include "cs8900.h"

void setup_cpld(void) {}
void setup_cf(void) {}
void setup_pcmcia(void) {}
void setup_lcd(void) {}

void test_cpld(void) {}
void test_cf(void) {}
void test_pcmcia(void) {}
void test_lcd(void) {}

void setup_ac97(void) {}
void setup_ethernet(void) {}
void setup_serial(void) {}
void setup_mmc(void) {}
void setup_ir(void) {}
void setup_usb(void) {}

void test_ac97(void) {}
void test_ethernet(void) {}
void test_serial(void) {}
void test_mmc(void) {}
void test_ir(void) {}
void test_usb(void) {}

void
test_eframe()
{
	setup_cpld();
	setup_cf();
	setup_pcmcia();
	setup_lcd();

	test_cpld();
	test_cf();
	test_pcmcia();
	test_lcd();
}

void
test_expbrd()
{
	setup_ac97();
	setup_ethernet();
	setup_serial();
	setup_mmc();
	setup_ir();
	setup_usb();

	test_ac97();
	test_ethernet();
	test_serial();
	test_mmc();
	test_ir();
	test_usb();
}


int
delayus(void)
{
	volatile unsigned long l;

	for (l = 0; l < /*10000*/1; l++)
		;
}

int
delayms(int ms)
{
	int i;

	for (i = 0; i < 1000*ms; i++)
		/*delayus()*/;
}

int clksets[] = {
	CLKSET_50_50_25,	 /* 0 */
	CLKSET_66_66_33,	 /* 1 */
	CLKSET_100_50_25,	 /* 2 */
	CLKSET_150_75_37,	 /* 3 */
	CLKSET_200_50_25,	 /* 4 */
	CLKSET_200_67_33,	 /* 5 */
	CLKSET_200_100_50	 /* 6 */
};

int
enable_dmaclock(void)
{
    cscRegs_t *csc = (cscRegs_t *)0x80000400;
    csc->pwrcnt |= 0x03ff0000;
    printf("PWRCNT %x\n", csc->pwrcnt);
    return 0;
}

int
disable_dmaclock(void)
{
    cscRegs_t *csc = (cscRegs_t *)0x80000400;
    csc->pwrcnt &= ~0x03ff0000;
    printf("PWRCNT %x\n", csc->pwrcnt);
    return 0;
}


int
enable_pgmclock(void)
{
    cscRegs_t *csc = (cscRegs_t *)0x80000400;
    /* enable PGMCLK at max speed */
    csc->pwrcnt = (csc->pwrcnt & PWRCNT_PGMCLK(255)) | PWRCNT_PGMCLK(1);
    return 0;
}

int
disable_pgmclock(void)
{
    cscRegs_t *csc = (cscRegs_t *)0x80000400;
    csc->pwrcnt &= PWRCNT_PGMCLK(255);
    return 0;
}

int
cmd_cclock(int argc, char *argv[])
{
	cscRegs_t *csc = (cscRegs_t *)0x80000400;
	u32 set;

	if (argc > 2 || (argc == 2 && argv[1][0] == '-')) {
		printf("usage: clock { slow | fast | ext | 0-6 }\n");
		return -1;
	}

	set = 0;

	if (argc > 1 && strcmp(argv[1], "ext") == 0) {
            	enable_pgmclock();
	}

	if (argc > 1 && strcmp(argv[1], "ext-") == 0) {
            disable_pgmclock();
	}

	if (argc > 1 && strcmp(argv[1], "dma") == 0) {
            enable_dmaclock();
	}

	if (argc > 1 && strcmp(argv[1], "dma-") == 0) {
            disable_dmaclock();
	}

	if (argc > 1 && strcmp(argv[1], "slow") == 0)
		set = CLKSET_50_50_25;

	if (argc > 1 && strcmp(argv[1], "fast") == 0)
		set = CLKSET_200_100_50;

	if (argc > 1 && ('0' <= argv[1][0] && argv[1][0] <= '9')) {
		int n = argv[1][0] - '0';
		set = clksets[n];
		printf("setting clock to #%d = %8x\n", n, set);
	}


	if (set) {
		printf("setting clkset %8x\n", set);
		delayms(10);
		csc->clkset = set;
		asm volatile("nop; nop; nop; nop");
	}

	printf("clkset %8x (slow=%8x, fast=%8x)\n",
	       csc->clkset, CLKSET_50_50_25, CLKSET_200_100_50);

	return 0;
}

int
cmd_tled(int argc, char *argv[])
{
	int i;

	for (i = 0; i < 10; i++) {
		set_expbrd_7seg_dig(i);
		delayms(100);
	}
}

int
cmd_expbrd(int argc, char *argv[])
{
	int i;
	u32 reg;

	if (argc < 2) {
		printf("usage: expbrd "
		       "{ a+ | a- | u+ | u- | r3+ | d3+ | r2+ | d2+ }\n");
		return -1;
	}

	reg = get_expbrd_reg();
	for (i = 1; i < argc; i++) {
		if (strcmp(argv[i], "a+") == 0)
			reg |= EXB_REG_AC96_PWR_EN;
		if (strcmp(argv[i], "a-") == 0)
			reg &= ~EXB_REG_AC96_PWR_EN;

		if (strcmp(argv[i], "u+") == 0)
		    reg |= EXB_REG_USB_PULLUP;
		if (strcmp(argv[i], "u-") == 0)
		    reg &= ~EXB_REG_USB_PULLUP;

		if (strcmp(argv[i], "r3+") == 0)
		    reg |= EXB_REG_RTS3;
		if (strcmp(argv[i], "r3-") == 0)
		    reg &= ~EXB_REG_RTS3;

		if (strcmp(argv[i], "d3+") == 0)
		    reg |= EXB_REG_DTR3;
		if (strcmp(argv[i], "d3-") == 0)
		    reg &= ~EXB_REG_DTR3;

		if (strcmp(argv[i], "r2+") == 0)
		    reg |= EXB_REG_RTS2;
		if (strcmp(argv[i], "r2-") == 0)
		    reg &= ~EXB_REG_RTS2;

		if (strcmp(argv[i], "d2+") == 0)
		    reg |= EXB_REG_DTR2;
		if (strcmp(argv[i], "d2-") == 0)
		    reg &= ~EXB_REG_DTR2;
	}


	printf("setting expbrd reg %8x\n", reg);
	set_expbrd_reg(reg);

	return 0;
}

#define DEBUG

#define cs_port_t volatile u32

cs_port_t * const cs8900_port_addr[8] = {
	(cs_port_t *)0x60000000, (cs_port_t *)0x60000004,
	(cs_port_t *)0x60000008, (cs_port_t *)0x6000000C,
	(cs_port_t *)0x60000010, (cs_port_t *)0x60000014,
	(cs_port_t *)0x60000018, (cs_port_t *)0x6000001C
};

/*
 * Typedefs
 */
// List of read ports
typedef enum {rxd0, rxd1, unused_r1, unused_r2, isq, ppptr, pd0, pd1}
	rx_port_t;

// List of write ports - ppptr, pd0, and pd1 are shared with read enums
typedef enum {txd0, txd1, txcmd, txlen, unused_t1}
	tx_port_t;

#define CS8900_CHIP_ID	0x630e

/*
 * Set the PP pointer register and optionally enable the autoincrement function
 */
static void
cs8900_set_pp_addr(u16 addr, int autoinc)
{
   /* Set autoincrement bit in PacketPage pointer value */
   if( autoinc) {
      addr |= 0x8000;
   }

#ifdef DEBUG
   printf( "Setting ppptr address @%8x to 0x%8x (%d)\n",
	   cs8900_port_addr[ppptr], (int) addr, autoinc);
#endif

   *(cs8900_port_addr[ppptr]) = addr;
}

/*
 *	Read data from the current PP register address.
 */
static u16 cs8900_read_pp_data(void)
{
#ifdef DEBUG
   u16 data;

   data = *(cs8900_port_addr[pd0]);
   printf("Data read from port @%8x = %x\n",
	  cs8900_port_addr[pd0], (int)data);
   return data;
#else
   return (*cs8900_port_addr[pd0]);
#endif

}

static void cs8900_write_pp_data(u16 data)
{
    *(cs8900_port_addr[pd0]) = data;
}

//static cs8900_pp_t *cs8900_pp_data = (void *) 0x0;

int
cmd_cs89(int argc, char *argv[])
{
	u16 volatile temp;

#if 0
	{
		volatile u32 *p1 = (volatile u32 *)0x60000014;
		volatile u32 *p2 = (volatile u32 *)0x60000018;
		while (1) {
			volatile u32 v;
			*p1 = 0;
delayus();
			v = *p2;

			*p1 = 0;
			v = *p2;
		}
	}
#endif

#if 0
	{
		volatile u32 *p1 = (volatile u32 *)0x60000014;
		volatile u32 *p2 = (volatile u32 *)0x60000018;
		int i;
		for (i = 0; i < 8; i++) {
			volatile u32 v;
			*p1 = 0;
			v = *p2;
			printf("[%d]=%x\n", i, v);
		}
	}
#endif

#if 1
	{
		volatile u32 *p1 = (volatile u32 *)0x60000014;
		volatile u32 *p2 = (volatile u32 *)0x60000018;
		volatile u32 *p3 = (volatile u32 *)0x30000000;
                volatile u32 v, a;

                a = 0;
                *p1 = a;
                v = *p2;
                printf("[%d]=%x\n", a, v);
v = *p3;

                a = 0x20;
                *p1 = a;
                v = *p2;
                printf("[%d]=%x\n", a, v);
v = *p3;

                a = 0x22;
                *p1 = a;
                v = *p2;
                printf("[%d]=%x\n", a, v);
v = *p3;
                a = 0x24;
                *p1 = a;
                v = *p2;
                printf("[%d]=%x\n", a, v);
v = *p3;

                a = 0x2c;
                *p1 = a;
                v = *p2;
                printf("[%d]=%x\n", a, v);
v = *p3;

                a = 0x134;
                *p1 = a;
                v = *p2;
                printf("[%d]=%x\n", a, v);
v = *p3;
	}
#endif

	/* make sure we can talk to the cs8900 */
	cs8900_set_pp_addr(0, 0);
	if( (temp = cs8900_read_pp_data()) != CS8900_CHIP_ID) {
		printf( "Can't find CS8900 NIC.  Got ID=0x%x\n", temp);
		return 0;
	}

        printf("found CS8900\n");

#define RESET		0x0040	/* Perform chip reset */
#define RSELFCTL	0x0114	/* Self Command Register */
#define RBUSCTL		0x0116	/* Bus control register */
#define RISAINT		0x0022	/* ISA interrupt select */

	cs8900_set_pp_addr(RSELFCTL, 0);
	cs8900_write_pp_data(RESET);
        delayms(100);

	cs8900_set_pp_addr(RBUSCTL, 0);
	printf("BuSCTL %08x\n", cs8900_read_pp_data());

	cs8900_set_pp_addr(RISAINT, 0);
	printf("0x22 %08x\n", cs8900_read_pp_data());

	cs8900_set_pp_addr(RISAINT, 0);
	cs8900_write_pp_data(0x00);

	cs8900_set_pp_addr(RISAINT, 0);
	printf("RISAINT %08x\n", cs8900_read_pp_data());

	return 0;
}


int
cmd_cf(int argc, char *argv[])
{
	extern void *slot_base;
	slot_base = (void *)0x20000000;

	if (argc < 2) {
		printf("usage: cf { id | read | regs }\n");
		return -1;
	}

	/* reset cf */
//	reset_cpld_ctrl_reg_bit(CPLD_CTRL_CF_RESET_BIT);
//	set_cpld_ctrl_reg_bit(CPLD_CTRL_CF_RESET_BIT);

        if (argc <= 1) {
            ide_identify_drive();
            return 0;
        }

        if (strcmp(argv[1], "regs") == 0) {
            ide_show_regs();
        }

        if (strcmp(argv[1], "id") == 0) {
            ide_identify_drive();
        }

        if (strcmp(argv[1], "read") == 0) {
            printf("reading CF\n");
            ide_test_read();
        }
}

#define	XTAL_IN			14745600	/* 14.7456 MHz crystal	*/

/*
 * return FCLK in Hz.
 */
static inline unsigned int
fclkfreq_get( void)
{
	u32 mainDiv1, mainDiv2, preDiv, ps, clkset;
	cscRegs_t *csc = (cscRegs_t *)0x80000400;

	
	clkset = csc->clkset;

	mainDiv1 = (clkset >>  7) & 0x0f;
	mainDiv2 = (clkset >> 11) & 0x1f;
	preDiv   = (clkset >>  2) & 0x1f;
	ps       = (clkset >> 18) & 0x03;

	return  XTAL_IN / ((preDiv + 2) * ( 1 << ps)) * (mainDiv1 +2) * (mainDiv2 + 2) ;
}

/*
 * return the AHB bus clock frequency (HCLK) in kHz.
 */
unsigned int
hclkfreq_get( void)
{
	cscRegs_t *csc = (cscRegs_t *)0x80000400;
	u32	hclkDiv;

	hclkDiv = (csc->clkset & 0x3) + 1;
	printf("fclk=%d, hclkDiv=%d\n", fclkfreq_get() / 1000, hclkDiv);

	return fclkfreq_get() / 1000 / hclkDiv;
}

int
cmd_lcd(int argc, char *argv[])
{
	if (argc < 2) {
		printf("usage: lcd { tft+/- | tft640+/- | tftp800+/- | "
		       "clear | pattern # | map # "
		       " depth {8|16|24} | }\n");
		return -1;
	}

	if (strcmp(argv[1], "clear") == 0) {
		lcd_pattern(0);
	}
	if (strcmp(argv[1], "pattern") == 0 ||
	    strcmp(argv[1], "pat") == 0)
	{
		if (argc == 3)
			lcd_pattern(argv[2][0]-'0');
		else
			printf("usage: lcd pattern #\n");
	}
	if (strcmp(argv[1], "map") == 0) {
		if (argc == 3)
			lcd_colormap(argv[2][0]-'0');
		else
			printf("usage: lcd map #\n");
	}
	if (strcmp(argv[1], "depth") == 0) {
		if (argc == 3) {
			int d;
			if (getnumber(argv[2], &d) == 0) {
				lcd_depth(d);
				return 0;
			}
		}
		printf("usage: lcd depth {8|16|24}\n");
	}

	if (strcmp(argv[1], "tft+") == 0 ||
	    strcmp(argv[1], "tft640+") == 0) {
		lcd_enable_tft(1);
	}
	if (strcmp(argv[1], "tft800+") == 0) {
		lcd_enable_tft(2);
	}
	if (strcmp(argv[1], "stn+") == 0) {
		lcd_enable_stn();
	}
	if (strcmp(argv[1], "lcd-") == 0 ||
	    strcmp(argv[1], "tft-") == 0 ||
	    strcmp(argv[1], "stn-") == 0)
	{
		lcd_disable();
	}

	return 0;
}

void enable_dcache(void)
{
	asm volatile ("mcr p15, 0, ip, c7, c6, 0");
}

void disable_dcache(void)
{
	asm volatile ("mcr p15, 0, ip, c7, c6, 0");
}

void enable_icache(void)
{
	register u32 i;
	
	/* read control register */
	asm volatile ("mrc p15, 0, %0, c1, c0, 0": "=r" (i));

	/* set i-cache */
	i |= 0x1000;

	/* write back to control register */
	asm volatile ("mcr p15, 0, %0, c1, c0, 0": : "r" (i));
}

void disable_icache(void)
{
	register u32 i;

	/* read control register */
	asm volatile ("mrc p15, 0, %0, c1, c0, 0": "=r" (i));

	/* clear i-cache */
	i &= ~0x1000;

	/* write back to control register */
	asm volatile ("mcr p15, 0, %0, c1, c0, 0": : "r" (i));

	/* flush i-cache */
	asm volatile ("mcr p15, 0, %0, c7, c5, 0": : "r" (i));
}

int
cmd_cache(int argc, char *argv[])
{
	if (argc < 2) {
		printf("usage: cache { i+ | i- | d+ | d- }\n");
		return -1;
	}

	if (strcmp(argv[1], "i+") == 0) {
		printf("enabling icache\n");
		enable_icache();
	}
	if (strcmp(argv[1], "i-") == 0) {
		disable_icache();
		printf("icache disabled\n");
	}
	if (strcmp(argv[1], "d+") == 0) {
		printf("enabling dcache\n");
		enable_dcache();
	}
	if (strcmp(argv[1], "d-") == 0) {
		disable_dcache();
		printf("dcache disabled\n");
	}

	return 0;
}

int
cmd_test_all(int argc, char *argv[])
{
	xprintf("test all!\n");

	test_eframe();
	test_expbrd();
}


/*
 * Local Variables:
 * indent-tabs-mode:nil
 * c-basic-offset:4
 * End:
*/
