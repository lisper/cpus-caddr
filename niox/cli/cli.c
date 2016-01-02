/*
 * cli.c
 *
 * $Id: cli.c,v 1.4 2005/03/10 14:07:05 brad Exp $
 */

#include "diag.h"

#define printf xprintf

#define NULL 0
#define MAX_LINE 256
#define MAX_ARGV 32

#define CLI_PROMPT "diag> "

int argc;
char *argv[MAX_ARGV];

static char line[MAX_LINE];
static char line2[MAX_LINE];

int cmd_help(int argc, char *argv[]);

#define DISK_CONTROLLER	0xf7ffe0
#define DISK_DEBUG	0xf7ffc0
#define SPY_CONTROLLER	0xffb000
#define SDRAM_START 0x00100000

#if 0
int
cmd_spy(int argc, char *argv[])
{
    vu32 *ps = (vu32 *)SPY_CONTROLLER;
    vu32 r0, r1, r2, r3;
    int i;

    r0 = ps[0];
    r1 = ps[1];
    r2 = ps[2];
    r3 = ps[3];
    
    printf("spy:\n");
    printf("reg0 %x\n", r0);
    printf("reg1 %x\n", r1);
    printf("reg2 %x\n", r2);
    printf("reg3 %x\n", r3);

    // start, read
    ps[2] = 0x05;

    // wait for rdy
    while (1) {
        r0 = ps[0];
        printf("reg0 %x\n", r0);
        if (r0 & 4)
            break;
    }

    for (i = 0; i < 5/*512*/; i++) {
        while (1) {
            // wait for iordy
            r0 = ps[0];
            if (r0 & 1) {
                // bd_rd
                r1 = ps[1];
                ps[2] = 0x08;
                ps[2] = 0x00;
                printf("data %x %x\n", r0, r1);
                break;
            }
        }
    }

    return -1;
}
#endif

int
cmd_disk_read(int argc, char *argv[])
{
    vu32 *pw = (vu32 *)SDRAM_START;
    vu32 *pd = (vu32 *)DISK_CONTROLLER;
    vu32 status;
    int i, block;

    block = 0;
    if (argc > 2) {
        if (getnumber(argv[2], &block)) {
            printf("bad block number '%s'\n", argv[1]);
            return -1;
        }
    }
    printf("block %d\n", block);

    for (i = 0; i < 256; i++)
        pw[01000 + i] = 0;

    // write dram - command list
//    pw[022] = 01001;
//    pw[023] = 04000;
    pw[022] = 01000;
    pw[023] = 0;

    // program disk controller
    status = pd[4];
    printf("status %x\n", status);
    status = pd[4];
    printf("status %x\n", status);

    // disk da (block 0)
    pd[6] = block;

    // load clp
    pd[5] = 022;

    // read
    pd[4] = 0;

    // start read
    pd[7] = 0;

    //
    status = pd[4];
    printf("status %x\n", status);

    for (i = 0; i < 500000; i++) {
        status = pd[4];
        if ((status & 1))
            break;
    }

    printf("status %x\n", status);

    return 0;
}

int
cmd_disk_write(int argc, char *argv[])
{
    vu32 *pw = (vu32 *)SDRAM_START;
    vu32 *pd = (vu32 *)DISK_CONTROLLER;
    vu32 status;
    int i, block;

    block = 1;
    if (argc > 2) {
        if (getnumber(argv[2], &block)) {
            printf("bad block number\n");
            return -1;
        }
    }
    printf("block %d\n", block);

    for (i = 0; i < 256; i++)
        pw[01000 + i] = 0;

    // write dram - command list
//    pw[022] = 01001;
//    pw[023] = 04000;
    pw[022] = 01000;
    pw[023] = 0;

#if 1
    pw[01000 + 0] = 0x11112222;
    pw[01000 + 1] = 0x33334444;
    pw[01000 + 2] = 0x55556666;
    pw[01000 + 3] = 0x12345678;
    pw[01000 + 4] = 0x87654321;
#else
    {
        unsigned char n;
        vu32 v;
        n = 0;
        for (i = 0; i < 256; i++) {
            v = ((n+0) << 24) |
                ((n+1) << 16) |
                ((n+2) << 8) |
                ((n+3) << 0);
            pw[01000 + i] = v;
            n += 4;
        }
    }
#endif

    // program disk controller
    status = pd[4];
    printf("status %x\n", status);

    // disk da (block 1)
    pd[6] = 1;

    // load clp
    pd[5] = 022;

    // write
    pd[4] = 011;

    // start write
    pd[7] = 0;

    //
    status = pd[4];
    printf("status %x\n", status);

    for (i = 0; i < 500000; i++) {
        status = pd[4];
        if ((status & 1))
            break;
    }

    printf("status %x\n", status);
    return 0;
}

