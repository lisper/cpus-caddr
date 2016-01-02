/*
 * test commands
 *
 */

#include "types.h"
#include "diag.h"
#include "lh7a400.h"

static int verbose;
static int stop_on_error;
static unsigned long errors;

extern void printf(char *fmt, ...);

void
info(void)
{
    cscRegs_t *csc = (cscRegs_t *)0x80000400;
    unsigned long p;
    int chipman, chipid;

    p = csc->pwrsr;

    chipman = (p >> 24) & 0xff;
    chipid = (p >> 16) & 0xff;
    printf("chip: manufacturer %2x, id %2x\n", chipman, chipid);

    if (p & PWRSR_LCKFLG) printf("LCKFLG (pll lock) ");
    if (p & PWRSR_CLDFLG) printf("CLDFLG (cold start) ");
    if (p & PWRSR_PFFLG) printf("PFFLG (pwr fail) ");
    if (p & PWRSR_RSTFLG) printf("RSTFLG (reset) ");
    if (p & PWRSR_NBFLG) printf("NBFLG (new batt) ");
    if (p & PWRSR_WUON) printf("WUON (wakeup) ");
    if (p & PWRSR_WUDR) printf("WUDR ");
    if (p & PWRSR_DCDET) printf("DCDET ");
    if (p & PWRSR_MCDR) printf("MCDR ");
}

int
cmd_info(int argc, char *argv[])
{
    info();
    return 0;
}

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

    if (strcmp(argv[0], "d") == 0) {
        dumpmem(addr, len);
    }

    if (strcmp(argv[0], "dw") == 0) {
        dumpmem16(addr, len);
    }

    if (strcmp(argv[0], "dl") == 0) {
        dumpmem32(addr, len);
    }

    return 0;
}

int
cmd_read(int argc, char *argv[])
{
    int addr, d;

    if (argc < 2) {
        printf("read <addr>\n");
        return -1;
    }

    addr = 0;

    if (getnumber(argv[1], &addr)) {
        printf("bad address\n");
        return -1;
    }

    printf("reading %8x...", addr);

    while (1) {
        d = *(volatile u32 *)addr;
        if (serial_poll())
            break;
    }

    return 0;
}

int
cmd_write(int argc, char *argv[])
{
    int addr, d;

    if (argc < 2) {
        printf("write <addr> { value }\n");
        return -1;
    }

    addr = 0;

    if (getnumber(argv[1], &addr)) {
        printf("bad address\n");
        return -1;
    }

    d = 0;

    if (argc == 3) {
        if (getnumber(argv[2], &d)) {
            printf("bad value\n");
            return -1;
        }
    }

    printf("writing %8x <- %08x...", addr, d);

    while (1) {
        *(volatile u32 *)addr = d;
        if (serial_poll())
            break;
    }

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

    if (strcmp(argv[0], "pb") == 0) {
        printf("%x <- %2x\n", addr, value & 0xff);
        *(u8 *)addr = value;
    }

    if (strcmp(argv[0], "ph") == 0) {
        printf("%x <- %4x\n", addr, value & 0xffff);
        *(u16 *)addr = value;
    }

    if (strcmp(argv[0], "p") == 0) {
        printf("%x <- %x\n", addr, value);
        *(u32 *)addr = value;
    }

    return 0;
}

int
cmd_verbose(int argc, char *argv[])
{
    if (argc == 2) {
        verbose = strcmp(argv[1], "on") == 0;
    }

    printf("verbose mode %s\n", verbose ? "on" : "off");

    return 0;
}

int
cmd_stop(int argc, char *argv[])
{
    if (argc == 2) {
        stop_on_error = strcmp(argv[1], "on") == 0;
    }

    printf("stop-on-error mode %s\n", stop_on_error ? "on" : "off");

    return 0;
}

#define ERROR(e){ (*err_fun)((char *)p, v, e); err = 1; if (stop_on_error) return -1; }

/*
 * quick memory test
 */

int
memory_quick_test(char *start_address,
                  char *stop_address,
                  int (*err_fun)(char *bad_address,
                                 u_char found_value,
                                 u_char expected_value)
	)
{
    u_char *p;
    int i, v, err;

    if (verbose) printf("quick mem: 32 bytes (%x-%x)\n",
                        start_address, stop_address);

    p = start_address;
    for (i = 0; i < 32; i++)
        p[i] = i;

    for (i = 0; i < 32; i++) {
        v = p[i];
        if (v != i) {
            ERROR(i);
            return -1;
        }
    }

    if (verbose) printf("quick mem: 1k hops\n");
    p = start_address;
    for (i = 0; i < 256; i++) {
        p += 1024;
        p[i] = i;
    }

    p = start_address;
    for (i = 0; i < 256; i++) {
        p += 1024;
        v = p[i];
        if (v != i) {
            ERROR(i);
            return -1;
        }
    }

    return 0;
}

