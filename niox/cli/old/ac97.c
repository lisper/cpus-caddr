/*
 * ac97.c
 *
 * $Id: ac97.c,v 1.1 2003/11/28 12:27:27 brad Exp $
 */

#include "diag.h"
#include "lh7a400.h"

#include "ac97.h"

#define POWER_UP_LOOP_COUNT 1024
#define CODEC_LOOP_COUNT 1024
#define POLL_LOOP_COUNT	1024

const char *reg2str[] = {
	"Reset",			/* AC97_RESET              0x0000 */
	"Master Vol Stereo",		/* AC97_MASTER_VOL_STEREO  0x0002 */
	"Headphone Volume",		/* AC97_HEADPHONE_VOL      0x0004 */
	"Master Volume Mono",		/* AC97_MASTER_VOL_MONO    0x0006 */
	"Master Tone",			/* AC97_MASTER_TONE        0x0008 */
	"PC  Beep Volume",		/* AC97_PCBEEP_VOL         0x000a */
	"Phone volume",			/* AC97_PHONE_VOL          0x000c */
	"Mic Volume",			/* AC97_MIC_VOL            0x000e */
	"LineIn Volume",		/* AC97_LINEIN_VOL         0x0010 */
	"CD Volume",			/* AC97_CD_VOL             0x0012 */
	"Video Volume",			/* AC97_VIDEO_VOL          0x0014 */
	"AUX Volume",			/* AC97_AUX_VOL            0x0016 */
	"PCM Out Volume",		/* AC97_PCMOUT_VOL         0x0018 */
	"Record Select",		/* AC97_RECORD_SELECT      0x001a */
	"Record Gain",			/* AC97_RECORD_GAIN        0x001c */
	"Record Gain Mic",		/* AC97_RECORD_GAIN_MIC    0x001e */
	"Gereral Purpose",		/* AC97_GENERAL_PURPOSE    0x0020 */
	"3D Control",			/* AC97_3D_CONTROL         0x0022 */
	"Modem Rate",			/* AC97_MODEM_RATE         0x0024 */
	"Power Control",		/* AC97_POWER_CONTROL      0x0026 */
	"Extended ID",			/* AC97_EXTENDED_ID        0x0028 */
	"Extended Status",		/* AC97_EXTENDED_STATUS    0x002A */
	"PCM Front DAC Rate",		/* AC97_PCM_FRONT_DAC_RATE 0x002C */
	"PCM Surround DAC Rate",	/* AC97_PCM_SURR_DAC_RATE  0x002E */
	"PCM LFE DAC Rate",		/* AC97_PCM_LFE_DAC_RATE   0x0030 */
	"PCM LR DAC Rate",		/* AC97_PCM_LR_ADC_RATE    0x0032 */
	"PCM Mic ADC Rate",		/* AC97_PCM_MIC_ADC_RATE   0x0034 */
	"Center+LFE Master Volume",	/* AC97_CENTER_LFE_MASTER  0x0036 */
	"Surround Master Volume",	/* AC97_SURROUND_MASTER    0x0038 */
	"Reserved 3A",			/* AC97_RESERVED_3A        0x003A */
	"Extended Modem ID",		/*                         0x003C */
	"Extended Modem Status",	/*                         0x003E */
	"Reserved 40", "Reserved 42", "Reserved 44",
	"Reserved 46", "Reserved 48", "Reserved 4A",
	"GPIO Pin Config",		/*                         0x004C */
	"GPIO Pin Polarity",		/*                         0x004E */
	"GPIO Pin Sticky",		/*                         0x0050 */
	"GPIO Pin Wakeup Mask",		/*                         0x0052 */
	"GPIO Pin Status",		/*                         0x0054 */
	"Reserved 56", "Reserved 58", "Reserved 5A", "Reserved 5C",
	"AC Mode Control",		/*                         0x005E */
	"Misc Crystal Control",		/*                         0x0060 */
	"Reserved 62", "Reserved 64", "Reserved 66",
	"S/PDIF Control",		/*                         0x0068 */
	"Serial Port Control",		/*                         0x006A */
	"Reserved 6C", "Reserved 6E",
	"Reserved 70", "Reserved 72", "Reserved 74",
	"Reserved 77", "Reserved 78", "Reserved 7A",
	"Vendor ID1",			/* AC97_VENDOR_ID1         0x007c */
	"Vendor ID2",			/* AC97_VENDOR_ID2         0x007e */
};