int
cmd_disk_regs(int argc, char *argv[])
{
    vu32 *pd = (vu32 *)DISK_CONTROLLER;
    vu32 status;
    int i;

    for (i = 0; i < 8; i++) {
        status = pd[i];
        printf("reg[%d] = %x\n", i, status);
    }

    {
        vu32 state, led_state, disk_state, bd_state, mmc_state, wc, bd_data;

        pd = (vu32 *)DISK_DEBUG;
        status = pd[7];
        disk_state = status & 0x1f;
        led_state = (status >> 5) & 0x1f;
        bd_state = (status >> 10) & 0xfff;

        mmc_state = (bd_state >> 6) & 0x3f;
        bd_state &= 0x3f;

        printf("----\n");
        printf("debug[7] %x\n", status);
        printf(" led_state 0x%x\n", led_state);
        printf(" disk_state %d (0x%x)\n", disk_state, disk_state);
        printf(" bd_state   %d (0x%x)\n", bd_state, bd_state);
        printf(" mmc_state  %d (0x%x)\n", mmc_state, mmc_state);

        status = pd[6];
        printf("debug[6] 0x%x\n", status);
        bd_data = status & 0xff;
        wc = (status >> 16) & 0xff;

        printf(" wc %d (0x%x)\n", wc, wc);
        printf(" bd_data 0x%x\n", bd_data);

        status = pd[5];
        printf("debug[5] 0x%x\n", status);

        status = pd[4];
        printf("debug[4] 0x%x\n", status);

    }
}

int
cmd_disk(int argc, char *argv[])
{
    if (argc < 2) {
        printf("disk { read | write | stat | regs}\n");
        return -1;
    }

    if (strcmp(argv[1], "stat") == 0) {
        vu32 *pd = (vu32 *)DISK_CONTROLLER;
        vu32 status;

        status = pd[4];
        printf("status %x\n", status);
    }

    if (strcmp(argv[1], "regs") == 0) {
        return cmd_disk_regs(argc, argv);
    }

    if (strcmp(argv[1], "read") == 0) {
        return cmd_disk_read(argc, argv);
    }

    if (strcmp(argv[1], "write") == 0) {
        return cmd_disk_write(argc, argv);
    }

    return -1;
}

#if 0
int
cmd_mmc(int argc, char *argv[])
{
    return -1;
}
#endif

int
cmd_mem(int argc, char *argv[])
{
    vu32 *pw, vw;
    int i, size, err;

    err = 0;
    pw = (vu32 *)SDRAM_START;

    if (argc < 2) {
        printf("mem { big | med | small }\n");
        return -1;
    }

    if (strcmp(argv[1], "big") == 0) {
        size = 64*1024;
    }

    if (strcmp(argv[1], "med") == 0) {
        size = 4096;
    }

    if (strcmp(argv[1], "small") == 0) {
        size = 8;
    }

    printf("memory test, size=%d\n", size);

    if (1) {
        for (i = 0; i < size; i++)
            pw[i] = i;

        for (i = 0; i < size; i++) {
            vw = pw[i];
            if (vw != i) {
                printf("err32: addr %x wrote %x read %x\n", &pw[i], i, vw);
                err++;
            }
        }
    }

    printf("size %d, errors %d\n", size, err);

    return 0;
}

int
cmd_peek(int argc, char *argv[])
{
    vu32 *pw;
    int i;

#if 1
    pw = (vu32 *)SDRAM_START;
    for (i = 0; i < 8; i++) {
        printf("mem %x: %x %x %x %x\n",
               pw, pw[0], pw[1], pw[2], pw[3]);
        pw += 4;
    }
#endif

    pw = (vu32 *)SDRAM_START;
    pw += 01000;
    for (i = 0; i < 8; i++) {
        printf("mem %x: %x %x %x %x\n",
               pw, pw[0], pw[1], pw[2], pw[3]);
        pw += 4;
    }

    return 0;
}

