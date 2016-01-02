/* cs89x0.c: A Crystal Semiconductor CS89[02]0 driver for etherboot. */
/*
  Permission is granted to distribute the enclosed cs89x0.[ch] driver
  only in conjunction with the Etherboot package.  The code is
  ordinarily distributed under the GPL.
  
  Russ Nelson, January 2000

  ChangeLog:

  Thu Dec 6 22:40:00 1996  Markus Gutschke  <gutschk@math.uni-muenster.de>

  * disabled all "advanced" features; this should make the code more reliable

  * reorganized the reset function

  * always reset the address port, so that autoprobing will continue working

  * some cosmetic changes

  * 2.5

  Thu Dec 5 21:00:00 1996  Markus Gutschke  <gutschk@math.uni-muenster.de>

  * tested the code against a CS8900 card

  * lots of minor bug fixes and adjustments

  * this is the first release, that actually works! it still requires some
    changes in order to be more tolerant to different environments

  * 4

  Fri Nov 22 23:00:00 1996  Markus Gutschke  <gutschk@math.uni-muenster.de>

  * read the manuals for the CS89x0 chipsets and took note of all the
    changes that will be neccessary in order to adapt Russel Nelson's code
    to the requirements of a BOOT-Prom

  * 6

  Thu Nov 19 22:00:00 1996  Markus Gutschke  <gutschk@math.uni-muenster.de>

  * Synched with Russel Nelson's current code (v1.00)

  * 2

  Thu Nov 12 18:00:00 1996  Markus Gutschke  <gutschk@math.uni-muenster.de>

  * Cleaned up some of the code and tried to optimize the code size.

  * 1.5

  Sun Nov 10 16:30:00 1996  Markus Gutschke  <gutschk@math.uni-muenster.de>

  * First experimental release. This code compiles fine, but I
  have no way of testing whether it actually works.

  * I did not (yet) bother to make the code 16bit aware, so for
  the time being, it will only work for Etherboot/32.

  * 12

  */

#include "diag.h"
#include "tftp.h"
#include "cs89x0.h"
#include "eframe.h"

static unsigned long	eth_nic_base;
static unsigned long    eth_mem_start;
static unsigned short   eth_irq;
static unsigned short   eth_cs_type;	/* one of: CS8900, CS8920, CS8920M  */
static unsigned short   eth_auto_neg_cnf;
static unsigned short   eth_adapter_cnf;
static unsigned short	eth_linectl;

#if 1

void outw(unsigned short w, unsigned long addr)
{
  unsigned long *pw = (unsigned long *)addr;

  *pw = w;
}

int inw(unsigned long addr)
{
  unsigned long *pw = (unsigned long *)addr;
  int val;

  return *pw;
}

#endif

void outsw(int port, const char *wbuf, int wlen)
{
	volatile unsigned long *pw = (unsigned long *)port;
	int i;
	volatile u32 *cr = (volatile u32 *)CPLD_RESET_CTRL_BITS;
	volatile u32 v;

	for (i = 0; i < wlen; i++) {
//		v = cr[0];
		*pw = ((volatile unsigned short *)wbuf)[i];
	}
}

void insw(int port, char *wbuf, int wlen)
{
	volatile unsigned long *pw = (unsigned long *)port;
	int i;
	volatile u32 *cr = (volatile u32 *)CPLD_RESET_CTRL_BITS;
	volatile u32 v;

	for (i = 0; i < wlen; i++) {
//		v = cr[0];
		((unsigned short *)wbuf)[i] = *pw;
	}
}


/*************************************************************************
	CS89x0 - specific routines
**************************************************************************/

static inline int readreg(int portno)
{
	outw(portno, eth_nic_base + ADD_PORT);
	return inw(eth_nic_base + DATA_PORT);
}

static inline void writereg(int portno, int value)
{
	outw(portno, eth_nic_base + ADD_PORT);
	outw(value, eth_nic_base + DATA_PORT);
	return;
}

/*************************************************************************
EEPROM access
**************************************************************************/

