/*
 */


#include "diag.h"
#include "lh7a400.h"
#include "serial-lh7a400.h"

#define printf xprintf

/* Optimization barrier */
/* The "volatile" is due to gcc bugs */
#define barrier() __asm__ __volatile__("": : :"memory")

UARTREGS *UART;

/*
 * flush serial input queue. returns 0 on success or negative error
 * number otherwise
 */
int
serial_flush_input(void)
{
    /*
     * keep on reading as long as the receiver is not empty
     * (errors are cleared by reading the register)
     */
    while( !(UART->fr & UART_FR_RXFE) ) {	/* Rx FIFO not empty */
	if( UART->dr & ( UART_DR_PE | UART_DR_FE | UART_DR_OE) ) {
	    return -1;
	}
    }
    return 0;
}


/*
 * flush output queue. returns 0 on success or negative error number
 * otherwise
 */
int
serial_flush_output(void)
{
    while( (UART->fr & UART_FR_TXFE) == 0)
	;

    return 0;
}

int
serial_set(which)
{
	switch (which) {
	case 1:
		UART = (UARTREGS *)0x80000600;
		break;
	case 2:
		UART = (UARTREGS *)0x80000700;
		break;
	case 3:
		UART = (UARTREGS *)0x80000800;
		{
		    gpioRegs_t *gpio = (gpioRegs_t *)0x80000e00;
		    gpio->pinmux |= GPIO_PINMUX_UART3ON;
		}
		break;

	default:
		return -1;
	}
	return 0;
}
/*
 * initialise serial port at the request baudrate. returns 0 on
 * success, or a negative error number otherwise
 */
int
serial_init(serial_baud_t baud)
{
    u32 divisor;

    /* get correct divisor */
    switch(baud) {
	case baud_9600:   divisor = UART_BCR_9600;   break;
	case baud_19200:  divisor = UART_BCR_19200;  break;
	case baud_38400:  divisor = UART_BCR_38400;  break;
	case baud_57600:  divisor = UART_BCR_57600;  break;
	case baud_115200: divisor = UART_BCR_115200; break;
	case baud_230400: divisor = UART_BCR_230400; break;

	default:
	    return -1;
    }

    /* Wait till it's not busy, then disable the UART */
    while( UART->fr & UART_FR_BUSY)
	;
	
    /*
     * the uart must be enabled to program the
     * other registers.
     */
    UART->cr = UART_CONTROL_EN;	/* Enable the UART */

    /* uart1 ? */
    if (UART == (UARTREGS *)0x80000600)
	UART->cr = UART_CONTROL_EN | UART_CONTROL_SIREN;
    
    /* switch receiver and transmitter off */
    UART->lcr = 0;
    barrier();

    /* Set the baud rate */
    UART->bcr = divisor;
    
    /* Enable FIFOs, 8 data bits, no parity, 1 Stop bit */
    UART->lcr = UART_LCR_FEN | UART_LCR_WLEN8;

    UART->intmask = 0;		/* clear interrupt mask bits  */
    UART->intraw  = 1;		/* clear any pending interrupts for the UART */

    return 0;
}


/*
 * check if there is a character available to read. returns 1 if there
 * is a character available, 0 if not.
 */
int
serial_poll(void)
{
    if( UART->fr & UART_FR_RXFE ) 		/* Rx FIFO empty? */
	return 0;				/* yes: "nothing available" */
    else 
	return 1;				/* no: "character available" */
}


/*
 * read one character from the serial port. return character (between
 * 0 and 255) on success, or negative error number on failure. this
 * function is blocking
 */
int
serial_read(void)
{
    int rv;
    u32 data;

    for(;;) {
	rv = serial_poll();

	if(rv > 0) {
	    /* get data and (possible) error */
	    data = UART->dr;

	    /* error ? */
	    if( data & (UART_DR_FE | UART_DR_PE) )
		return -1;

	    /* no error, return the data */
	    return data & UART_DR_DATAMASK;
	}
    }
}


/*
 * write character to serial port. return 0 on success, or negative
 * error number on failure. this function is blocking
 */
int
serial_write(int c)
{
    while( (UART->fr & UART_FR_TXFE) == 0)	/* wait for room in the TX fifo */
	;

    UART->dr = c & UART_DR_DATAMASK;			/* ship it */

    return 0;
}


int
putchar(int c)
{
	if (c == '\n')
		serial_write('\r');

	return serial_write(c);
}

int
puts(char *s)
{
	int c;
	while (c = *s++)
		putchar(c);
	return 0;
}

int
getchar(void)
{
	return serial_read();
}

int
iskey(void)
{
	if (serial_poll())
		return 1;
	return 0;
}

extern int ttynum;

void
ser_status(void)
{
}

void
ser_test_seq(int which)
{
    serial_set(which);
    serial_init(baud_9600);

    if (which == 1)
	UART->cr = UART_CONTROL_EN | UART_CONTROL_SIREN;

    puts("\n");
    puts("0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ\n");
    puts("0123456789abcdefghijklmnopqrstuvwxyz\n");
    puts("\n");

    serial_set(ttynum);
}

int
cmd_serial(int argc, char *argv[])
{
    int i;

    if (argc > 1 && strcmp(argv[1], "init") == 0) {
    }

    ser_status();

    printf("serial port 1:\n");

    ser_test_seq(1);

    printf("serial port 2:\n");
    ser_test_seq(2);

    printf("serial port 3:\n");
    ser_test_seq(3);

    printf("done\n");

    return 0;
}
