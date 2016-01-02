/*
 * cs8900.h  header for the cs8900 driver on the
 * Sharp LH79520 and LH7A400 Evaluation Boards.
 * 
 * Copyright (C) 2001 SHARP MICROELECTRONICS OF THE AMERICAS, INC.
 *		CAMAS, WA
 *
 * Portions Copyright (C) 2002 Lineo.
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
 *	References:
 *		(1) ARM Isis Technical Reference Manual, System on Chip Group,
 *		ARM SC063-TRM-0001-C
 *
 */


/*
 * Typedefs
 */
// List of read ports
typedef enum {rxd0, rxd1, unused_r1, unused_r2, isq, ppptr, pd0, pd1}
	rx_port_t;

// List of write ports - ppptr, pd0, and pd1 are shared with read enums
typedef enum {txd0, txd1, txcmd, txlen, unused_t1}
	tx_port_t;

 
 
/*
 * PacketPage register layout
 */

// The following structures are not too useful for an IO mapped
// architecture, but they can be used to determine offsets in the
// PacketPage atructures to registers and data.

// CS8900A bus interface control registers
// Address range 0x0000 - 0x00FE
typedef struct __attribute__ ((packed)) {
   u16        chip_id_h;       // Chip ID register high
   u16        chip_id_l;       // Chip ID register low
   u16        reserved_1 [14];
   u16        io_base_addr;    // IO base address
   u16        int_num;         // Interrupt number
   u16        dma_channel;     // DMA channel
   u16        dma_sof;         // DMA start of frame
   u16        dma_frame_cnt;   // DMA frame count
   u16        dma_byte_cnt;    // DMA byte count
   u16        mem_base_h;      // Memory base address high
   u16        mem_base_l;      // Memory base address low
   u16        boot_pr_addr_h;  // Boot PROM base address high
   u16        boot_pr_addr_l;  // Boot PROM base address low
   u16        boot_pr_mask_h;  // Bot PROM address mask high
   u16        boot_pr_mask_l;  // Bot PROM address mask low
   u16        reserved_2 [4];
   u16        eeprom_cmd;      // EEPROM command
   u16        eeprom_data;     // EEPROM data
   u16        reserved_3 [6];
   u16        rxfr_byte_cnt;   // RX frame byte count
   u16        reserved_4 [87];
} cs8900_8900bus_t;

// CS8900A status and control registers
// Address range 0x0100 - 0x0142
typedef struct __attribute__ ((packed)) {
   u16        reserved_1;
   u16        reg3_rxcfg;      // Register 3 - RXCFG
   u16        reg5_rxctl;      // Register 5 - RXCTL
   u16        reg7_txcfg;      // Register 7 - TXCFG
   u16        reg9_txcmd;      // Register 9 - TXCMD (status)
   u16        regb_bufcfg;     // Register B - BufCFG
   u16        reserved_2 [3];
   u16        reg13_linectl;   // Register 13 - LineCTL
   u16        reg15_selfctl;   // Register 15 - SelfCTL
   u16        reg17_busctl;    // Register 17 - BusCTL
   u16        reg19_testctl;   // Register 19 - TestCTL
   u16        reserved_3 [3];
   u16        reg0_isq;        // Register 0 - Interrupt status Queue
   u16        reserved_4;
   u16        reg4_rxevent;    // Register 4 - RxEvent
   u16        reserved_5;
   u16        reg8_txevent;    // Register 8 - TxEvent
   u16        reserved_6;
   u16        regc_bufevent;   // Register C - BufEvent
   u16        reserved_7;
   u16        reg10_rxmiss;    // Register 10 - RX miss counter
   u16        reg12_txcol;     // Register 12 - TX collision clear
   u16        reg14_linest;    // Register 14 - Line status
   u16        reg16_selfst;    // Register 16 - Self status
   u16        reg18_busst;     // Register 18 - Bus status
   u16        reserved_8;
   u16        reg1c_tdr;       // Register 1C - Time domain ref counter
   u16        reserved_9 [3];
} cs8900_8900stco_t;

// CS8900A transmit initiate registers
// Address range 0x0144 - 0x014E
typedef struct __attribute__ ((packed)) {
   u16        txcmd;           // Transmit command
   u16        txlen;           // Transmit length
   u16        reserved_1 [4];
} cs8900_8900tran_t;