static int wait_eeprom_ready(void)
{
	unsigned long tmo = currticks() + 4*TICKS_PER_SEC;

	/* check to see if the EEPROM is ready, a timeout is used -
	   just in case EEPROM is ready when SI_BUSY in the
	   PP_SelfST is clear */
	while(readreg(PP_SelfST) & SI_BUSY) {
		if (currticks() >= tmo)
			return -1; }
	return 0;
}

static int get_eeprom_data(int off, int len, unsigned short *buffer)
{
	int i;

#define EDEBUG
#ifdef	EDEBUG
	printf("\ncs: EEPROM data from %x for %x:",off,len);
#endif
	for (i = 0; i < len; i++) {
		if (wait_eeprom_ready() < 0)
			return -1;
		/* Now send the EEPROM read command and EEPROM location
		   to read */
		writereg(PP_EECMD, (off + i) | EEPROM_READ_CMD);
		if (wait_eeprom_ready() < 0)
			return -1;
		buffer[i] = readreg(PP_EEData);
#ifdef	EDEBUG
		if (!(i%10))
			printf("\ncs: ");
		printf("%4x ", buffer[i]);
#endif
	}
#ifdef	EDEBUG
	printf("\n");
#endif

	return(0);
}

static int get_eeprom_chksum(int off, int len, unsigned short *buffer)
{
	int  i, cksum;

	cksum = 0;
	for (i = 0; i < len; i++)
		cksum += buffer[i];
	cksum &= 0xffff;
printf("eeprom chksum %x\n", cksum);
	if (cksum == 0)
		return 0;
	return -1;
}

/*************************************************************************
Activate all of the available media and probe for network
**************************************************************************/

static void clrline(void)
{
	int i;
#if 0
	printf("\r");
	for (i = 79; i--; ) printf(" ");
	printf("\rcs: ");
#endif
	return;
}

static void control_dc_dc(int on_not_off)
{
	unsigned int selfcontrol;
	unsigned long tmo = currticks() + TICKS_PER_SEC;

	/* control the DC to DC convertor in the SelfControl register.  */
	selfcontrol = HCB1_ENBL; /* Enable the HCB1 bit as an output */
	if (((eth_adapter_cnf & A_CNF_DC_DC_POLARITY) != 0) ^ on_not_off)
		selfcontrol |= HCB1;
	else
		selfcontrol &= ~HCB1;
	writereg(PP_SelfCTL, selfcontrol);

	/* Wait for the DC/DC converter to power up - 1000ms */
	while (currticks() < tmo);

	return;
}

static int detect_tp(void)
{
	unsigned long tmo;

	/* Turn on the chip auto detection of 10BT/ AUI */

	clrline(); printf("attempting %s:","TP");

        /* If connected to another full duplex capable 10-Base-T card
	   the link pulses seem to be lost when the auto detect bit in
	   the LineCTL is set.  To overcome this the auto detect bit
	   will be cleared whilst testing the 10-Base-T interface.
	   This would not be necessary for the sparrow chip but is
	   simpler to do it anyway. */
	writereg(PP_LineCTL, eth_linectl &~ AUI_ONLY);
//	control_dc_dc(0);

        /* Delay for the hardware to work out if the TP cable is
	   present - 150ms */
	for (tmo = currticks() + 4; currticks() < tmo; );

	//printf("PP_LineST %4x\n", readreg(PP_LineST));
	if ((readreg(PP_LineST) & LINK_OK) == 0)
		return 0;

	if (eth_cs_type != CS8900) {

		writereg(PP_AutoNegCTL, eth_auto_neg_cnf & AUTO_NEG_MASK);

		if ((eth_auto_neg_cnf & AUTO_NEG_BITS) == AUTO_NEG_ENABLE) {
			printf(" negotiating duplex... ");
			while (readreg(PP_AutoNegST) & AUTO_NEG_BUSY) {
				if (currticks() - tmo > 40*TICKS_PER_SEC) {
					printf("time out ");
					break;
				}
			}
		}
		if (readreg(PP_AutoNegST) & FDX_ACTIVE)
			printf("using full duplex");
		else
			printf("using half duplex");
	}

	return A_CNF_MEDIA_10B_T;
}

