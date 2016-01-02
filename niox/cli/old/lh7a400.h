/*
 * lh7a400_smc.h: describe the Static Memory Controller on the LH7A400
 *
 * Copyright (C) 2001 Sharp Microelectronics of the Americas, Inc.
 *		Camas, WA
 * Portions Copyright (C) 2002  Lineo, Inc.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 *
 *
 *	References:
 *		(1) Sharp LH7A400 Programming Manual
 *
 */

#ifndef LH7A400_H
#define LH7A400_H

/*
 * Clock and State Controller Structure
 */ 
#ifndef __ASSEMBLY__
typedef struct {
    volatile u32	pwrsr;		/* Power/state control status */ 
    volatile u32	pwrcnt;		/* Clock/debug control status */ 
    volatile u32	halt;		/* Read to Enter Idle mode */ 
    volatile u32	stby;		/* Read to Enter Standby mode */ 
    volatile u32	bleoi;		/* Clear low battery interrupt */ 
    volatile u32	mceoi;		/* Clear media changed interrupt */ 
    volatile u32	teoi;		/* Clear tick interrupt */ 
    volatile u32	stfclr;		/* Clear Nbflg, rstflg, pfflg, cldflg */ 
    volatile u32	clkset;		/* Clock speed control */ 
    volatile u32	scratch0;	/* Scratch Register 0 */ 
    volatile u32	scratch1;	/* Scratch Register 1 */ 
    volatile u32	clktest;	/* TEST register */ 
    volatile u32	usbreset;	/* Separate reset of USB APB and I/O */ 
    volatile u32	apbwait;	/* APB Bridge AHB wait state control */
} cscRegs_t;

#else // __ASSEMBLY__

/* offsets of interest to assembly code */
#define CSC_CLKSET_OFFSET	0x20

#endif // __ASSEMBLY__


/* Power/state Control Status Register bits */ 
#define PWRSR_MCDR		_BIT(6)		/* media changed direct read	*/
#define PWRSR_DCDET		_BIT(7)		/* DC detect			*/
#define PWRSR_WUDR		_BIT(8)		/* Wakeup Detect direct read	*/
#define PWRSR_WUON		_BIT(9)		/* Wakeup signal woke us up	*/
#define PWRSR_NBFLG		_BIT(10)	/* New battery flag		*/
#define PWRSR_RSTFLG		_BIT(11)	/* Reset flag			*/
#define PWRSR_PFFLG		_BIT(12)	/* Power Fail flag		*/
#define PWRSR_CLDFLG		_BIT(13)	/* Cold Start flag		*/
#define PWRSR_LCKFLG		_BIT(14)	/* PLL2 Lock flag		*/

#define PWRSR_RTCDIV_WIDTH	(6)
#define	PWRSR_RTCDIV		_BITMASK(PWRSR_RTCDIV_WIDTH)
#define PWRSR_CHIPID_WIDTH	(8)
#define	PWRSR_CHIPID		_SBF(16, _BITMASK(PWRSR_CHIPID_WIDTH))
#define PWRSR_CHIPMAN_WIDTH	(8)
#define PWRSR_CHIPMAN		_SBF(24, _BITMASK(PWRSR_CHIPMAN_WIDTH))


/* Clock/debug Control Status Register bits */ 
#define	PWRCNT_WAKEDI		_BIT(1)
#define PWRCNT_PGMCLK_WIDTH	(8)
#define	PWRCNT_PGMCLK(n)	_SBF(8, (n) & _BITMASK(PWRCNT_PGMCLK_WIDTH))

/* Clock Speed Control Register bits and bit fields */ 
#define CLKSET_MAINDIV1(n)	(((n) & 0x0F) << 7)
#define CLKSET_MAINDIV2(n)	(((n) & 0x1F) << 11)
#define CLKSET_PREDIV(n)	(((n) & 0x1F) << 2)
#define CLKSET_HCLKDIV1		(0 << 0)
#define CLKSET_HCLKDIV2		(1 << 0)
#define CLKSET_HCLKDIV3		(2 << 0)
#define CLKSET_HCLKDIV4		(3 << 0)
#define CLKSET_PCLKDIV2		(0 << 16)
#define CLKSET_PCLKDIV4		(1 << 16)
#define CLKSET_PCLKDIV8		(2 << 16)
#define CLKSET_PS0		(0 << 18)
#define CLKSET_PS1		(1 << 18)
#define CLKSET_PS2		(2 << 18)
#define CLKSET_PS3		(3 << 18)