// CS8900A address filter registers
// Address range 0x0150 - 0x015E
typedef struct __attribute__ ((packed)) {
   u8         hash_filter [8]; // Logical address filter
   u8         enet_address [6];// Ethernet IEEE address
   u8         reserved_1 [674];
} cs8900_8900filter_t;

// CS8900A Frame location(s)
// Address range 0x0400 - 0x0A00
typedef struct __attribute__ ((packed)) {
   u16        rx_status;       // Receive status
   u16        rxlen;           // Receive length
   u16        rxfr_loc [0xA00 - 0x404];
                                  // Receive frame location
   u16        txfr_loc;        // Transmit frame location
} cs8900_8900frame_t;

// CS8900 PacketPage structure
typedef struct __attribute__ ((packed)) {
   cs8900_8900bus_t     bus_regs;
   cs8900_8900stco_t    stco_regs;
   cs8900_8900tran_t    tx_regs;
   cs8900_8900filter_t  filter_regs;
   cs8900_8900frame_t   frame_regs;
} cs8900_pp_t;

/*****************************************************************************
 * Register attributes and layout - bus interface registers
 ****************************************************************************/
 
// Interrupt values - int_num register
typedef enum {INTR0 = 0x0, INTR1 = 0x1, INTR2 = 0x2, INTR3 = 0x3,
   INTR_NONE = 0x4} enet_int_t;

// DMA values - dma_channel register
typedef enum {DMA0 = 0x0, DMA1 = 0x1, DMA2 = 0x2,
   DMA_NONE = 0x3} enet_dma_t;

// EEPROM command bits used with EEPROM command word
#define EEPROM_WRITE      0x0100
#define EEPROM_READ       0x0200
#define EEPROM_EW_ENABLE  0x0030
#define EEPROM_EW_DISABLE 0x0000


/*****************************************************************************
 * Register identification
 ****************************************************************************/

// Register 0 - Interrupt status queue bits - this mask is also shared with
// all the individual status and control registers and the Interrupt status
// queue port register - the value obtained with this mask is used to identify
// the source of an interrupt and where the data for the interrupt resides
#define REGNUM_MASK       0x003F    // Interrupt # mask (register number)

// Register identification list - obtained from the interrupt status queue or
// an individual register and the REGNUM_MASK mask value. In general, status
// registers are Read-Only (RO), while control and configuration registers
// are Read-Write (RW). When an interrupt occurs, the lower 6 bits of the
// interrupt status queue (masked with REGNUM_MASK) will designate which
// register contains the information for the present interrupt
#define RRXCFG            0x0003    // Receiver configuration register (RW)
#define RRXEVENT          0x0004    // Receiver event status register  (RO)
#define RRXCTL            0x0005    // Receiver control register       (RW)
#define RTXCFG            0x0007    // Transmitter configuration reg   (RW)
#define RTXEVENT          0x0008    // Transmitter event status reg    (RO)
#define RTXCMD            0x0009    // Transmit command status reg     (RO)
#define RBUFCFG           0x000B    // Buffer configuration register   (RW)
#define RBUFEVENT         0x000C    // Buffer event status register    (RO)
#define RRXMISS           0x0010    // Receiver missed frame status reg(RO)
#define TXCMD             0x0011    // TX command reg (WO)
#define RTXCOL            0x0012    // Transmitter collision count reg (RO)
#define RLINECTL          0x0013    // Line control register           (RW)
#define RLINEST           0x0014    // Line status register            (RO)
#define RSELFCTL          0x0015    // Self control register           (RW)
#define RSELFST           0x0016    // Self status register            (RO)
#define RBUSCTL           0x0017    // Bus control register            (RW)
#define RBUSST            0x0018    // Bus status register             (RO)
#define RTESTCTL          0x0019    // Test control register           (RW)
#define RAUIRELF          0x001C    // AUI time domain reflectometer   (RO)

/*****************************************************************************
 * Register attributes and layout - Control registers
 ****************************************************************************/

// Register 3 - Receiver configuration bits
#define SKIP_1            0x0040    // Delete last received frame
#define STREAME           0x0080    // Automatically transfer frames via DMA
#define RXOKIE            0x0100    // Interrupt when good RX frame received
#define RXDMA_ONLY        0x0200    // Use DMA only for RX frames
#define AUTORX_DMAE       0x0400    // Auto-switch to DMA for receive
#define BUFFERCRC         0x0800    // Include CRC in RX buffer
#define CRCERRORIE        0x1000    // Interrupt on RX frame CRC error
#define RUNTIE            0x2000    // Interrupt on short RX frame
#define EXTADATAIE        0x4000    // Interrupt on long RX frame