/* send a test packet - return true if carrier bits are ok */
static int send_test_pkt(struct nic *nic)
{
	static unsigned char testpacket[] = { 0,0,0,0,0,0, 0,0,0,0,0,0,
				     0, 46, /*A 46 in network order       */
				     0, 0,  /*DSAP=0 & SSAP=0 fields      */
				     0xf3,0 /*Control (Test Req+P bit set)*/ };
	unsigned long tmo;

	writereg(PP_LineCTL, readreg(PP_LineCTL) | SERIAL_TX_ON);

	memcpy(testpacket, nic->node_addr, ETH_ALEN);
	memcpy(testpacket+ETH_ALEN, nic->node_addr, ETH_ALEN);

	outw(TX_AFTER_ALL, eth_nic_base + TX_CMD_PORT);
	outw(ETH_ZLEN, eth_nic_base + TX_LEN_PORT);

	/* Test to see if the chip has allocated memory for the packet */
	for (tmo = currticks() + 2;
	     (readreg(PP_BusST) & READY_FOR_TX_NOW) == 0; )
		if (currticks() >= tmo)
			return(0);

	/* Write the contents of the packet */
	outsw(eth_nic_base + TX_FRAME_PORT, testpacket,
	      (ETH_ZLEN+1)>>1);

	printf(" sending test packet ");
	/* wait a couple of timer ticks for packet to be received */
	for (tmo = currticks() + 2; currticks() < tmo; );

	if ((readreg(PP_TxEvent) & TX_SEND_OK_BITS) == TX_OK) {
			printf("succeeded\n");
			return 1;
	}
	printf("failed\n");
	return 0;
}


static int detect_aui(struct nic *nic)
{
	clrline(); printf("attempting %s:","AUI");
//	control_dc_dc(0);

	writereg(PP_LineCTL, (eth_linectl & ~AUTO_AUI_10BASET) | AUI_ONLY);

	if (send_test_pkt(nic)) {
		return A_CNF_MEDIA_AUI; }
	else
		return 0;
}

static int detect_bnc(struct nic *nic)
{
	clrline(); printf("attempting %s:","BNC");
//	control_dc_dc(1);

	writereg(PP_LineCTL, (eth_linectl & ~AUTO_AUI_10BASET) | AUI_ONLY);

	if (send_test_pkt(nic)) {
		return A_CNF_MEDIA_10B_2; }
	else
		return 0;
}

/**************************************************************************
ETH_RESET - Reset adapter
***************************************************************************/

static void cs89x0_reset(struct nic *nic)
{
	int  i;
	unsigned long reset_tmo;

	writereg(PP_SelfCTL, readreg(PP_SelfCTL) | POWER_ON_RESET);

	/* wait for two ticks; that is 2*55ms */
	for (reset_tmo = currticks() + 2; currticks() < reset_tmo; );

#if 0
	if (eth_cs_type != CS8900) {
		/* Hardware problem requires PNP registers to be reconfigured
		   after a reset */
		if (eth_irq != 0xFFFF) {
			outw(PP_CS8920_ISAINT, eth_nic_base + ADD_PORT);
			outb(eth_irq, eth_nic_base + DATA_PORT);
			outb(0, eth_nic_base + DATA_PORT + 1); }

		if (eth_mem_start) {
			outw(PP_CS8920_ISAMemB, eth_nic_base + ADD_PORT);
			outb((eth_mem_start >> 8) & 0xff,
			     eth_nic_base + DATA_PORT);
			outb((eth_mem_start >> 24) & 0xff,
			     eth_nic_base + DATA_PORT + 1);
		}
	}
#endif

	/* Wait until the chip is reset */
	for (reset_tmo = currticks() + 2;
	     (readreg(PP_SelfST) & INIT_DONE) == 0 &&
		     currticks() < reset_tmo; );

	/* disable interrupts and memory accesses */
	writereg(PP_BusCTL, 0);

	/* set the ethernet address */
	for (i=0; i < ETH_ALEN/2; i++)
		writereg(PP_IA+i*2,
			 nic->node_addr[i*2] |
			 (nic->node_addr[i*2+1] << 8));

	/* receive only error free packets addressed to this card */
	writereg(PP_RxCTL, DEF_RX_ACCEPT);
//writereg(PP_RxCTL, DEF_RX_ACCEPT | RX_ALL_ACCEPT);

	/* do not generate any interrupts on receive operations */
	writereg(PP_RxCFG, 0);

	/* do not generate any interrupts on transmit operations */
	writereg(PP_TxCFG, 0);

	/* do not generate any interrupts on buffer operations */
	writereg(PP_BufCFG, 0);

	/* reset address port, so that autoprobing will keep working */
	outw(PP_ChipID, eth_nic_base + ADD_PORT);

	return;
}