/*
 *  MEMORY PATTERN TEST
 *
 *  Tests a specified region of memory.  The algorithm was collectively
 *  developed by W. Flynn, F. Peterson, and M. Wilke following months of
 *  intense research:
 *
 *          Patterns:       initial = F0h
 *                          A = 55h
 *                          B = 33h
 *                          C = 0Fh
 *
 *  1. Fill memory with the initial test pattern.
 *          Memory:  F0, F0, F0, F0, ...
 *
 *  2. Fill memory with patterns, verifying the initial test pattern as
 *     you fill.
 *          Memory:  A, B, C, A, B, C, ...
 *
 *  3. Shuffle the patterns* i.e., {A,B,C} => {B,C,A}.
 *
 *  4. Fill memory with patterns, verifying the patterns from the previous
 *     pass as you fill.
 *          Memory:  B, C, A, B, C, A, ...
 *
 *  5. Shuffle the patterns* i.e., {B,C,A} => {C,B,A}.
 *
 *  6. Fill memory with patterns, verifying the patterns from the previous
 *     pass as you fill.
 *          Memory:  C, A, B, C, A, B, ...
 *
 *  7. Fill memory with zeroes, verifying the patterns from the previous
 *     pass as you fill.
 *          Memory:  0, 0, 0, 0, 0, 0, ...
 *
 *  returns 0 if no error was detected
 *  returns -1 if an error was detected
 *
 */

#define initial_pattern 0xf0
#define pattern_0       0x0f
#define pattern_1       0x33
#define pattern_2       0x55

static u_char sequence[] = { pattern_0, pattern_1, pattern_2 };

int
memory_pattern_test(u_char *start_address,
		    u_char *end_address,
		    int (*err_fun)(char *bad_address,
				   u_char found_value,
				   u_char expected_value)
	)
{
    volatile u_char *p;
    u_char c, i, v, err;
    u_char c1, c2;

    err = 0;


    if (verbose) printf("mem pattern: %x-%x\n",
                        start_address, end_address);

    /*
      fill the memory with the initial test pattern.
      Each byte stored is immediately verified, thus detecting non-existent
      memory and preventing the test from continuing.
    */

    if (verbose) printf("mem pattern: fill\n");

    for (p = start_address; p <= end_address; p++) {
        *p = initial_pattern;
        if ((v = *p) != initial_pattern)
            ERROR(initial_pattern);
    }

    /*
      simultaneously verifys the pattern currently
      in memory and store the new pattern.
    */

    if (verbose) printf("mem pattern: check\n");

    /* check initial bytes */
    for (i = 0, p = start_address; p <= end_address; p++) {
        if ((v = *p) != initial_pattern)
            ERROR(initial_pattern);

        *p = (c = sequence[i++ & 3]);
        if ((v = *p) != c)
            ERROR(c);
    }

    if (verbose) printf("mem pattern: plain\n");

    /* check sequence plain */
    for (c1 = 0, p = start_address; p <= end_address; p++) {
//		if (*p != initial_pattern)
//			ERROR(initial_pattern);

        *p = (c = sequence[c1++ & 3]);
        if (*p != c)
            ERROR(c);
    }

    if (verbose) printf("mem pattern: rotated\n");

    /* check sequence rotated once */
    for (c1 = 0, c2 = 1, p = start_address; p <= end_address; p++) {
        if ((v = *p) != (c = sequence[c1++ & 3]))
            ERROR(c);

        *p = (c = sequence[c2++ & 3]);
        if (*p != c)
            ERROR(c);
    }

    if (verbose) printf("mem pattern: rotated twice\n");

    /* check sequence rotated twice */
    for (c1 = 1, c2 = 2, p = start_address; p <= end_address; p++) {
        if ((v = *p) != (c = sequence[c1++ & 3]))
            ERROR(c);

        *p = (c = sequence[c2++ & 3]);
        if (*p != c)
            ERROR(c);
    }

    if (verbose) printf("mem pattern: zeros\n");

    /* check zeros */
    for (c1 = 2, p = start_address; p <= end_address; p++) {
        if ((v = *p) != (c = sequence[c1++ & 3]))
            ERROR(c);

        *p = 0;
        if (*p != 0)
            ERROR(0);
    }

    if (err)
        return -1;

    return 0;
}