/* Clock USB Register bits */ 
#define USBRESET_IO		_BIT(0)
#define USBRESET_APB		_BIT(1)

/* APB wait register bits */
#define APB_NO_WRITE_WAIT	_BIT(0)

/* derived clocks */
#define CLKSC_XTAL_IN		(14745600)
#define CLKSC_SSP_CLK		(CLKSC_XTAL_IN / 2)
#define CLKSC_BMI_CLK		(CLKSC_XTAL_IN / 2)
#define CLKSC_UART_CLK		(CLKSC_XTAL_IN / 2)
#define CLKSC_DCDC_CLK		(CLKSC_XTAL_IN / 5)
#define CLKSC_TIMER_SEL0_CLK	(CLKSC_XTAL_IN / 7372)
#define CLKSC_TIMER_SEL1_CLK	(CLKSC_XTAL_IN / 29)
#define CLKSC_TIMER3_CLK	(CLKSC_XTAL_IN / 2)
#define CLKSC_AAC_CLK		(CLKSC_XTAL_IN / 5)
#define CLKSC_USB_CLK		((CLKSC_XTAL_IN * 9 * 21) / (29 * 2))


/*
 * csc->clkset values for various CPU/HCLK/PCLK speeds
 */

/*  CPU clock = 50MHz,   HCLK = 50MHz,   PCLK=25MHz (/2) */
#define CLKSET_50_50_25	(CLKSET_HCLKDIV1 | \
			 CLKSET_MAINDIV1(11) | \
			 CLKSET_MAINDIV2(10) | \
			 CLKSET_PREDIV(21) | \
			 CLKSET_PS1 | \
			 CLKSET_PCLKDIV2)


/* CPU clock = 66 MHz   HCLK =  66 MHz, PCLK=33 MHz */
#define CLKSET_66_66_33		(CLKSET_HCLKDIV1 | \
			 CLKSET_MAINDIV1(15) | \
			 CLKSET_MAINDIV2(8) | \
			 CLKSET_PREDIV(17) | \
			 CLKSET_PS1 | \
			 CLKSET_PCLKDIV2)

/*  CPU clock = 100,   HCLK = 50MHz,   PCLK=25MHz (/2) */
#define CLKSET_100_50_25 (CLKSET_HCLKDIV2 | \
			 CLKSET_MAINDIV1(5) | \
			 CLKSET_MAINDIV2(29) | \
			 CLKSET_PREDIV(14) | \
			 CLKSET_PS1 | \
			 CLKSET_PCLKDIV2)

/*  CPU clock = 150,   HCLK = 75,   PCLK=37 */
#define CLKSET_150_75_37 (CLKSET_HCLKDIV2 | \
			 CLKSET_MAINDIV1(13) | \
			 CLKSET_MAINDIV2(17) | \
			 CLKSET_PREDIV(12) | \
			 CLKSET_PS1 | \
			 CLKSET_PCLKDIV2)

/*  CPU clock = 200,   HCLK = 50MHz,   PCLK=25MHz (/2) */
#define CLKSET_200_50_25 (CLKSET_HCLKDIV4 | \
			 CLKSET_MAINDIV1(12) | \
			 CLKSET_MAINDIV2(29) | \
			 CLKSET_PREDIV(14) | \
			 CLKSET_PS1 | \
			 CLKSET_PCLKDIV2)

/*  CPU clock = 200,   HCLK = 67,   PCLK=33 (/2) */
#define CLKSET_200_67_33 (CLKSET_HCLKDIV3 | \
			 CLKSET_MAINDIV1(12) | \
			 CLKSET_MAINDIV2(29) | \
			 CLKSET_PREDIV(14) | \
			 CLKSET_PS1 | \
			 CLKSET_PCLKDIV2)

/*  CPU clock = 200,   HCLK = 100,   PCLK=25MHz (/2) */
#define CLKSET_200_100_50 (CLKSET_HCLKDIV2 | \
			 CLKSET_MAINDIV1(12) | \
			 CLKSET_MAINDIV2(29) | \
			 CLKSET_PREDIV(14) | \
			 CLKSET_PS1 | \
			 CLKSET_PCLKDIV2)