/**************************************************************************
ETH_TRANSMIT - Transmit a frame
***************************************************************************/

static void cs89x0_transmit(
	struct nic *nic,
	const char *d,			/* Destination */
	unsigned int t,			/* Type */
	unsigned int s,			/* size */
	const char *p)			/* Packet */
{
	unsigned long tmo;
	int           sr;

//printf("cs89x0_transmit()\n");
//printf("PP_BusST %4x\n", readreg(PP_BusST));
//printf("PP_BufEvent %4x\n", readreg(PP_BufEvent));
//printf("PP_BufCFG %4x\n", readreg(PP_BufCFG));
//printf("PP_LineST %4x\n", readreg(PP_LineST));
//printf("PP_LineCTL %4x\n", readreg(PP_LineCTL));
//printf("PP_SelfST %4x\n", readreg(PP_SelfST));
//printf("PP_SelfCTL %4x\n", readreg(PP_SelfCTL));
//printf("PP_TestCTL %4x\n", readreg(PP_TestCTL));
//printf("PP_TxCMD %4x\n", readreg(PP_TxCMD));
//printf("PP_TxEvent %4x\n", readreg(PP_TxEvent));
//printf("PP_RxEvent %4x\n", readreg(PP_RxEvent));
//printf("PP_ISQ %4x\n", readreg(PP_ISQ));
//printf("PP_AutoNegCTL %4x\n", readreg(PP_AutoNegCTL));
//printf("PP_BusCTL %4x\n", readreg(PP_BusCTL));
//printf("PP_RxStatus %4x\n", readreg(PP_RxStatus));
//printf("PP_RxMiss %4x\n", readreg(PP_RxMiss));
//printf("PP_RxFrame %4x\n", readreg(PP_RxFrame));
//printf("PP_RxLength %4x\n", readreg(PP_RxLength));

	/* does this size have to be rounded??? please,
	   somebody have a look in the specs */
	if ((sr = ((s + ETH_HLEN + 1)&~1)) < ETH_ZLEN)
		sr = ETH_ZLEN;

	//printf("sr %d\n", sr);

retry:
	/* initiate a transmit sequence */
	outw(TX_AFTER_ALL, eth_nic_base + TX_CMD_PORT);
	outw(sr, eth_nic_base + TX_LEN_PORT);

	/* Test to see if the chip has allocated memory for the packet */
	if ((readreg(PP_BusST) & READY_FOR_TX_NOW) == 0) {
		/* Oops... this should not happen! */
		printf("cs: unable to send packet; retrying...\n");
		for (tmo = currticks() + 5*TICKS_PER_SEC; currticks() < tmo; );
		cs89x0_reset(nic);
		goto retry; }

	/* Write the contents of the packet */
#if 0
if (d[1] == 0xff) {
	outw(0xffff, eth_nic_base + TX_FRAME_PORT);
//	outw(((u_short *)d)[0], eth_nic_base + TX_FRAME_PORT);
	outw(((u_short *)d)[1], eth_nic_base + TX_FRAME_PORT);
	outw(((u_short *)d)[2], eth_nic_base + TX_FRAME_PORT);
//	printf("d %2x %2x %2x %2x\n", d[0], d[1], d[2], d[3]);
} else {
	outsw(eth_nic_base + TX_FRAME_PORT, d, ETH_ALEN/2);
}
#else
	outsw(eth_nic_base + TX_FRAME_PORT, d, ETH_ALEN/2);
#endif

	outsw(eth_nic_base + TX_FRAME_PORT, nic->node_addr, ETH_ALEN/2);
	outw(((t >> 8)&0xFF)|(t << 8), eth_nic_base + TX_FRAME_PORT);
	outsw(eth_nic_base + TX_FRAME_PORT, p, (s+1)/2);

	for (sr = sr/2 - (s+1)/2 - ETH_ALEN - 1; sr-- > 0;
	     outw(0, eth_nic_base + TX_FRAME_PORT));

	/* wait for transfer to succeed */
	for (tmo = currticks()+2*TICKS_PER_SEC;
	     (s = readreg(PP_TxEvent)&~0x1F) == 0 && currticks() < tmo;)
		/* nothing */ ;
	if ((s & TX_SEND_OK_BITS) != TX_OK) {
		printf("\ntransmission error %x\n", s);
		printf("PP_TxEvent %4x\n", readreg(PP_TxEvent));
	}

	return;
}