static void decode_GlobalISR(u32 isr)
{
	if( isr & AAC_IRQ_CODEC_READY )		printf( "CodecReady  ");
	if( isr & AAC_IRQ_WAKEUP )		printf( "Wakeup  ");
	if( isr & AAC_IRQ_GPIO )		printf( "GPIO  ");
	if( isr & AAC_IRQ_GPIO_BUSY )		printf( "GPIO_BUSY  ");
	if( isr & AAC_IRQ_SLOT2_RX_VALID )	printf( "Slot2_Rx_Valid  ");
	if( isr & AAC_IRQ_SLOT1_TX_DONE )	printf( "Slot1_Tx_Done  ");
	printf( "\n");
}


/* Write AC97 codec registers */
static u16 aac_ac97_get(u8 reg)
{
	aacRegs_t *aac = (aacRegs_t *)0x80000000;
	int count;
	u16 val;
	u16 tmp;
	u16 gisr;

	/* ensure AAC_IRQ_SLOT2_RX_VALID is clear */
	tmp = aac->slot2Data;

	/* send the register number */
	aac->slot1Data = reg;

	/* wait for Tx Complete */
	count = POLL_LOOP_COUNT;
	do {
		if ((gisr = aac->GlobalRawISR & AAC_IRQ_SLOT1_TX_DONE))
			break;
	} while (count--);

	if( count == 0)
		printf("ac97: read reg %x Tx Complete count expired\n", reg);

	/* now wait for Rx valid */
	count = POLL_LOOP_COUNT;
	do {
		if ((gisr = aac->GlobalRawISR & AAC_IRQ_SLOT2_RX_VALID))
			break;
	} while( count--);

	delayus(100);

	if (count) {
		val = aac->slot2Data;	/* get the register value */
	} else {
		printf("ac97: read reg %x Rx Valid count expired\n", reg);
		val = 0;
	}

	if (val != 0)
		printf("ac97: (%s<%02x>) = 0x%x\n", reg2str[reg>>1], reg, val);

	return val;
}

static inline void wait_for_power_ready(void)
{
	int count = POWER_UP_LOOP_COUNT;

	do {
		if (aac_ac97_get(AC97_POWER_CONTROL) == 0x0F)
			break;
	} while( count--);

	if (aac_ac97_get(AC97_POWER_CONTROL) == 0x0F)
		printf("power ok\n");
	else
		printf("power NOT ok (%x)\n",
		       aac_ac97_get(AC97_POWER_CONTROL));
}

int cmd_aac(int argc, char *argv[])
{
	gpioRegs_t *gpio = (gpioRegs_t *)0x80000e00;
	volatile u32 *expbrd_reg = (u32 *)0x70000000;
	aacRegs_t *aac = (aacRegs_t *)0x80000000;
	int loops;

	/* power up ac97 chip */
	*expbrd_reg = 0x00ff;
	
	/* set GPIO:H pins as output */
	gpio->phddr = _BIT(6);
	gpio->phdr = _BIT(6);

	/* make sure the AAC is enabled and standard codec is disabled */
	gpio->pinmux &= ~GPIO_PINMUX_CODECON;

	aac->Control = AAC_CTRL_ENABLE;		/* enable the AAC */
	delayms(1);

#if 1
	aac->Reset = AAC_RESET_FORCEDRESET | AAC_RESET_TIMEDRESET;
	delayms(1);
#endif

	printf("ac97: waiting for Codec ready\n");

	for (loops = 0; loops < CODEC_LOOP_COUNT; loops++) {
		if( (aac->GlobalRawISR & AAC_IRQ_CODEC_READY) == 0) {
			continue;
		}

		delayus(1);
		break;
	}

	decode_GlobalISR(aac->GlobalRawISR);

	if (loops == CODEC_LOOP_COUNT) {
		printf("ac97: unable to ready codec\n");
		printf("GlobalRawISR %x\n", aac->GlobalRawISR);


		return -1;
	}

	printf("ac97: Codec ready\n");

	aac->Reset = AAC_RESET_TIMEDRESET;

	wait_for_power_ready();

	printf("ac97: power ready\n");

	printf("GlobalRawISR %x\n", aac->GlobalRawISR);

	return 0;
}