/*
 * Static Memory Controller Module Register Structure
 */
#ifndef __ASSEMBLY__
typedef struct {
	volatile u32	bcr0;		/* Configuration for bank 0 */ 
	volatile u32	bcr1;		/* Configuration for bank 1 */ 
	volatile u32	bcr2;		/* Configuration for bank 2 */ 
	volatile u32	bcr3;		/* Configuration for bank 3 */ 
	volatile u32	reserved1;
	volatile u32	reserved2;
	volatile u32	bcr6;		/* Configuration for bank 6 */ 
	volatile u32	bcr7;		/* Configuration for bank 7 */ 
	volatile u32	pc1_attribute;	/* PC1 Attribute */ 
	volatile u32	pc1_common;	/* PC1 Common */ 
	volatile u32	pc1_io;		/* PC1 IO */ 
	volatile u32	reserved3;
	volatile u32	pc2_attribute;	/* PC2 Attribute */ 
	volatile u32	pc2_common;	/* PC2 Common */ 
	volatile u32	pc2_io;		/* PC2 IO */ 
	volatile u32	reserved4;
	volatile u32	pcmcia_control;	/* PCMCIA Control*/ 
} SMCREGS;
#else
/* offsets for assembly code */
#define SMC_BCR0_OFF	0x0
#define SMC_BCR1_OFF	0x4
#define SMC_BCR2_OFF	0x8
#define SMC_BCR3_OFF	0xC
#define SMC_BCR6_OFF	0x18
#define SMC_BCR7_OFF	0x1C

#define SMC_PC1_ATTR	0x20
#define SMC_PC1_COM	0x24
#define SMC_PC1_IO	0x28

#define SMC_PC2_ATTR	0x30
#define SMC_PC2_COM	0x34
#define SMC_PC2_IO	0x38

#define SMC_PCMCIA_CTRL	0x40

#endif

/**********************************************************************
 * SMC Bank Configuration Register Bit Fields
 *********************************************************************/
#define SMC_BCR_IDCY(n)	_SBF(0,(((n)-1)&0x0F))	/* Idle Cycle Time */
#define SMC_BCR_WST1(n)	_SBF(5,(((n)-1)&0x1F))	/* Wait State 1 */
#define SMC_BCR_RBLE(n)	_SBF(10,((n)&0x01))	/* Read Byte Lane Enable */
#define SMC_BCR_WST2(n)	_SBF(11,(((n)-1)&0x1F))	/* Wait State 2 */
#define SMC_BCR_WPERR	_BIT(25)		/* Write Protect Error Flag*/
#define SMC_BCR_WP	_BIT(26)		/* Write Protect */
#define SMC_BCR_PME	_BIT(27)		/* Page Mode Enable */
#define SMC_BCR_MW8	_SBF(28,0)		/* Memory width 8 bits */
#define SMC_BCR_MW16	_SBF(28,1)		/* Memory width 16 bits */
#define SMC_BCR_MW32	_SBF(28,2)		/* Memory width 32 bits */

/**********************************************************************
 * PCMCIA Attribute, Common, and IO Space Configuration Register
 * Bit Fields
 *********************************************************************/
#define PCMCIA_CFG_PC(n)	_SBF(0,((n)&0xFF))	/* Pre-charge delay*/ 
#define PCMCIA_CFG_HT(n)	_SBF(8,((n)&0x0F))	/* Hold time */ 
#define PCMCIA_CFG_AC(n)	_SBF(16,((n)&0xFF))	/* Access time */ 
#define PCMCIA_CFG_W8		_SBF(31,0)		/* Address space 8 bits wide */ 
#define PCMCIA_CFG_W16		_SBF(31,1)		/* Address space 16 bits wide */ 

/**********************************************************************
 * PCMCIA Control Register Bit Fields
 *********************************************************************/