/**************************************************************************
ETH_POLL - Wait for a frame
***************************************************************************/

static int cs89x0_poll(struct nic *nic)
{
	int status;

	status = readreg(PP_RxEvent);

	if ((status & RX_OK) == 0) {
if (status & ~0x3f) printf("cs: PP_RxEvent %4x\n", status);
		return(0);
	}

	status = inw(eth_nic_base + RX_FRAME_PORT);
	nic->packetlen = inw(eth_nic_base + RX_FRAME_PORT);
	//printf("packet in! len %d (0x%x)\n", nic->packetlen, nic->packetlen);
	insw(eth_nic_base + RX_FRAME_PORT, nic->packet, nic->packetlen >> 1);
	if (nic->packetlen & 1)
		nic->packet[nic->packetlen-1] = inw(eth_nic_base + RX_FRAME_PORT);
	return 1;
}

static void cs89x0_disable(struct nic *nic)
{
	cs89x0_reset(nic);
}

/**************************************************************************
ETH_PROBE - Look for an adapter
***************************************************************************/

struct nic *cs89x0_probe(struct nic *nic, unsigned short *probe_addrs)
{

	int      i, result = -1, no_eeprom;
	unsigned rev_type = 0, ioaddr, ioidx, isa_cnf, cs_revision;
	unsigned short eeprom_buff[CHKSUM_LEN];

#if 0
	printf("timer test\n");
	{
		int loop = 0;

		while (1) {
			unsigned long tmo = currticks() + 2*TICKS_PER_SEC;
			printf("loop %d\n", ++loop);
			while (1) {
				if (currticks() >= tmo) {
					break;
				}
			}
			if (serial_poll())
				break;
		}
	}
#endif

	enable_pgmclock();

//	ioaddr = 0x40000300;
	ioaddr = 0x60000000;

	/* if they give us an odd I/O address, then do ONE write to
	   the address port, to get it back to address zero, where we
	   expect to find the EISA signature word. */
	if (ioaddr & 1) {
		ioaddr &= ~1;
		if ((inw(ioaddr + ADD_PORT) & ADD_MASK) != ADD_SIG)
			return 0;
		outw(PP_ChipID, ioaddr + ADD_PORT);
	}

#if 1
	{
		unsigned int sig;
		outw(PP_ChipID, ioaddr + ADD_PORT);
		sig = inw(ioaddr + DATA_PORT);
		if (sig != CHIP_EISA_ID_SIG) {
			printf("sig does not match; wanted %x, got %x\n",
			       CHIP_EISA_ID_SIG, sig);
		}
		printf("sig ok: %x\n", sig);
	}
#else
	if (inw(ioaddr + DATA_PORT) != CHIP_EISA_ID_SIG)
		return 0;
#endif
	eth_nic_base = ioaddr;
	no_eeprom = 0;

	/* get the chip type */
	rev_type = readreg(PRODUCT_ID_ADD);
	printf("rev_type %x\n", rev_type);

	eth_cs_type = rev_type &~ REVISON_BITS;
	cs_revision = ((rev_type & REVISON_BITS) >> 8) + 'A';

	printf("\ncs: cs89%c0%s rev %c, base %x",
	       eth_cs_type==CS8900?'0':'2',
	       eth_cs_type==CS8920M?"M":"",
	       cs_revision,
	       eth_nic_base);

