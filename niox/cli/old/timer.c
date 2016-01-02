/*
 * timer.c
 * 
 * $Id: timer.c,v 1.2 2005/01/15 21:38:38 brad Exp $
 */

#include "diag.h"

static int timer_ready;
static unsigned short last_count;
static unsigned long ticks;

/*
 * Timer Module Register Structure
 */ 
typedef struct {
	volatile u32		load;		/* RW */ 
	volatile u32		value;		/* RO */ 
	volatile u32		control;	/* RW */ 
	volatile u32		clear;		/* WO */ 
} timerRegs_t;

#define TIMER1_PHYS	0x80000c00
#define TIMER2_PHYS	0x80000c20
#define	BZCON		0x80000c40
#define TIMER3_PHYS	0x80000c80

#define TIMER_CTRL_ENABLE		_BIT(7)
#define TIMER_CTRL_DISABLE		(0)
#define TIMER_CTRL_PERIODIC		_BIT(6)
#define TIMER_CTRL_FREERUN		(0)
#define TIMER_CTRL_508K			_BIT(3)
#define TIMER_CTRL_2K			(0)

void
init_timer(void)
{
	timerRegs_t *timer1 = (timerRegs_t *)TIMER1_PHYS;
	timerRegs_t *timer2 = (timerRegs_t *)TIMER2_PHYS;
	timerRegs_t *timer3 = (timerRegs_t *)TIMER3_PHYS;

	/* stop all timers */
	timer1->control = 0;
	timer2->control = 0;
	timer3->control = 0;

	timer1->load = 0xffff;

	/* free running */
	timer1->control = TIMER_CTRL_ENABLE | TIMER_CTRL_2K;

	last_count = 0;
}

unsigned short
get_timer_count(void)
{
	timerRegs_t *timer1 = (timerRegs_t *)TIMER1_PHYS;
	return ~(unsigned short)timer1->value;
}

unsigned long currticks(void)
{
	unsigned count, diff;

	if (!timer_ready) {
		init_timer();
		timer_ready = 1;
	}

#if 0
	count = get_timer_count();
	diff = count - last_count;
	ticks += diff;

	last_count = count;

	return (ticks * 10) / 2048;
#else
	count = get_timer_count();
	diff = count - last_count;
	if (diff < 204)
		return ticks;

	ticks += diff / 204;
	last_count = count;

	return ticks;
#endif
}

int
ticks_per_sec(void)
{
	return 10;
}

static int tc;

void twiddle(void)
{
	char c;

	if (tc < 0 || tc >= 8) tc = 0;
	c = "|/-\\|/-\\"[tc++];
	putchar(c);
}


int
cmd_buzz(int argc, char *argv[])
{
	timerRegs_t *timer1 = (timerRegs_t *)TIMER1_PHYS;
	volatile u32 *bzcon = (volatile u32 *)BZCON;
	int f;

	if (argc < 2) {
		printf("buzz <freq>\n");
		return -1;
	}

	if (getnumber(argv[1], &f)) {
		printf("bad frequency\n");
		return -1;
	}


	/* stop timer */
	timer1->control = 0;
	timer1->load = 0xffff;

	/* free running */
	timer1->control = TIMER_CTRL_ENABLE | TIMER_CTRL_508K;
	timer_ready = 0;

	timer1->load = 508000 / f;

	*bzcon = 0x02;
	delayms(500);
	*bzcon = 0x0;
	delayms(500);

	return 0;
}

int
cmd_tbuzz(int argc, char *argv[])
{
	timerRegs_t *timer1 = (timerRegs_t *)TIMER1_PHYS;
	volatile u32 *bzcon = (volatile u32 *)BZCON;
	int i, j;
	int freq[8];

	/* around 500hz tone */
	*bzcon = 0x0;
	for (i = 0; i < 5; i++) {
		for (j = 0; j < 1000; j++) {
			*bzcon = 0x1;
			delayms(1);
			*bzcon = 0x0;
			delayms(1);
		}
		delayms(500);
	}

	
	/* stop timer */
	timer1->control = 0;
	timer1->load = 0xffff;

	/* free running */
	timer1->control = TIMER_CTRL_ENABLE | TIMER_CTRL_508K;
	timer_ready = 0;

	freq[0] = 440;
	freq[1] = 494;
	freq[2] = 523;
	freq[3] = 587;
	freq[4] = 659;
	freq[5] = 698;
	freq[6] = 784;
	freq[7] = 880;

	for (i = 0; i < 8; i++) {
		timer1->load = 508000 / freq[i];

		printf("tone %d\n", i);
		*bzcon = 0x02;
		delayms(500);
		*bzcon = 0x0;
		delayms(500);
	}

	return 0;
}


