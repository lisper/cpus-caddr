#include "diag.h"

#define printf xprintf

void exit(int s)
{
	while (1);
}

void abort(void)
{
	while (1);
}

int serial_init(void)
{
	tv_init();
}

char kb_map[] = {
	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
	0x00, 0x34, 0x72, 0x66, 0x76, 0x00, 0x00, 0x00,
	0x20, 0x00, 0x09, 0x7f, 0x20, 0x20, 0x20, 0x00,
	0x00, 0x38, 0x69, 0x6b, 0x2c, 0x00, 0x00, 0x5c,
	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
	0x00, 0x36, 0x79, 0x68/*0x67*/, 0x6e, 0x00, 0x00, 0x00,
	0x00, 0x32, 0x77, 0x73, 0x78, 0x00, 0x00, 0x00,
	0x00, 0x39, 0x6f, 0x6c, 0x2e, 0x00, 0x00, 0x60,
	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
	0x00, 0x35, 0x74, 0x67, 0x62, 0x00, 0x00, 0x00,
	0x00, 0x31, 0x71, 0x61, 0x7a, 0x20, 0x3d, 0x00,
	0x00, 0x2d, 0x5b, 0x27, 0x20, 0x00, 0x0d, 0x5d,
	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
	0x00, 0x37, 0x75, 0x6a, 0x6d, 0x00, 0x00, 0x00,
	0x00, 0x33, 0x65, 0x64, 0x63, 0x00, 0x00, 0x00,
	0x00, 0x30, 0x70, 0x3a, 0x2f, 0x00, 0x00, 0x00
};

#define KEYBOARD 0xffd080

static int kb_state;
static int kb_full;
static int kb_char;

int kb_check(void)
{
	vu32 *kb = (vu32 *)KEYBOARD;
	vu32 kl, kh, csr;

	csr = kb[5];

	if ((csr & 0x20) == 0)
		return;

	kl = kb[0];
	kh = kb[1];

	if (kh == 0)
		return 0;

	switch (kb_state) {
	case 0:
		// look for key down
		if ((kl & 0x100) == 0) {
			kb_char = kb_map[kl & 0x7f];
			kb_full = 1;
			kb_state = 1;
			//printf("[%x %x => %x]\n", kl, kh, kb_char);
			return 1;
		}
		break;
	case 1:
		// look for key up
		if (kl & 0x100)
			kb_state = 0;
#if 0
		else {
			// repeat
			kb_char = kb_map[kl & 0x7f];
			kb_full = 1;
			kb_state = 1;
			//printf("[%x %x => %x]\n", kl, kh, kb_char);
			return 1;
		}
#endif
		break;
	}

	return 0;
}

int kb_data(void)
{
	int ret;
	
	ret = kb_full ? kb_char : 0;
	kb_full = 0;
	return ret;
}

int
serial_poll(void)
{
	if (kb_check())
		return 1;

//    if( UART->fr & UART_FR_RXFE ) 		/* Rx FIFO empty? */
//	return 0;				/* yes: "nothing available" */
//    else 
//	return 1;				/* no: "character available" */
	return 0;
}

serial_write(int c)
{
//    while( (UART->fr & UART_FR_TXFE) == 0)	/* wait for room in the TX fifo */
//	;
//
//    UART->dr = c & UART_DR_DATAMASK;			/* ship it */
//
    tv_write(c);
    return 0;
}

int
serial_read(void)
{
    int rv;
    u_char data;

    for(;;) {
	rv = serial_poll();

	if(rv > 0) {
		return kb_data();
//	    /* get data and (possible) error */
//	    data = UART->dr;
//
//	    /* error ? */
//	    if( data & (UART_DR_FE | UART_DR_PE) )
//		return -1;
//
//	    /* no error, return the data */
//	    return data & UART_DR_DATAMASK;
//		return 0;
	}
    }
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

/*
?ASlink-Warning-Undefined Global _putchar referenced by module readline.c
?ASlink-Warning-Undefined Global _xprintf referenced by module cli.c
?ASlink-Warning-Undefined Global _puts referenced by module main.c

?ASlink-Warning-Undefined Global ___bss_start__ referenced by module main.c
?ASlink-Warning-Undefined Global _printf referenced by module readline.c
?ASlink-Warning-Undefined Global ___bss_end__ referenced by module main.c

?ASlink-Warning-Undefined Global _getchar referenced by module readline.c
*/
