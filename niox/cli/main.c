/*
 * main.c
 *
 * $Id$
 */

#include "diag.h"

void
clear_bss(void)
{
	u_char *p;
	extern u_char __bss_start__, __bss_end__;

	for (p = &__bss_start__; p < &__bss_end__;)
		*p++ = 0;
}

void banner(void)
{
#if 0
	tv_write('A');
        tv_write('B');
        tv_write('C');
        tv_write('D');
        tv_write('E');
#endif

#if 0
        puts("testing printf\n");
        xprintf("testing printf %d \n", 12);
        xprintf("testing printf %d %d\n", 12, 34);
#endif

	puts("hello! ");
	puts("diag 0.0 ");
	puts(__DATE__);
	puts("\n");
}

#if 0
void quick_sdram_test(void)
{
    vu32 *p = (vu32 *)0x00100000;
    vu32 d;

    p[0] = 0x11112222;
    p[1] = 0x33334444;
    d = p[0];
    d = p[1];

    p[0] = 0x11112222;
    p[1] = 0x33334444;
    p[2] = 0x55556666;
    p[3] = 0x77778888;
    d = p[0];
    d = p[1];
    d = p[2];
    d = p[3];

    p[0] = 0x22221111;
    p[1] = 0x44443333;
    p[2] = 0x66665555;
    p[3] = 0x88887777;
    p[4] = 0xaaaa9999;
    p[5] = 0xccccbbbb;
    p[6] = 0xeeeedddd;
    p[7] = 0x12345678;
    d = p[0];
    d = p[1];
    d = p[2];
    d = p[3];
    d = p[4];
    d = p[5];
    d = p[6];
    d = p[7];

    p[1] = 0x1;
    p[3] = 0x2;

    d = p[0];
    d = p[1];
    d = p[2];
    d = p[3];

    asm volatile(".word 0x32");
    while (1);
}

void
quick_disk_read(void)
{
#define DISK_CONTROLLER	0xf7ffe0
#define SDRAM_START 0x00100000
    vu32 *pw = (vu32 *)SDRAM_START;
    vu32 *pd = (vu32 *)DISK_CONTROLLER;
    vu32 status;
    volatile int i;

    // write dram - command list
    pw[022] = 01001;
    pw[023] = 04000;

    // program disk controller
    status = pd[4];

    // disk da (block 0)
    pd[6] = 0;

    // load clp
    pd[5] = 022;

    // read
    pd[4] = 0;

    // start read
    pd[7] = 0;

    for (i = 0; i < 2000; i++)
        ;

    for (i = 0; i < 20000; i++) {
        status = pd[4];
        if ((status & 1))
            break;
    }

    asm volatile(".word 0x32");
    while (1);
}

volatile int x;

void do_test(int h)
{
    x = 0;
    if (h < -1) {
        x = 1;
    }
    if (h > 896) {
        x = 2;
    }
}
#endif

main()
{
#if 0
    do_test(-2);
    do_test(900);
    while (1);
#endif

#if 0
    quick_sdram_test();
#endif

#if 0
    quick_disk_read();
#endif

    tv_blob();
    clear_bss();
    serial_init();
    banner();
    cli_init();
    cli();

    while (1);
}


/*
 * Local Variables:
 * indent-tabs-mode:nil
 * c-basic-offset:4
 * End:
*/