#define PCMCIA_CONTROL_NONE	_SBF(0,0)	/* No cards enabled */ 
#define PCMCIA_CONTROL_CF	_SBF(0,1)	/* One CF enabled */ 
#define PCMCIA_CONTROL_PC	_SBF(0,2)	/* One PC enabled */ 
#define PCMCIA_CONTROL_CFPC	_SBF(0,3)	/* One CF and one PC enabled */ 
#define PCMCIA_CONTROL_PC1RST	_SBF(2,1)	/* Reset card 1 */ 
#define PCMCIA_CONTROL_PC1NORMAL _SBF(2,0)	/* Normal op card 1 */ 
#define PCMCIA_CONTROL_PC2RST	_SBF(3,1)	/* Reset card 2 */ 
#define PCMCIA_CONTROL_PC2NORMAL _SBF(3,0)	/* Normal op card 1 */ 
#define PCMCIA_CONTROL_WEN1	 _SBF(4,1)	/* Wait State Enable card 1 */ 
#define PCMCIA_CONTROL_WEN2	 _SBF(5,1)	/* Wait State Enable card 1 */ 
#define PCMCIA_CONTROL_MANPREG	 _SBF(8,1)	/* Manual nPREG */ 
#define PCMCIA_CONTROL_AUTOPREG	 _SBF(8,0)	/* Auto nPREG */ 

/* GPIO Register Structures */ 
typedef struct {
	volatile u32	padr;
	volatile u32	pbdr;
	volatile u32	pcdr;
	volatile u32	pddr;
	volatile u32	paddr;
	volatile u32	pbddr;
	volatile u32	pcddr;
	volatile u32	pdddr;
	volatile u32	pedr;
	volatile u32	peddr;
	volatile u32	kscan;
	volatile u32	pinmux;
	volatile u32	pfdr;
	volatile u32	pfddr;
	volatile u32	pgdr;
	volatile u32	pgddr;
	volatile u32	phdr;
	volatile u32	phddr;
	volatile u32	reserved1;
	volatile u32	inttype1;
	volatile u32	inttype2;
	volatile u32	gpiofeoi;
	volatile u32	gpiointen;
	volatile u32	intstatus;
	volatile u32	rawintstatus;
	volatile u32	gpiodb;
	volatile u32	papindr;
	volatile u32	pbpindr;
	volatile u32	pcpindr;
	volatile u32	pdpindr;
	volatile u32	pepindr;
	volatile u32	pfpindr;
	volatile u32	pgpindr;
	volatile u32	phpindr;
} gpioRegs_t;

/**********************************************************************
 * GPIO PINMUX Register
 *********************************************************************/ 
#define GPIO_PINMUX_PEOCON	_BIT(0)
#define GPIO_PINMUX_PDOCON	_BIT(1)
#define GPIO_PINMUX_CODECON	_BIT(2)
#define GPIO_PINMUX_UART3ON	_BIT(3)
#define GPIO_PINMUX_CLK12EN	_BIT(4)
#define GPIO_PINMUX_CLK0EN	_BIT(5)

/**********************************************************************
 * GPIO Port F Interrupts (used for all Port F Interrupt registers)
 *********************************************************************/ 
#define GPIO_PFINT(n)		(_BIT(n)&0xFF)

/*
 * LCD 
 */

/* CLCDC Registers */
#ifndef __ASSEMBLY__
typedef struct {
	volatile u32 timing0;	/* Horizontal axis panel control */
	volatile u32 timing1;	/* Vertical axis panel control */
	volatile u32 timing2;	/* Clock and signal polarity control */
	volatile u32 reserved;	/* Reserved. Do not access these locations. */
	volatile u32 upbase;	/* Upper panel frame base address */
	volatile u32 lpbase;	/* Lower panel frame base address */
	volatile u32 intren;	/* Interrupt enable mask */
	volatile u32 control;	/* LCD panel pixel parameters */
	volatile u32 status;	/* Raw interrupt status */
	volatile u32 interrupt;	/* Final masked interrupts */
	volatile u32 upcurr;	/* LCD upper panel current address value */
	volatile u32 lpcurr;	/* LCD lower panel current address value */
	volatile u32 overflow;	/* SDRAM overflow frame buffer address */
	volatile u32 reserved1[115]; /* Reserved. Do not access. */
	u16 palette[256];   /* 256 Å◊ 16-bit color palette */
} CLCDCREGS;

typedef struct {
	volatile u32 setup;	/* Setup		*/ 
	volatile u32 control;	/* Control		*/ 
	volatile u32 timing1;	/* HR-TFT Timing 1	*/ 
	volatile u32 timing2;	/* HR-TFT Timing 2	*/ 
} CLCDICPREGS;


#else /* __ASSEMBLY__ */