// Register 5 - Receiver control bits
#define IAHASHA           0x0040    // Accept frames that pass hash filter
#define PROMISUCOUSA      0x0080    // Accept all incoming frames
#define RXOKA             0x0100    // Accept valid RX frames
#define MULTICASTA        0x0200    // Accept multicast frames that pass hash
#define INDIVIDUALA       0x0400    // Accept frames that pass individual addr
#define BROADCASTA        0x0800    // Accept broadcase frames
#define CRCERRORA         0x1000    // Accept frames with a bad CRC
#define RUNTA             0x2000    // Accept short frames
#define EXTADATAA         0x4000    // Accept long frames

// Register 7 - Transmitter configuration bits
#define LOSSOFCRIE        0x0040    // Interrupt on loss of carrier (on TX)
#define SQERRORIE         0x0080    // Interrupt on SQE error
#define TXOKIE            0x0100    // Interrupt on good TX frame completion
#define OUTOFWINDOWIE     0x0200    // Interrupt on late collision
#define JABBERIE          0x0400    // Interrupt on long transmission (time)
#define ANYCOLLIE         0x0800    // Interrupt on any collision (on TX)
#define COLL16IE          0x8000    // Interrupt on 16th collision (on TX)

// Register B - Buffer configuration bits
#define SWINT_X          0x0040     // Generate an interrupt (software)
#define RXDMAIE          0x0080     // Interrupt on RX frame DMA complete
#define RDY4TXIE         0x0100     // Interrupt when ready to accept next TX frame
#define TXUNDERRUNIE     0x0200     // Interrupt TX frame underrun error
#define RXMISSIE         0x0400     // Interrupt on missed RX frame
#define RX128IE          0x0800     // Interrupt on start of RX frame
#define TXCOLOVIE        0x1000     // Interrupt on TX collision counter overflow
#define MISSOVIE         0x2000     // Interrupt on missed frame counter overflow
#define RXDESTIE         0x8000     // Interrupt on match of RX frame to individ ad

// Register 13 - Line control bits
#define SERRXON          0x0040     // Receiver enabled
#define SERTXON          0x0090     // Transmitter enabled
#define AUIONLY          0x0100     // AUI/10Base-T selection bit
#define AUTOAUI          0x0200     // Autoselect AUI or 10Base-T
#define MODBACKOFFE      0x0800     // Used modified TX backoff alogrithm
#define POLARITYDIS      0x1000     // Do not automatically correct polarity
#define DIS2PARTDEF      0x2000     // Disable 2-part deferral
#define LORXSQUELCH      0x4000     // Reduce squelch thresholds

// Register 15 - Self control bits
#define RESET            0x0040     // Perform chip reset
#define SWSUSPEND        0x0100     // Enter suspend mode
#define HWSLEEPIE        0x0200     // Enter sleep mode
#define HWSTANDBYE       0x0400     // Standby/Sleep enable
#define HC0E             0x1000     // LINKLED led/HC0 output selection
#define HC1E             0x2000     // BSTATUS led/HC1 output selection
#define HCB0             0x4000     // State of HC0 pin
#define HCB1             0x8000     // State of HC1 pin

// Register 16 - Self status bits
#define INITD			0x0080		// Chip initialization complete
#define SIBUSY			0x0100		// EEPROM is busy

// Register 17 - Bus control bits
#define RESETRXDMA       0x0040     // Reset DMA RX offset pointer
#define DMAEXTEND        0x0100     // Modify DMA signal timing
#define USESA            0x0200     // Enable MEMCS16 on SA12..19 match
#define MEMORYE          0x0400     // Enable memory mode
#define DMABURST         0x0800     // Limit DMA transfers to bursts
#define IOCHRDYE         0x1000     // Disable IOCHRDY signal
#define RXDMASIZE        0x2000     // Set DMA buffer size to 64K
#define ENABLERQ         0x8000     // Enable interrupt generation

// Register 19 - Test control bits
#define DISABLELT        0x0080     // Allow transfers regardless of link status
#define ENDECLOOP        0x0200     // Enable ENDEC loopback mode
#define AUILOOP          0x0400     // Enable AUI loopback mode
#define DISABLEBACKOFF   0x0800     // Disable backoff algorithm
#define FDX              0x4000     // Enable 10Base-T full duplex mode