/*
   Suk, D.S. and Reddy, S.M., "A March Test for Functional Faults
   in Semiconductor Random Access Memories", IEEE Transactions on
   Computers, vol. C-30, no. 12, pp. 982-985, December 1981.

   FOR address = lowest TO highest STEP 1
       write(address, 0)               # initialize all locations to 0
   FOR address = lowest TO highest STEP 1
       read(address)                   # if not 0: error
       write(address, 1)
       read(address)                   # if not 1: error
       write(address, 0)
       read(address)                   # if not 0: error
       write(address, 1)
   FOR address is lowest TO highest STEP 1
       read(address)                   # if not 1: error
       write(address, 0)
       write(address, 1)
   FOR address is highest TO lowest STEP -1
       read(address)                   # if not 1: error
       write(address, 0)
       write(address, 1)
       write(address, 0)
   FOR address is highest TO lowest STEP -1
       read(address)                   # if not 0: error
       write(address, 1)
       write(address, 0)
*/

int
memory_march_b_test(char *start_address,
		    char *stop_address,
		    int (*err_fun)(char *bad_address,
				   u_int32 found_value,
				   u_int32 expected_value)
	)
{
    volatile u_int32 *p;
    u_int32 v;
    int err = 0;

    if (verbose) printf("march test: %x-%x\n",
                        start_address, stop_address);

    /* test 32 bit aligned only */
    if ((u_int32)start_address & 3)
        return -1;
    if ((u_int32)stop_address & 3)
        return -1;

    if (verbose) printf("march test: zero\n");

    for (p = (u_int32 *)start_address; p <= (u_int32 *)stop_address; p++) {
        *p = 0;
    }

    if (verbose) printf("march test: one\n");

    for (p = (u_int32 *)start_address; p <= (u_int32 *)stop_address; p++) {
        if ((v = *p) != 0)
            ERROR(0);

        *p = 0xffffffff;
        if ((v = *p) != 0xffffffff)
            ERROR(0xffffffff);

        *p = 0;
        if ((v = *p) != 0)
            ERROR(0);

        *p = 0xffffffff;
    }

    if (verbose) printf("march test: two\n");

    for (p = (u_int32 *)start_address; p <= (u_int32 *)stop_address; p++) {
        if ((v = *p) != 0xffffffff)
            ERROR(0xffffffff);

        *p = 0;
        *p = 0xffffffff;
    }


    if (verbose) printf("march test: three\n");

    for (p = (u_int32 *)start_address; p <= (u_int32 *)stop_address; p++) {
        if ((v = *p) != 0xffffffff)
            ERROR(0xffffffff);

        *p = 0;
        *p = 0xffffffff;
        *p = 0;
    }

    if (verbose) printf("march test: four\n");

    for (p = (u_int32 *)start_address; p <= (u_int32 *)stop_address; p++) {
        if ((v = *p) != 0)
            ERROR(0);

        *p = 0xffffffff;
        *p = 0;
    }

    if (err)
        return -1;

    return 0;
}

static int
error_function(char *bad_address,
	       u_char found_value,
	       u_char expected_value)
{
    if (verbose)
        printf("memory test error: %x; found %2x expected %2x\n",
               bad_address, found_value, expected_value);
    errors++;
}

static int
error_function_32(char *bad_address,
	       u_int32 found_value,
	       u_int32 expected_value)
{
    if (verbose)
        printf("memory test error: %x; found %8x expected %8x\n",
               bad_address, found_value, expected_value);
    errors++;
}

int
cmd_memory_test(int argc, char *argv[])
{
    char *start_address, *stop_address;
    int p, passes, quick_only, medium_only;

    errors = 0;
    passes = 1;
    quick_only = 0;
    medium_only = 0;

    if (argc == 1) {
        printf("usage: %s {quick | <# of passes>}\n", argv[0]);
        return -1;
    }

    if (argc > 1 && argv[1][0] == 'q')
        quick_only = 1;

    if (argc > 1 && argv[1][0] == 'm')
        medium_only = 1;

    if (argc > 1 && argv[1][0] != 'q' && argv[1][0] != 'm')
        if (getnumber(argv[1], &passes)) {
            printf("bad # of passes\n");
            return -1;
        }

    for (p = 0; p < passes; p++) {

        if (passes > 1)
            printf("pass %d of %d\n", p, passes);

#define SDRAM_TEST_START 0xc1000000
        start_address = (char *)SDRAM_TEST_START;
        stop_address = (char *)SDRAM_TEST_START + (3*1024*1024);

        if (memory_quick_test(start_address, stop_address,
                              error_function))
            break;

        if (quick_only)
            continue;

        if (serial_poll())
            break;
            
        /* */
        start_address = (char *)SDRAM_TEST_START;
        stop_address = (char *)SDRAM_TEST_START + 0x9ffff;

        if (memory_pattern_test(start_address, stop_address,
                                error_function))
            break;

        start_address = (char *)SDRAM_TEST_START;
        stop_address = (char *)SDRAM_TEST_START + 0x9fff0;

        if (memory_march_b_test(start_address, stop_address,
                                error_function_32))
            break;

        if (serial_poll())
            break;
            
        /* */
        start_address = (char *)SDRAM_TEST_START + (1*1024*1024);
        stop_address = (char *)SDRAM_TEST_START + (3*1024*1024);

        if (memory_pattern_test(start_address, stop_address,
                                error_function))
            break;

        if (memory_march_b_test(start_address, stop_address,
                                error_function_32))
            break;

        if (medium_only)
            continue;

        if (serial_poll())
            break;
            
        /* */
#define MAX_MEG 64
        start_address = (char *)SDRAM_TEST_START + (5*1024*1024);
        stop_address = (char *)SDRAM_TEST_START + (MAX_MEG*1024*1024);

        if (memory_pattern_test(start_address, stop_address,
                                error_function))
            break;

        if (memory_march_b_test(start_address, stop_address,
                                error_function_32))
            break;
    }

    printf("memory test pass done; errors %d\n", errors);

    if (errors)
        return -1;

    return 0;
}