#define CLCDC_TIMING0_OFF	0x000 /* Horizontal axis panel control */
#define CLCDC_TIMING1_OFF	0x004 /* Vertical axis panel control */
#define CLCDC_TIMING2_OFF	0x008 /* Clock and signal polarity control */
#define CLCDC_UPBASE_OFF	0x010 /* Upper panel frame base address */
#define CLCDC_LPBASE_OFF	0x014 /* Lower panel frame base address */
#define CLCDC_INTREN_OFF	0x018 /* Interrupt enable mask */
#define CLCDC_CONTROL_OFF	0x01C /* LCD panel pixel parameters */
#define CLCDC_STATUS_OFF	0x020 /* Raw interrupt status */
#define CLCDC_INTERRUPT_OFF	0x024 /* Final masked interrupts */
#define CLCDC_UPCURR_OFF	0x028 /* LCD upper panel current addrress */
#define CLCDC_LPCURR_OFF	0x02C /* LCD lower panel current address */
#define CLCDC_OVERFLOW_OFF	0x030 /* SDRAM overflow frame buffer address */
#define CLCDC_PALETTE_OFF	0x200 /* 256 Å◊ 16-bit color palette */

#endif

#define CLCDC_TIM0_HBP(n) _SBF(24,(((n)-1)&0xff)) /* Horiz back portch */
#define CLCDC_TIM0_HFP(n) _SBF(16,(((n)-1)&0xff)) /* Horiz front portch */
#define CLCDC_TIM0_HSW(n) _SBF(8,(((n)-1)&0xff)) /* Horiz sync pulse width */
#define CLCDC_TIM0_PPL(n) _SBF(0,(((n)/16-1)&0xff)) /* Pixels-per-line */

#define CLCDC_TIM1_VBP(n) _SBF(24,(((n)-1)&0xff)) /* Vertical back portch */
#define CLCDC_TIM1_VFP(n) _SBF(16,(((n)-1)&0xff)) /* Vertical front portch */
#define CLCDC_TIM1_VSW(n) _SBF(8,(((n)-1)&0x3f)) /* Vert sync pulse width */
#define CLCDC_TIM1_LPP(n) _SBF(0,(((n)-1)&0x3ff)) /* Lines-per-panel */

#define CLCDC_TIM2_BCD(n) _SBF(26,(n)&1) /* Bypass pixel clock divider */
#define CLCDC_TIM2_CPL(n) _SBF(16,((n)-1)&0x3ff) /* Clocks per line */
#define CLCDC_TIM2_IOE(n) _SBF(14,(n)&1) /* invert output enable */
#define CLCDC_TIM2_IPC(n) _SBF(13,(n)&1) /* invert panel clock */
#define CLCDC_TIM2_IHS(n) _SBF(12,(n)&1) /* invert horiz sync */
#define CLCDC_TIM2_IVS(n) _SBF(11,(n)&1) /* invert vert sync */
#define CLCDC_TIM2_ACB(n) _SBF(6,(n)&0x1f) /* AC bias signal freq */
#define CLCDC_TIM2_CSEL(n) _SBF(5,(n)&1) /* reference clock select */
#define CLCDC_TIM2_PCD(n) _SBF(0,(n)&0x1f) /* panel clock devisor */

#define CLCDC_TIM3_LEE(n) _SBF(16,(n)&1) /* lcd line end enable */
#define CLCDC_TIM3_LED(n) _SBF(0,(n)&0xff) /* line end signal delay */

#define CLCDC_INTREN_BUSEREN(n) _SBF(4,(n)&1) /* AHB master bus error enable */
#define CLCDC_INTREN_VCOMEN(n) _SBF(3,(n)&1) /* vertical compare int enable */
#define CLCDC_INTREN_NBUEN(n) _SBF(2,(n)&1) /* next base update int enable */
#define CLCDC_INTREN_LPUEN(n) _SBF(1,(n)&1) /* fifo u-flow lwr panel int ena */
#define CLCDC_INTREN_UPUEN(n)_SBF(0,(n)&1) /* fifo u-flow upr panel int ena */