/*****************************************************************************
 * Register attributes and layout - Status registers
 ****************************************************************************/

// Register 4 - Receiver event bits
#define IAHASH            0x0040    // Receive frame's DA was accepted
#define DRIBBLEBITS       0x0080    // Extra bits received after last byte
#define RXOK              0x0100    // RX frame has good length and CRC
#define HASHED            0x0200    // DA was accepted by the hash filter
#define INDIVID_ADDR      0x0400    // RX frame matched DA
#define BROADCAST         0x0800    // Broadcast RX frame received
#define CRCERROR          0x1000    // Bad CRC in the RX frame
#define RUNT              0x2000    // RX frame shorter than 64 bytes
#define EXTRADATA         0x4000    // RX frame longer than 1518 bytes
#define HASH_TBL_MASK     0xFC00    // Hash table index mask

// Register 8 - Transmit event bits
#define LOSSOFCRS         0x0040    // No carrier at end of preamble
#define SQERROR           0x0080    // No collision on AUI
#define TXOK              0x0100    // Last TX frame transmitted OK
#define OUTOFWINDOW       0x0200    // Late collision
#define JABBER            0x0400    // Last tranmission too long
#define TXCOL_MASK        0x7800    // Number of collisions on last packet
#define COLL16            0x8000    // Too many collisions on packet

// Register 9 - TX command status
#define TXSTART           0x00C0    // Buffer load prior to transfer (mask)
#define FORCE             0x0100    // Force termination of any existing TX frames
#define ONECOLL           0x0200    // Stop transfer on any collision
#define INHIBITCRC        0x1000    // Do not append CRC to transmission
#define TXPADDIS          0x2000    // Disable TX frame passing

#define TX_START_5        0x0000    // Start transfer after 5 bytes are buffer
#define TX_START_381      0x0040    // Start transfer after 381 bytes are buffer
#define TX_START_1021     0x0080    // Start transfer after 1021 bytes are buffer
#define TX_START_ALL      0x00C0    // Start transfer after frame is buffered

// Register C - Buffer event status bits
#define SWINT             0x0040    // Software initiated interrupt
#define RXDMAFRAME        0x0080    // One or more frames transferred via DMA
#define RDY4TX            0x0100    // Ready to accept TX frame for transfer
#define TXUNDERRUN        0x0200    // Ran out of data on transfer
#define RXMISS            0x0400    // RX frame(s) have been lost
#define RX128             0x0800    // 128 bytes on an incoming frame received
#define RXDEST            0x8000    // Incoming frame passed RX DA filter

// Register 10 - Receive miss counter
#define MISSCOUNT_MASK    0xFFC0    // Running count of missed RX frames mask

// Register 12 - Transmit collision counter
#define COLCOUNT_MASK     0xFFC0    // Running count of transmit collisions mask

// Register 14 - Line status bits
#define LINKOK            0x0080    // 10Base-T link ok
#define AUI               0x0100    // AUI link ok
#define BT10              0x0200    // 10Base-T link active
#define POLARITYOK        0x1000    // 10Base-T polarity is correct
#define CRS               0x4000    // Frame is currently being received

// Register 16 - Self status bits
#define ACTIVE33          0x0040    // Power supply is 3.3v
#define INITD             0x0080    // CS8900A reset initialization is complete
#define SIBUSY            0x0100    // EEPROM is currently being accessed
#define EE_PRESENT        0x0200    // EEPROM is present
#define EEOK              0x0400    // EEPROM checksum was OK on last readout
#define EL_PRESENT        0x0800    // External EEPROM decode logic is present
#define EESIZE            0x1000    // EEPROM size bit

// Register 18 - Bus status bits
#define TXBIDERROR        0x0080    // Request to transmit will not be honored
#define RDY4TXNOW         0x0100    // Same as RDY4TX bit in register C

// Register 1C - AUI time domain reflectometer counter
#define AUICOUNT_MASK     0xFFC0    // Time domain count mask

/*****************************************************************************
 * Ethernet packet structure
 ****************************************************************************/

// Basic data frame
typedef struct
{
   u8    daddr [6];          // Destination ethernet address
   u8    saddr [6];          // Source ethernet address
   u16   datalen;            // Data buffer length
   u8    buffer [1550];      // Data buffer
} buffer_t;

#define CS8900_CHIP_ID	0x630e

