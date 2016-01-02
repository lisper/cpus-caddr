/*
 * serial-lh7a400.h: Sharp LH7A400 serial port header
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
 */

#ifndef LH7A400_SERIAL_H
#define LH7A400_SERIAL_H

#include "types.h"

typedef enum {
	baud_9600 = 1,
	baud_19200,
	baud_38400,
	baud_57600,
	baud_115200,
	baud_230400
} serial_baud_t;

/**********************************************************************
 * UART Module Register Structures
 *********************************************************************/
typedef struct {
    volatile u32	dr;		/* Data */ 
    volatile u32	lcr;		/* Line Control */ 
    volatile u32	bcr;		/* Baud Rate Control */ 
    volatile u32	cr;		/* Control */ 
    volatile u32	fr;		/* Flag register */
    volatile u32	intraw;		/* Raw Interrupt */ 
    volatile u32	intmask;	/* Interrupt Mask */ 
    volatile u32	intres;		/* Resultant Interrupt */ 
} UARTREGS;

/**********************************************************************
 * UART Data Register Bit Fields
 *********************************************************************/
#define UART_DR_DATAMASK	(0xFF)		/* Data (8 bits) */ 
#define UART_DR_FE		_BIT(8)		/* Framing Error */ 
#define UART_DR_PE		_BIT(9)		/* Parity Error */ 
#define UART_DR_OE		_BIT(10)	/* Overrun Error */ 
#define UART_DR_BE		_BIT(11)	/* Break Error */ 

/**********************************************************************
 * UART Line Control Register Bit Fields
 *********************************************************************/
#define UART_LCR_SENDBRK	_SBF(0,1)	/* Send Break */ 
#define UART_LCR_PEN		_SBF(1,1)	/* Parity Enable */ 
#define UART_LCR_EPS		_SBF(2,1)	/* Even Parity Select */ 
#define UART_LCR_STP2		_SBF(3,1)	/* Two Stop Bits Select */ 
#define UART_LCR_FEN		_SBF(4,1)	/* FIFO Enable */ 
#define UART_LCR_WLEN5		_SBF(5,0)	/* 5 bits */ 
#define UART_LCR_WLEN6		_SBF(5,1)	/* 6 bits */ 
#define UART_LCR_WLEN7		_SBF(5,2)	/* 7 bits */ 
#define UART_LCR_WLEN8		_SBF(5,3)	/* 8 bits */ 

/**********************************************************************
 * UART Baud Rate Control Register Bit Field
 *********************************************************************/
#define UART_BCR(n)		_SBF(0,((n)&0xFFFF)	/* Clear To Send */ 
/* The following assume a UART clock frequency of 7.3728 MHz */ 
#define UART_BCR_2400		_SBF(0,0xBF)
#define UART_BCR_4800		_SBF(0,0x5F)
#define UART_BCR_9600		_SBF(0,0x2F)
#define UART_BCR_19200		_SBF(0,0x17)
#define UART_BCR_28800		_SBF(0,0xF)
#define UART_BCR_38400		_SBF(0,0xB)
#define UART_BCR_57600		_SBF(0,0x7)
#define UART_BCR_115200		_SBF(0,0x3)
#define UART_BCR_153600		_SBF(0,0x2)
#define UART_BCR_230400		_SBF(0,0x1)
#define UART_BCR_460800		_SBF(0,0x0)

/**********************************************************************
 * UART Control Register Bit Fields
 *********************************************************************/
#define UART_CONTROL_EN		_BIT(0)		/* UART Enable */ 
#define UART_CONTROL_SIREN	_BIT(1)		/* SIR Enable */ 
#define UART_CONTROL_SIRLP	_BIT(2)		/* IrDA SIR Low Power Mode */ 
#define UART_CONTROL_RXP	_BIT(3)		/* Receive Pin Polarity Select*/ 
#define UART_CONTROL_TXP	_BIT(4)		/* Xmit Pin Polarity Select */ 
#define UART_CONTROL_MXP	_BIT(5)		/* Modem Polarity Select */ 
#define UART_CONTROL_LBE	_BIT(6)		/* Loop Back Enable */ 
#define UART_CONTROL_SIRBD	_BIT(7)		/* SIR Blanking Disable */ 

/**********************************************************************
 * UART Flag Register Bit Fields
 *********************************************************************/
#define UART_FR_CTS		_BIT(0)		/* Clear To Send */ 
#define UART_FR_DSR		_BIT(1)		/* Data Set Ready */ 
#define UART_FR_DCD		_BIT(2)		/* Data Carrier Detect */ 
#define UART_FR_BUSY		_BIT(3)		/* Transmitter Busy */ 
#define UART_FR_RXFE		_BIT(4)		/* RX FIFO Empty */ 
#define UART_FR_TXFF		_BIT(5)		/* TX FIFO Full */ 
#define UART_FR_RXFF		_BIT(6)		/* RX FIFO Full */ 
#define UART_FR_TXFE		_BIT(7)		/* TX FIFO Empty */ 

/**********************************************************************
 * UART Interrupt Registers Bit Fields
 * intraw, intmask, intres
 *********************************************************************/
#define UART_INT_RI		_BIT(0)		/* Receive Interrupt */ 
#define UART_INT_TI		_BIT(1)		/* Transmit Interrupt */ 
#define UART_INT_MI		_BIT(2)		/* Modem Interrupt */ 
#define UART_INT_RTI 		_BIT(3)		/* Receive Timeout Interrupt */ 

/*
 * Clock to the UARTs
 */
#define UART_CLK 14745600	/* 14 MHz */


#endif /* LH7A400_SERIAL_H */ 