#define CLCDC_CTRL_WATERMARK(n) _SBF(16,(n)&1) /* dma fifo threshhold */
#define CLCDC_CTRL_LCDVCOMP(n) _SBF(12,(n)&3) /* lcd vertical compare */
#define CLCDC_CTRL_LCDPWR(n) _SBF(11,(n)&1) /* lcd power enable */
#define CLCDC_CTRL_BGR(n) _SBF(8,(n)&1) /* rbg/bgr format */
#define CLCDC_CTRL_LCDDUAL(n) _SBF(7,(n)&1) /* dual/single lcd panel */
#define CLCDC_CTRL_LCDMONO8(n) _SBF(6,(n)&1) /* mono stn 4/8 bit mode */
#define CLCDC_CTRL_LCDTFT(n) _SBF(5,(n)&1) /* tft/stn select */
#define CLCDC_CTRL_LCDBW(n) _SBF(4,(n)&1) /* color/mono select */
#define CLCDC_CTRL_LCDBPP(n) _SBF(1,(n)&7) /* bits-per-pixel */
#define CLCDC_CTRL_LCDEN(n) _SBF(0,(n)&1) /* lcd controller enable */

#define CLCDICP_CTRL_SPSEN(n) _SBF(0, (n)&1)
#define CLCDICP_CTRL_CLSEN(n) _SBF(1, (n)&1)

#define CLCDICP_SETUP_CMS(n) _SBF(0, (n)&3)
#define CLCDICP_SETUP_PPL(n) _SBF(4, (n)&0x1ff)
#define CLCDICP_SETUP_ICPEN(n) _SBF(13, (n)&1)

/* AC97 */

typedef struct {
	u32 	Data;			/* R/W FIFO */
	u32	RxControl;		/* Rx Control */
	u32 	TxControl;		/* Tx Control */
	u32	Status;			/* channel status*/
	u32	RawISR;			/* Raw Interrupt Status	*/
	u32	ISR;			/* Masked Interrupt Status */
	u32	IE;			/* Interrupt Enable */
	u32	reserved;
} aacChannel_t;

#define N_CHAN 4

typedef struct {
	aacChannel_t chan[N_CHAN];	/* N_CHAN sets of channel registers */
	u32	slot1Data;		/* Slot 1 Tx or Tx data */
	u32	slot2Data;		/* Slot 2 Tx or Tx data */
	u32	slot12Data;		/* Slot 12 Tx or Tx data */
	u32	GlobalRawISR;		/* Global Raw Interrupt Status */
	u32	GlobalISR;		/* Global Interrupt Status */
	u32	GlobalIE;		/* Global Interrupt Enable */
	u32	GlobalEOI;		/* Global Interrupt Clear */
	u32	Control;
	u32	Reset;			/* reset control */
	u32	Sync;			/* SYNC control */
	u32	GlobalFifoISR;		/* GLobal channel FIFO ISR */
} aacRegs_t;

/* GlobalRawISR, GlobalISR, GlobalIE register bits */
#define	AAC_IRQ_CODEC_READY	_BIT(5)		/* Codec Ready */
#define	AAC_IRQ_WAKEUP		_BIT(4)		/* Wakeup */
#define	AAC_IRQ_GPIO		_BIT(3)		/* GPIO */
#define	AAC_IRQ_GPIO_BUSY	_BIT(2)		/* GPIO busy */
#define	AAC_IRQ_SLOT2_RX_VALID	_BIT(1)		/* Slot 2 Rx valid */
#define	AAC_IRQ_SLOT1_TX_DONE	_BIT(0)		/* Slot 1 Tx done */

/* GlobalEOI bits */
#define AAC_EOI_CODEC_READY	_BIT(1)		/* clear CodecReady IRQ */
#define AAC_EOI_WAKEUP		_BIT(0)		/* clear Wakeup IRQ */

/* Control register bits */
#define AAC_CTRL_OCR		_BIT(2)		/* Override Codec Ready */
#define AAC_CTRL_LOOPBACK	_BIT(1)		/* Enable Loopback mode */
#define AAC_CTRL_ENABLE		_BIT(0)		/* Enable AAC */

/* Reset register bits */
#define AAC_RESET_FORCE		_BIT(2)		/* Forced reset	enable */
#define AAC_RESET_FORCEDRESET	_BIT(1)
#define AAC_RESET_TIMEDRESET	_BIT(0)

/* Sync register bits */
#define AAC_SYNC_FORCE		_BIT(2)		/* Forced sync enable */
#define AAC_SYNC_FORCEDRESET	_BIT(1)
#define AAC_SYNC_TIMEDRESET	_BIT(0)




#endif /* LH7A400_H */ 