int
cmd_memory_alias_test(int argc, char *argv[])
{
    volatile u32 *pl;
    int i;

    pl = (volatile u32 *)0xc4000000;
#define MB(n) ((n)*1024*1024)

    printf("search for aliases from %8x..%8x\n", pl, &pl[MB(4)/4]);

    for (i = 0; i < MB(4)/4; i++) {
        pl[i] = 0;
    }

    pl[0] = 0x12345678;

    for (i = 1; i < MB(4)/4; i++) {
        if (pl[i] != 0)
            printf("alias at %8x\n", &pl[i]);
    }

    printf("done\n");
    return 0;
}

struct {
    int start;
    int mb;
} banks[] = {
    { 0xc0000000, 8 }, { 0xc1000000, 8 },
    { 0xc4000000, 8 }, { 0xc5000000, 8 },
    { 0xc8000000, 8 }, { 0xc9000000, 8 },
    { 0xcc000000, 8 }, { 0xcd000000, 8 },
};

int
cmd_memory_size_test(int argc, char *argv[])
{
#if 0
    volatile u32 *pl;
    int i;

    pl = (volatile u32 *)0xc0400000;

    printf("quick size for aliases from %8x..%8x\n", pl, &pl[MB(4)/4]);

    for (i = 1; i < 16; i++) {
        pl = (volatile u32 *)banks[i].start;
        pl[0] = 0;
        pl[0] = 0x12340000 | i;
    }

    for (i = 1; i < 16; i++) {
        pl = (volatile u32 *)banks[i].start;
        int expected = 0x12340000 | i;
        int got = pl[0];

        if (got != expected) {
            printf("bank %d, addr %x, got %x, expected %x\n",
                   i, pl, got, expected);
        }
    }

    printf("done\n");
    return 0;
#else
    volatile u32 *pl;
    int i, j, mb;

    printf("quick sizing\n");

    printf("16mb banks\n");
    for (i = 1; i < 16; i++) {
        pl = (volatile u32 *)(banks[0].start + 0x1000000*i);
        pl[0] = 0;
        pl[0] = 0x12340000 | i;
    }

    for (i = 1; i < 16; i++) {
        pl = (volatile u32 *)(banks[0].start + 0x1000000*i);
        int expected = 0x12340000 | i;
        int got = pl[0];

        if (got != expected) {
            printf("bank %d, addr %x, got %x, expected %x\n",
                   i, pl, got, expected);
        }
    }

    printf("1mb banks\n");
    for (i = 1; i < 256; i++) {
        pl = (volatile u32 *)(banks[0].start + 0x100000*i);
        pl[0] = 0;
        pl[0] = 0x12340000 | i;
    }

    mb = 0;
    for (i = 1; i < 256; i++) {
        pl = (volatile u32 *)(banks[0].start + 0x100000*i);
        int expected = 0x12340000 | i;
        int got = pl[0];

        if (got == expected) {
            mb++;
            printf("bank %d, addr %x good\n", i, pl);
        }
    }

    printf("found %dmb\n", mb);

    printf("banks\n");
    for (i = 1; i < 8; i++) {
        pl = (volatile u32 *)banks[i].start;
        pl[0] = 0x12340000 | i;
        pl = (volatile u32 *)(banks[i].start + 0x100000*4);
        pl[0] = 0x56780000 | i;
    }

    mb = 0;
    for (i = 1; i < 8; i++) {
        pl = (volatile u32 *)banks[i].start;
        int expected = 0x12340000 | i;
        int got = pl[0];

        if (got == expected) {
            mb += 4;
            printf("bank %d, addr %x good\n", i, pl);
        }

        pl = (volatile u32 *)(banks[i].start + 0x100000*4);
        expected = 0x56780000 | i;
        got = pl[0];

        if (got == expected) {
            mb += 4;
            printf("bank %d, addr %x good\n", i, pl);
        }
    }

    printf("done\n");
    return 0;
#endif
}


/*
 * Local Variables:
 * indent-tabs-mode:nil
 * c-basic-offset:4
 * End:
*/