	/* First check to see if an EEPROM is attached*/
	if ((readreg(PP_SelfST) & EEPROM_PRESENT) == 0) {
		printf("\ncs: no EEPROM...\n");
		outw(PP_ChipID, eth_nic_base + ADD_PORT);
		no_eeprom = 1;
//		return 0;
	}
	else if (get_eeprom_data(START_EEPROM_DATA,CHKSUM_LEN,
				 eeprom_buff) < 0) {
		printf("\ncs: EEPROM read failed...\n");
		outw(PP_ChipID, eth_nic_base + ADD_PORT);
		no_eeprom = 1;
//		return 0;
	}
	else if (get_eeprom_chksum(START_EEPROM_DATA,CHKSUM_LEN,
				   eeprom_buff) < 0) {
		printf("\ncs: EEPROM checksum bad...\n");
		outw(PP_ChipID, eth_nic_base + ADD_PORT);
		no_eeprom = 1;
//		return 0;
	}

	if (no_eeprom) {
		memset(eeprom_buff, 0, sizeof(eeprom_buff));

		/* eth_auto_neg_cnf */
		eeprom_buff[AUTO_NEG_CNF_OFFSET/2] = IMM_BIT;

		/* eth_adapter_cnf */
		eeprom_buff[ADAPTER_CNF_OFFSET/2] =
			A_CNF_10B_T | A_CNF_MEDIA_10B_T;

		eeprom_buff[0] = 0x0100;
		eeprom_buff[1] = 0x0302;
		eeprom_buff[2] = 0x0504;
	}

	/* get transmission control word but keep the
	   autonegotiation bits */
	eth_auto_neg_cnf = eeprom_buff[AUTO_NEG_CNF_OFFSET/2];
	/* Store adapter configuration */
	eth_adapter_cnf = eeprom_buff[ADAPTER_CNF_OFFSET/2];
	/* Store ISA configuration */
	isa_cnf = eeprom_buff[ISA_CNF_OFFSET/2];

	/* store the initial memory base address */
	eth_mem_start = eeprom_buff[PACKET_PAGE_OFFSET/2] << 8;

	printf("%s%s%s, addr ",
	       (eth_adapter_cnf & A_CNF_10B_T)?", RJ-45":"",
	       (eth_adapter_cnf & A_CNF_AUI)?", AUI":"",
	       (eth_adapter_cnf & A_CNF_10B_2)?", BNC":"");

	/* If this is a CS8900 then no pnp soft */
	if (eth_cs_type != CS8900 &&
	    /* Check if the ISA IRQ has been set  */
	    (i = readreg(PP_CS8920_ISAINT) & 0xff,
	     (i != 0 && i < CS8920_NO_INTS)))
		eth_irq = i;
	else {
		i = isa_cnf & INT_NO_MASK;
#if 0
		if (eth_cs_type == CS8900) {
			printf("\ncs: BUG: isa_config is %d\n", i);
		}
#endif
		eth_irq = i;
	}

	/* Retrieve and print the ethernet address. */
	for (i=0; i<ETH_ALEN; i++) {
		printf("%2x%s",
		       (int)(nic->node_addr[i] =
				    ((unsigned char *)eeprom_buff)[i]),
		       i < ETH_ALEN-1 ? ":" : "\n");
	}

	/* Set the LineCTL quintuplet based on adapter
	   configuration read from EEPROM */
	if ((eth_adapter_cnf & A_CNF_EXTND_10B_2) &&
	    (eth_adapter_cnf & A_CNF_LOW_RX_SQUELCH))
		eth_linectl = LOW_RX_SQUELCH;
	else
		eth_linectl = 0;