#if 0
int
cmd_dump(int argc, char *argv[])
{
    int addr, len;

    if (argc < 2) {
        printf("dump <addr> { <len> }\n");
        return -1;
    }

    len = 1;
    addr = 0;

    if (getnumber(argv[1], &addr)) {
        printf("bad address\n");
        return -1;
    }

    if (argc == 3) {
        if (getnumber(argv[2], &len)) {
            printf("bad length\n");
            return -1;
        }
    }

    dumpmem32(addr, len);

    return 0;
}

int
cmd_poke(int argc, char *argv[])
{
    int addr, value;

    if (argc < 2) {
        printf("poke <addr> <value>\n");
        return -1;
    }

    addr = 0;
    value = 0;

    if (getnumber(argv[1], &addr)) {
        printf("bad address\n");
        return -1;
    }

    if (getnumber(argv[2], &value)) {
        printf("bad value\n");
        return -1;
    }

    printf("%x <- %x\n", addr, value);
    *(u32 *)addr = value;

    return 0;
}
#endif

struct {
    char *cmd;
    int (*func)(int, char **);
    char *desc;
} commands[] = {
//	{ "d", cmd_dump, "dump memory as 32 bit words" },
//	{ "p", cmd_poke, "poke memory as 32 bit words" },
	{ "disk", cmd_disk, "test disk" },
//	{ "mmc", cmd_mmc, "test mmc" },
//	{ "spy", cmd_spy, "test spy" },
	{ "mem", cmd_mem, "test memory" },
	{ "peek", cmd_peek, "read memory" },
	{ "?", cmd_help, "print help" },
	{ "help", cmd_help, "print help" },
	{ 0 }
};

int
cmd_help(int argc, char *argv[])
{
    int i;

    printf("available commands:\n");
    for (i = 0; commands[i].cmd; i++) {
        printf("%s\t%s\n", commands[i].cmd, commands[i].desc);
    }
}

/*
 * find the first word of the input in the command list and run the
 * command function...
 */
int
parse_command(void)
{
    int i, hit;

    hit = 0;
    for (i = 0; commands[i].cmd; i++) {
        if (strncasecmp(commands[i].cmd, argv[0],
                        strlen(argv[0])) == 0)
        {
            hit++;
            (*commands[i].func)(argc, argv);
            break;
        }
    }

    if (!hit) {
	    printf("unknown command? '%s'\n\r", argv[0]);
    }

    return 0;
}

/*
 * parse new input line, finding word boundaries and creating
 * an argv vector
 */
int
create_argv(void)
{
    char *p, c, t;

    if (0) printf("create_argv() line '%s'\n", line);

    strcpy(line2, line);

    p = line2;
    argc = 0;

    while (*p) {
        if (argc == MAX_ARGV) {
            printf("input exceeds max # of args (%d)", MAX_ARGV);
            printf("'%s'\n", line);
            break;
        }

        /* save start of word */
        argv[argc++] = p;
        argv[argc] = NULL;

        /* quoted string? */
        if (*p == '\'' || *p == '\"') {
            t = *p;

            /* adjust pointer to skip over starting quote */
            argv[argc-1]++;
            p++;

            while (c = *p) {
                if (c == t) {
                    *p++ = 0;
                    break;
                }
                p++;
            }
        } else {
            /* not quoted string, find end of word */
            while (c = *p) {

                if (c == ' ' || c == '\t') {
                    *p++ = 0;
                    break;
                }

                p++;
            }
        }

        /* skip over whitespace */
        while (c = *p) {
            if (c != ' ' && c != '\t')
                break;

            p++;
            continue;
        }
    }

    return 0;
}

void
prompt(void)
{
	printf("\n" CLI_PROMPT);
}

int
cli(void)
{
	while (1) {
		prompt();

		if (readline(line, sizeof(line)))
			continue;

		if (line[0] == 0)
			continue;

		if (create_argv())
			continue;

		parse_command();
	}
}

int
cli_init()
{
	readline_init();
#if 0
	//cmd_spy(0, NULL);
	//cmd_mem(0, NULL);
        cmd_disk_read(0, NULL);
	//cmd_disk_write(0, NULL);
#endif
	return 0;
}


/*
 * Local Variables:
 * indent-tabs-mode:nil
 * c-basic-offset:4
 * End:
*/