	/* check to make sure that they have the "right"
	   hardware available */
	switch(eth_adapter_cnf & A_CNF_MEDIA_TYPE) {
	case A_CNF_MEDIA_10B_T: result = eth_adapter_cnf & A_CNF_10B_T;
		break;
	case A_CNF_MEDIA_AUI:   result = eth_adapter_cnf & A_CNF_AUI;
		break;
	case A_CNF_MEDIA_10B_2: result = eth_adapter_cnf & A_CNF_10B_2;
		break;
	default: result = eth_adapter_cnf & (A_CNF_10B_T | A_CNF_AUI |
					     A_CNF_10B_2);
	}
	if (!result) {
		printf("cs: EEPROM is configured for unavailable media\n");
	error:
		writereg(PP_LineCTL, readreg(PP_LineCTL) &
			 ~(SERIAL_TX_ON | SERIAL_RX_ON));
		outw(PP_ChipID, eth_nic_base + ADD_PORT);
		return 0;
	}

	/* Initialize the card for probing of the attached media */
	cs89x0_reset(nic);

	/* set the hardware to the configured choice */
	switch(eth_adapter_cnf & A_CNF_MEDIA_TYPE) {
	case A_CNF_MEDIA_10B_T:
		result = detect_tp();
		if (!result) {
			clrline();
			printf("10Base-T (RJ-45%s",
			       ") has no cable\n"); }
		/* check "ignore missing media" bit */
		if (eth_auto_neg_cnf & IMM_BIT)
				/* Yes! I don't care if I see a link pulse */
			result = A_CNF_MEDIA_10B_T;
		break;
	case A_CNF_MEDIA_AUI:
		result = detect_aui(nic);
		if (!result) {
			clrline();
			printf("10Base-5 (AUI%s",
			       ") has no cable\n"); }
		/* check "ignore missing media" bit */
		if (eth_auto_neg_cnf & IMM_BIT)
				/* Yes! I don't care if I see a carrrier */
			result = A_CNF_MEDIA_AUI;
		break;
	case A_CNF_MEDIA_10B_2:
		result = detect_bnc(nic);
		if (!result) {
			clrline();
			printf("10Base-2 (BNC%s",
			       ") has no cable\n"); }
		/* check "ignore missing media" bit */
		if (eth_auto_neg_cnf & IMM_BIT)
				/* Yes! I don't care if I can xmit a packet */
			result = A_CNF_MEDIA_10B_2;
		break;
	case A_CNF_MEDIA_AUTO:
		writereg(PP_LineCTL, eth_linectl | AUTO_AUI_10BASET);
		if (eth_adapter_cnf & A_CNF_10B_T)
			if ((result = detect_tp()) != 0)
				break;
		if (eth_adapter_cnf & A_CNF_AUI)
			if ((result = detect_aui(nic)) != 0)
				break;
		if (eth_adapter_cnf & A_CNF_10B_2)
			if ((result = detect_bnc(nic)) != 0)
				break;
		clrline(); printf("no media detected\n");
		goto error;
	}
	clrline();
	switch(result) {
	case 0:                 printf("no network cable attached to configured media\n");
		goto error;
	case A_CNF_MEDIA_10B_T: printf("using 10Base-T (RJ-45)\n");
		break;
	case A_CNF_MEDIA_AUI:   printf("using 10Base-5 (AUI)\n");
		break;
	case A_CNF_MEDIA_10B_2: printf("using 10Base-2 (BNC)\n");
		break;
	}

	/* Turn on both receive and transmit operations */
	writereg(PP_LineCTL, readreg(PP_LineCTL) | SERIAL_RX_ON |
		 SERIAL_TX_ON);
	
//	if (ioaddr == 0)
//		return (0);

	nic->reset = cs89x0_reset;
	nic->poll = cs89x0_poll;
	nic->transmit = cs89x0_transmit;
	nic->disable = cs89x0_disable;

#if 0
{
	writereg(PP_SelfCTL, HCB1_ENBL | HCB0_ENBL);
	while (1) {
		writereg(PP_SelfCTL, HCB1_ENBL|HCB0_ENBL | HCB0);
		delayms(200);
		writereg(PP_SelfCTL, HCB1_ENBL|HCB0_ENBL | HCB1);
		delayms(200);
		if (serial_poll())
			break;
	}
}
#endif

#if 0
	printf("blast...\n");
	while (1) {
		send_test_pkt(nic);
		if (serial_poll())
			break;
	}
	printf("done.\n");
#endif

	return (nic);
}

/*
 * Local variables:
 *  c-basic-offset: 8
 * End:
 */

