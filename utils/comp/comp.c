/*
 * compare results of usim behavioral model and caddr rtl model log files
 *
 * this is a total hack, but useful
 * it is highly dependant on the format of the output strings in the trace files
 *
 * basically it tries to match up the pc's and track the contents of
 * the local memoryes (A,M), stack, pdl, vmem's and imem.  anomalies
 * in the microcode execution should show up as deltas between the two sources.
 *
 * there is also some code to check for missing (incomplete) reads and writes
 */

#define _FILE_OFFSET_BITS 64

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <signal.h>

char *fn1, *fn2;
FILE *f1, *f2;
int debug;
int show;
int look;
int busy;
int eof;
int max_count;

char line1[1024];
char line2[1024];

unsigned int pc1, pc2;
unsigned long long ir1, ir2;
unsigned int aloc1, aloc2;
unsigned int a1, a2;
unsigned int mloc1, mloc2;
unsigned int m1, m2;
unsigned int n1, n2;
unsigned int r1, r2;
unsigned int lc1, lc2;

int state1, state2;
int needline1 = 1;

int spc_offby1 = 0;

int line_num1, line_num2;
int l1, l2;
unsigned int lpc1, lpc2;
int gap, ok, amemgap, spcgap, l1gap, l2gap;

int f1_in_iram, f2_in_iram;

int instr1, instr2;
int disk_busy1, disk_busy2;

unsigned int amem1[1024]; char amem1_fill[1024]; int amem1_line[1024];
unsigned int amem2[1024]; char amem2_fill[1024]; int amem2_line[1024];
char amem_report[1024];

unsigned int l1_1[2048]; char l1_1_fill[2048];
unsigned int l1_2[2048]; char l1_2_fill[2048];

unsigned int l2_1[1024]; char l2_1_fill[1024];
unsigned int l2_2[1024]; char l2_2_fill[1024];

unsigned int spc1[32]; char spc1_fill[32];
unsigned int spc2[32]; char spc2_fill[32];
char spc_report[32];

struct page_s {
    unsigned int w[256];
};

static struct page_s *phy_pages[16*1024];

void dump_state(void)
{
    printf("line1 %d, line2 %d\n", line_num1, line_num2);
    printf("l1 %d, l2 %d\n", l1, l2);
    printf("lpc1 %o, lpc2 %o\n", lpc1, lpc2);
    printf("pc1 %o, pc2 %o\n", pc1, pc2);
    printf("gap %d, ok %d\n", gap, ok);
}

void sigint_handler(int arg)
{
    printf("SIGINT\n");
    dump_state();
    exit(4);
}

void getline1(void)
{
    int l;
    if (needline1) {
        line_num1++;
        if (fgets(line1, sizeof(line1), f1) == NULL) {
            eof++;
        }
        
        if ((l = strlen(line1))) {
            if (line1[l-1] == '\n')
                line1[l-1] = 0;
        }

        needline1 = 0;
    }
}

void advance1(void)
{
    needline1 = 1;
}

int e_awrite[3], e_mwrite[3], e_spcwrite[3], e_pdlwrite[3];
int e_icwrite[3], e_l1write[3], e_l2write[3], e_irwrite[3];
int e_xbusread[3], e_xbuswrite[3], e_xbusfault[3];

unsigned int aaddr[3], maddr[3], spcaddr[3], pdladdr[3];
unsigned int l1addr[3], l2addr[3], iraddr[3];
unsigned int awrite[3], mwrite[3], spcwrite[3], pdlwrite[3];
unsigned int icwrite[3], l1write[3], l2write[3];
unsigned long long irwrite[3];

void reset_events(int i)
{
    e_awrite[i] = 0;
    e_mwrite[i] = 0;
    e_spcwrite[i] = 0;
    e_pdlwrite[i] = 0;
    e_icwrite[i] = 0;
    e_l1write[i] = 0;
    e_l2write[i] = 0;
    e_irwrite[i] = 0;
    e_xbusread[i] = 0;
    e_xbuswrite[i] = 0;
    e_xbusfault[i] = 0;
}

void show_events(int i)
{
    if (!show)
        return;

    if (e_awrite[i]) {
        printf("%d: a[%o]<-%o\n", i, aaddr[i], awrite[i]);
    }

    if (e_mwrite[i]) {
        printf("%d: m[%o]<-%o\n", i, maddr[i], mwrite[i]);
    }

    if (e_spcwrite[i]) {
        printf("%d: spc[%o]<-%o\n", i, spcaddr[i], spcwrite[i]);
    }

    if (e_pdlwrite[i]) {
        printf("%d: pdl[%o]<-%o\n", i, pdladdr[i], pdlwrite[i]);
    }

    if (e_icwrite[i]) {
    }

    if (e_l1write[i]) {
        printf("%d: l1[%o]<-%o\n", i, l1addr[i], l1write[i]);
    }

    if (e_l2write[i]) {
        printf("%d: l2[%o]<-%o\n", i, l2addr[i], l2write[i]);
    }

    if (e_irwrite[i]) {
    }
}

int check_amem(int show)
{
    int i, mismatch;

    mismatch = 0;

    for (i = 0; i < 1024; i++) {
        if (amem1_fill[i] == 0 &&
            amem2_fill[i] == 0)
            continue;

        if (amem1[i] != amem2[i]) {
            if (amem_report[i])
                continue;

            if (show) {
                printf("amem %o 1: %11o  2: %11o  (lines %d, %d)\n",
                       i, amem1[i], amem2[i],
                       amem1_line[i], amem2_line[i]);

                amem_report[i] = 1;
                continue;
            } else {
                mismatch++;
            }
        }
    }

    if (mismatch)
        return -1;

    return 0;
}

int check_spc(int show)
{
    int i, mismatch;

    mismatch = 0;

    for (i = 0; i < 32; i++) {
        if (spc1_fill[i] == 0 &&
            spc2_fill[i] == 0)
            continue;

        if (spc1[i] != spc2[i]) {
            if (spc_report[i])
                continue;

            if (show) {
                printf("spc %o 1: %11o  2: %11o\n",
                       i, spc1[i], spc2[i]);

                spc_report[i] = 1;
                continue;
            } else {
                mismatch++;
            }
        }
    }

    if (mismatch)
        return -1;

    return 0;
}

int check_l1(int show)
{
    int i, mismatch;

    mismatch = 0;

    for (i = 0; i < 2048; i++) {
        if (l1_1_fill[i] == 0 &&
            l1_2_fill[i] == 0)
            continue;

        if (l1_1[i] != l1_2[i]) {
            if (show) {
                printf("l1 %o 1: %11o  2: %11o\n",
                       i, l1_1[i], l1_2[i]);

                continue;
            } else {
                mismatch++;
            }
        }
    }

    if (mismatch)
        return -1;

    return 0;
}

int check_l2(int show)
{
    int i, mismatch;

    mismatch = 0;

    for (i = 0; i < 1024; i++) {
        if (l2_1_fill[i] == 0 &&
            l2_2_fill[i] == 0)
            continue;

#define L2_MASK ~(0300000000)

        if ((l2_1[i] & L2_MASK) != (l2_2[i] & L2_MASK)) {
            if (show) {
                printf("l2 %o 1: %11o  2: %11o\n",
                       i, l2_1[i], l2_2[i]);

                continue;
            } else {
                mismatch++;
            }
        }
    }

    if (mismatch)
        return -1;

    return 0;
}

struct page_s *
page_ptr(int pn)
{
    struct page_s *page;

    if ((page = phy_pages[pn]) == 0) {
        page = (struct page_s *)malloc(sizeof(struct page_s));
        if (page) {
            memset(page, 0, sizeof(struct page_s));
            phy_pages[pn] = page;
        }
    }

    return page;
}

int 
mem1_write(int pn, int offset, unsigned v)
{
    struct page_s *page;

    if ((page = page_ptr(pn))) {
        page->w[offset] = v;
        return 0;
    }

    return -1;
}

int 
mem1_read(int pn, int offset, unsigned v)
{
    struct page_s *page;

    if (pn >= 01000) return 0;

    if ((page = page_ptr(pn))) {
        if (page->w[offset] != v) {
            printf("1: memory read mismatch pn=%o, offset=%o, %o != %o\n",
                   pn, offset,
                   page->w[offset], v);
            return -1;
        }
        return 0;
    }

    return -1;
}

int 
mem2_write(int pn, int offset, unsigned v)
{
    struct page_s *page;

    if ((page = page_ptr(pn))) {
//        page->w[offset] = v;
        return 0;
    }

    return -1;
}

int 
mem2_read(int pn, int offset, unsigned v)
{
    struct page_s *page;

    if (pn >= 01000) return 0;

    if ((page = page_ptr(pn))) {
        if (page->w[offset] != v) {
            printf("2: memory read mismatch pn=%o, offset=%o, %o != %o\n",
                   pn, offset,
                   page->w[offset], v);
            return -1;
        }
        return 0;
    }

    return -1;
}

int
check_dram(void)
{
    return 0;
}

/* ----------------------------------------------------------------------- */

/*
 * read from caddr trace file
 *
 * caddr log file is the "master"
 */
int get1(void)
{
#if 0
    if (state1 == 0) {
        while (1) {
            advance1();
            getline1();
            if (strstr(line1, "A="))
                break;
        }
    }
    state1 = 1;
#endif

    if (eof)
        return 0;

    while (1) {
        int n;
        getline1();
        n = sscanf(line1, "%o %llo A=%o M=%o N%d R=%o LC=%o",
                   &pc1, &ir1, &a1, &m1, &n1, &r1, &lc1);
        advance1();
        if (n == 7)
            break;

        if (line1[1] == 0)
            continue;

        if (memcmp(line1, "boot", 4) == 0)
            continue;

        if (memcmp(line1, "prom:", 5) == 0)
            continue;

        if (memcmp(line1, "unibus:", 7) == 0)
            continue;

        if (memcmp(line1, "busint:", 7) == 0)
            continue;

        if (memcmp(line1, "dpi_ide:", 8) == 0) {
            if (line1[9] != 'b')
                printf("%s\n", line1);
            continue;
        }

        if (memcmp(line1, "built on:", 9) == 0)
            continue;

        if (memcmp(line1, "force ", 6) == 0)
            continue;

        if (memcmp(line1, "ram_s3board.v:", 14) == 0)
            continue;

        if (memcmp(line1, "Enabling ", 9) == 0)
            continue;

        if (memcmp(line1, "reset", 5) == 0)
            continue;

        if (memcmp(line1, "destintctl", 10) == 0)
            continue;

        if (memcmp(line1, "io:", 3) == 0)
            continue;

        if (memcmp(line1, "tv:", 3) == 0)
            continue;

        if (memcmp(line1, "vram:", 5) == 0)
            continue;

        if (memcmp(line1, "amem:", 5) == 0)
            continue;

        if (memcmp(line1, "xbus:", 5) == 0)
            continue;

        if (memcmp(line1, "load md", 7) == 0)
            continue;

        if (memcmp(line1, "pcs", 3) == 0)
            continue;

        if (memcmp(line1, "xxx:", 4) == 0)
            continue;

        if (memcmp(line1, "rc:", 3) == 0)
            continue;

        if (memcmp(line1, "disk:", 5) == 0)
            continue;

        if (memcmp(line1, "mcr:", 4) == 0)
            continue;

        printf("1: confusion %d (line %d) '%s'\n", n, line_num1, line1);
        exit(2);
    }

    reset_events(1);
    if (show) printf("1: pc=%o\n", pc1);
    instr1++;

    while (1) {
        int n;

        getline1();

        if (line1[1] == 0) {
            advance1();
            continue;
        }

#define cmp4(a, b, c, d) \
        (line1[0] == a && line1[1] == b && line1[2] == c && line1[3] == d)

        /* spc: */
        if (cmp4('s', 'p', 'c', ':')) {
            int off = 0;

            if (line1[5] == 'W')
                off = 7;
            if (line1[6] == 'W')
                off = 8;

            if (off) {
                n = sscanf(line1, "spc: W %o <- %o",
                           &spcaddr[1], &spcwrite[1]);
                if (n == 2) {
                    e_spcwrite[1] = 1;

                    if (spc_offby1) spcaddr[1]++;
                    spc1[spcaddr[1] & 037] = spcwrite[1];
                    spc1_fill[spcaddr[1] & 037] = 1;
                    spc_report[spcaddr[1] & 037] = 0;
                }
            }
            advance1();
            continue;
        }

        /* pdl: */
        if (cmp4('p', 'd', 'l', ':')) {
            int off = 0;
            if (line1[5] == 'W')
                off = 7;
            if (line1[6] == 'W')
                off = 8;

            if (off) {
                n = sscanf(&line1[off], "pdl: W %o <- %o", &pdladdr[1], &pdlwrite[1]);
                if (n == 2) {
                    e_pdlwrite[1] = 1;
                }
            }
            advance1();
            continue;
        }

        if (memcmp(line1, "load md", 7) == 0) {
            advance1();
            continue;
        }

        if (memcmp(line1, "pdlidx <- ", 10) == 0) {
            advance1();
            continue;
        }

        /* amem: */
        if (line1[0] == 'a' && line1[1] == 'm' && line1[4] == ':') {
            if (line1[6] == 'W') {
                n = sscanf(line1, "amem: W %o <- %o", &aaddr[1], &awrite[1]);
                if (n == 2) {
                    e_awrite[1] = 1;

                    amem1[aaddr[1] & 01777] = awrite[1];
                    amem1_fill[aaddr[1] & 01777] = 1;
                    amem_report[aaddr[1] & 01777] = 0;
                    if (0) printf("1: >amem[%o]\n", aaddr[1] & 01777);

                    amem1_line[aaddr[1] & 01777] = line_num1;
                }
            }

            advance1();
            continue;
        }

        /* mmem: */
        if (line1[0] == 'm' && line1[1] == 'm' && line1[4] == ':') {
            advance1();
            continue;
        }

        /* iram: */
        if (line1[0] == 'i' && line1[1] == 'r' && line1[4] == ':') {
            if (line1[6] == 'W') {
                n = sscanf(line1, "iram: W %o <- %llo",
                           &iraddr[1], &irwrite[1]);
                if (n == 2) {
                    e_spcwrite[1] = 1;
                }
            }
            advance1();
            continue;
        }

        /* vmem0 */
        if (line1[0] == 'v' && line1[1] == 'm' && line1[4] == '0') {
            if (line1[7] == 'W') {
                n = sscanf(line1, "vmem0: W %o <- %o;",
                           &l1addr[1], &l1write[1]);
                if (n == 2) {
                    e_l1write[1] = 1;

                    l1_1[l1addr[1] & 03777] = l1write[1];
                    l1_1_fill[l1addr[1] & 03777] = 1;
                    if (0) printf("'%s' yields l1_2[%o] <- %o\n",
                                  line1, l1addr[1] & 03777, l1write[1]);
                }
            }
            advance1();
            continue;
        }

        /* vmem1 */
        if (line1[0] == 'v' && line1[1] == 'm' && line1[4] == '1') {
            if (line1[7] == 'W') {
                n = sscanf(line1, "vmem1: W %o <- %o;", &l2addr[1], &l2write[1]);
                if (n == 2) {
                    e_l2write[1] = 1;

                    l2_1[l2addr[1] & 01777] = l2write[1];
                    l2_1_fill[l2addr[1] & 01777] = 1;
                }
            }

            advance1();
            continue;
        }

        /* vm0 vm1 */
        if (line1[0] == 'v' && line1[1] == 'm' &&
            (line1[2] == '0' || line1[2] == '1'))
        {
            advance1();
            continue;
        }

        if (line1[0] == 'v' && line1[1] == 'm' && line1[2] == 'a')
        {
            advance1();
            continue;
        }

        /* xbus: */
        if (line1[0] == 'x' && line1[1] == 'b' && line1[2] == 'u')
        {
            if (line1[6] == 'a')
                e_xbusfault[1] = 1;

            if (line1[6] == 'r') {
                e_xbusread[1] = 1;
            }
            if (line1[6] == 'w') {
                e_xbuswrite[1] = 1;
            }
            
            advance1();
            continue;
        }

        /* unibus: */
        if (line1[0] == 'u' && line1[1] == 'n' && line1[2] == 'i')
        {
            if (line1[8] == 'w') {
                unsigned int ua, uv;
                sscanf(line1, "unibus: write @%o <- %o", &ua, &uv);

                if (ua == 017773005 && uv == 044) {
                    f1_in_iram = 1;
                }
            }
            advance1();
            continue;
        }

        /* ddr: */
        if (line1[0] == 'd' && line1[1] == 'd' && line1[2] == 'r')
        {
            advance1();
            continue;
        }

        /* sdram: */
        if (line1[0] == 's' && line1[1] == 'd' && line1[2] == 'r')
        {
            advance1();
            continue;
        }

        /* rc: sdram read/write */
        if (line1[0] == 'r' && memcmp(line1, "rc: sdram ", 10) == 0) {
            char *p;

            if (line1[10] == 'w') {
                unsigned int paddr, v;
                n = sscanf(&line1[10], "write %o <- %o", &paddr, &v);
                if (n == 2) {
                    int pn = paddr >> 8;
                    int offset = paddr & 0377;
                    mem1_write(pn, offset, v);
                }
            }

            if (line1[10] == 'r') {
                unsigned int paddr, v;
                n = sscanf(&line1[10], "read %o -> %o", &paddr, &v);
                if (n == 2) {
                    int pn = paddr >> 8;
                    int offset = paddr & 0377;
                    mem1_read(pn, offset, v);
                }
            }

            advance1();
            continue;
        }

        if (line1[0] == 'm' && memcmp(line1, "mcr:", 4) == 0) {
            advance1();
            continue;
        }

        /* disk: */
        if (line1[0] == 'd' && memcmp(line1, "disk:", 5) == 0) {
            if (line1[6] == 'd' && line1[7] == 'a') {
                unsigned da, u, c, h, b, lba;
                sscanf(line1, "disk: da %o (unit%d cyl %d head %d block %d) lba 0x%x",
                       &da, &u, &c, &h, &b, &lba);
                if (0) printf("1: %s\n", line1);
            }

            advance1();
            continue;
        }

        /* tv: */
        if (line1[0] == 't' && line1[1] == 'v')
        {
            advance1();
            continue;
        }

        /* io: */
        if (line1[0] == 'i' && line1[1] == 'o')
        {
            advance1();
            continue;
        }

        if (memcmp(line1, "pli", 3) == 0) {
            advance1();
            continue;
        }

        if (memcmp(line1, "dpi", 3) == 0) {

            if (memcmp(line1, "dpi_ide:", 8) == 0 && line1[9] != 'b') {
                    printf("%s\n", line1);
            }

            advance1();
            continue;
        }

        if (memcmp(line1, "s_read2:", 8) == 0) {
            advance1();
            continue;
        }

        if (memcmp(line1, "destimod1:", 10) == 0) {
            advance1();
            continue;
        }

        if (memcmp(line1, "destintctl:", 11) == 0) {
            advance1();
            continue;
        }

        if (memcmp(line1, "dispatch:", 9) == 0) {
            advance1();
            continue;
        }

        if (memcmp(line1, "prom:", 5) == 0) {
            advance1();
            continue;
        }

        /* xxx: */
        if (line1[0] == 'x' && line1[1] == 'x' && line1[2] == 'x')
        {
            int count;
            if (line1[11] == 'b')
                disk_busy1 = instr1;
            if (line1[11] == 'i') {
                count = (instr1 - disk_busy1) + 1;
                if (busy)
                    printf("1: disk busy for %d instructions @ line %d\n",
                           count, line_num1);
            }
            advance1();
            continue;
        }

        break;
    }

    show_events(1);

    return 0;
}

struct {
    int what;
    int addr;
    int v;
} dstack[10];
int dcount;
#define AMEM 1
#define MMEM 2
#define SPC 3

void do_defered(void)
{
    int i, a;

    for (i = 0; i < dcount; i++) {
        switch (dstack[i].what) {
        case AMEM:
            a = dstack[i].addr;

            if (0) printf("2: >amem[%o]\n", a);
            amem2[a] = dstack[i].v;
            amem2_fill[a] = 1;
            amem_report[a] = 0;
            break;
        case SPC:
            a = dstack[i].addr;

            if (0) printf("2: >spc[%o]\n", a);
            spc2[a] = dstack[i].v;
            spc2_fill[a] = 1;
            spc_report[a] = 0;
if (a == 0) spc_offby1 = 0;
            break;
        }
    }

    dcount = 0;
}

void defer2(int what, int addr, int v)
{
    dstack[dcount].what = what;
    dstack[dcount].addr = addr;
    dstack[dcount].v = v;
    dcount++;

#ifndef PIPELINED_WRITES
    do_defered();
#endif
}

void getline2(void)
{
    int l;

    line_num2++;
    if (fgets(line2, sizeof(line2), f2) == NULL) {
        eof++;
    }
        
    if ((l = strlen(line2))) {
        if (line2[l-1] == '\n')
            line2[l-1] = 0;
    }
}

/*
 * read from usim trace file
 */
int get2(void)
{
    int n;

    reset_events(2);

    if (state2 == 0) {
        while (1) {
            getline2();
            if (eof)
                return 0;

            if (line2[0] == '-')
                break;

            if (line2[0] == 'a' && memcmp(line2, "a_memory", 8) == 0) {
                sscanf(line2, "a_memory[%o] <- %o", &aaddr[2], &awrite[2]);
                amem2[aaddr[2] & 01777] = awrite[2];
                amem2_fill[aaddr[2] & 01777] = 1;
                amem_report[aaddr[2] & 01777] = 0;
                if (0) printf("2: >amem[%o]\n", aaddr[2] & 01777);

                amem2_line[aaddr[2] & 01777] = line_num2;
            }

            if (line2[0] == 'w' && memcmp(line2, "write_mem", 9) == 0) {
                char *p = strstr(line2, "pn=");
                unsigned int pn, offset, v;
                if (p) {
                    n = sscanf(p, "pn=%o offset=%o; v %o", &pn, &offset, &v);
                    mem2_write(pn, offset, v);
                }
            }

            if (line2[0] == 'r' && memcmp(line2, "read_mem", 9) == 0) {
                char *p = strstr(line2, "pn=");
                unsigned int pn, offset, v;
                if (p) {
                    n = sscanf(p, "pn=%o offset=%o; v %o", &pn, &offset, &v);
                    mem2_read(pn, offset, v);
                }
            }
        }
    }
    state2 = 1;

    while (1) {
        getline2();
        if (eof)
            return 0;

        if (memcmp(line2, "disk:", 5) == 0) {
            if (strstr(line2, "fut"))
                printf("%s\n", line2);
        }

        n = sscanf(line2, "%o %llo", &pc2, &ir2);
        if (n == 2)
            break;
    }

    if (show) printf("2: pc=%o\n", pc2);
    instr2++;
    do_defered();

    while (1) {
        getline2();
        if (eof)
            return 0;

        if (line2[0] == '-')
            break;

        if (line2[0] == 'a' && line2[1] == '=') {
            sscanf(line2, "a=%o (%o), m=%o (%o)", &aloc2, &a2, &mloc2, &m2);
        }

        if (line2[0] == 'a' && line2[1] == '_' && line2[2] == 'm') {
            n = sscanf(line2, "a_memory[%o] <- %o", &aaddr[2], &awrite[2]);
            if (n == 2) {
                e_awrite[2] = 1;
                defer2(AMEM, aaddr[2], awrite[2]);

                amem2_line[aaddr[2] & 01777] = line_num2;
            }
        }
        if (line2[0] == 'm' && line2[1] == '_' && line2[2] == 'm') {
            n = sscanf(line2, "m_memory[%o] <- %o", &maddr[2], &mwrite[2]);
            if (n == 2) {
                e_mwrite[2] = 1;
            }
        }

        if (line2[0] == 'w' && line2[1] == 'r' && line2[2] == 'i')
        {
            if (line2[8] == 's') {
                n = sscanf(line2, "writing spc[%o] <- %o,",
                           &spcaddr[2], &spcwrite[2]);
                if (n == 2) {
                    e_spcwrite[2] = 1;
                    defer2(SPC, spcaddr[2], spcwrite[2]);
                }
            }
            if (line2[8] == 'p') {
                n = sscanf(line2, "writing pdl[%o] <- %o,",
                           &pdladdr[2], &pdlwrite[2]);
                if (n == 2) {
                    e_pdlwrite[2] = 1;
                }
            }
            if (line2[8] == 'I') {
                n = sscanf(line2, "writing IC <- %o,", &icwrite[2]);
                if (n == 1) {
                    e_icwrite[2] = 1;
                }
            }
        }

        if (line2[0] == 'l' && line2[1] == '1' && line2[3] == 'm') {
            n = sscanf(line2, "l1_map[%o] <- %o", &l1addr[2], &l1write[2]);
            if (n == 2) {
                e_l1write[2] = 1;

                l1_2[l1addr[2] & 03777] = l1write[2];
                l1_2_fill[l1addr[2] & 03777] = 1;

                if (0) printf("'%s' yields l1_2[%o] <- %o\n",
                              line2, l1addr[2] & 03777, l1write[2]);
            }
        }

        if (line2[0] == 'l' && line2[1] == '2' && line2[3] == 'm') {
            n = sscanf(line2, "l2_map[%o] <- %o", &l2addr[2], &l2write[2]);
            if (n == 2) {
                e_l2write[2] = 1;

                l2_2[l2addr[2] & 01777] = l2write[2];
                l2_2_fill[l2addr[2] & 01777] = 1;
            }
        }

//----
        if (line2[0] == 'w' && memcmp(line2, "write_mem", 9) == 0) {
            char *p = strstr(line2, "pn=");
            unsigned int pn, offset, v;
            if (p) {
                n = sscanf(p, "pn=%o offset=%o; v %o", &pn, &offset, &v);
                mem2_write(pn, offset, v);
            }
        }

        if (line2[0] == 'r' && memcmp(line2, "read_mem", 9) == 0) {
            char *p;
            unsigned int pn, offset, v, vaddr;

            p = strstr(line2, "vaddr=");
            if (p) {
                n = sscanf(p, "vaddr=%o", &vaddr);
            }

            p = strstr(line2, "pn=");
            if (p) {
                n = sscanf(p, "pn=%o offset=%o; v %o", &pn, &offset, &v);
                mem2_read(pn, offset, v);
            }

           if (vaddr == 01005 && pn == 037766 && v == 044)
                f2_in_iram = 1;
        }

//---
        if (memcmp(line2, "disk:", 5) == 0) {
            if (line2[6] == 'd' && line2[7] == 'a') {
                unsigned da, u, c, h, b, lba;
                sscanf(line2, "disk: da %o (unit%d cyl %d head %d block %d) lba 0x%x",
                       &da, &u, &c, &h, &b, &lba);
                printf("%s\n", line2);
            }

            if (strstr(line2, "fut"))
                printf("%s\n", line2);
        }

    }

    show_events(2);

    return 0;
}

int lookforrw(void)
{
    int r, count;
    unsigned int dest;
    int read_follows, write_follows;
    int read_start, write_start;
    unsigned long long u;
    unsigned int read_pc, write_pc;
    int old_n1;

#if 0
    /* advance file1 to iram */
    while (1) {
        r = get1();
        if (r)
            return -1;
        if (eof)
            break;
        if (f1_in_iram) {
            break;
        }
    }
#endif

    read_follows = 0;
    read_start = 0;

    write_follows = 0;
    write_start = 0;

    old_n1 = 0;

    count = 0;
    while (1) {
        int count;

        r = get1();
        if (r)
            return -1;
        if (eof)
            break;

        u = ir1;

        if (old_n1 == 0)
        switch ((u >> 43) & 03) {
        case 0: /* alu */
        case 3: /* byte */
            dest = (u >> 14) & 07777;

            if ((dest & 04000) == 0) {
                switch (dest >> 5) {
                case 021: /* start-read */
                case 031: /* start-read */
                    read_follows = instr1;
                    read_start = line_num1;
                    read_pc = pc1;
                    if (0) printf("read @ %o, line %d\n", pc1, line_num1);
                    break;
                case 022: /* start-write */
                case 032: /* start-write */
                    write_follows = instr1;
                    write_start = line_num1;
                    write_pc = pc1;
                    if (0) printf("write @ %o, line %d\n", pc1, line_num1);
                    break;
                }
            }
        }

        if (read_follows && write_follows) {
            printf("1: rw missing confusion @ lines %d, %d\n",
                   read_start, write_start);
        }

        if (read_follows) {
            count = (instr1 - read_follows) + 1;

            if (count <= 2) {
                if (e_xbusread[1] || e_xbusfault[1]) {
                    read_follows = 0;
                    if (0) printf("read concludes @ %o, line %d, count %d\n",
                                  lc1, line_num1, count);
                }
            } else {
                printf("1: read missing @ line %d-%d, pc %o\n",
                       read_start, line_num1, read_pc);

                read_follows = 0;
                read_start = 0;
            }
        }

        if (write_follows) {
            count = (instr1 - write_follows) + 1;

            if (count <= 2) {
                if (e_xbuswrite[1] || e_xbusfault[1]) {
                    write_follows = 0;
                    if (0) printf("write concludes @ %o, line %d, count %d\n",
                                  lc1, line_num1, count);
                }
            } else {
                printf("1: write missing @ line %d-%d, pc %o\n",
                       write_start, line_num1, write_pc);

                write_follows = 0;
                write_start = 0;
            }

        }

        old_n1 = n1;
    }

    return 0;
}

int check_mems(void)
{
    /* */
    if (check_amem(0) == 0)
        amemgap = 0;
    else
        amemgap++;

    if (amemgap > 1/*5*/) {
        printf("amem mismatch: pc1=%o pc2=%o; (1=%d, 2=%d)\n",
               pc1, pc2, line_num1, line_num2);
        check_amem(1);
    }

    /* */
    if (check_spc(0) == 0)
        spcgap = 0;
    else
        spcgap++;

    if (spcgap > 5) {
        printf("spc mismatch: pc1=%o pc2=%o; (1=%d, 2=%d)\n",
               pc1, pc2, line_num1, line_num2);
        check_spc(1);
    }

    /* */
    if (check_l1(0) == 0)
        l1gap = 0;
    else
        l1gap++;

    if (l1gap > 5) {
        printf("l1 mismatch: pc1=%o pc2=%o; (1=%d, 2=%d)\n",
               pc1, pc2, line_num1, line_num2);
        check_l1(1);
    }

    /* */
    if (check_l2(0) == 0)
        l2gap = 0;
    else
        l2gap++;

    if (l2gap > 5) {
        printf("l2 mismatch: pc1=%o pc2=%o; (1=%d, 2=%d)\n",
               pc1, pc2, line_num1, line_num2);
        check_l2(1);
    }

    if (check_dram() == 0)
        ;

    return 0;
}

int process(void)
{
    int r, count;

#if 0
    /* advance file1 to iram */
    while (1) {
        r = get1();
        if (r)
            return -1;
        if (eof)
            break;
        if (f1_in_iram) {
            printf("f1 in iram; pc1 %o\n", pc1);
            break;
        }
    }
#endif

#if 0
    /* advance file1 to iram */
    while (1) {
        r = get2();
        if (r)
            return -1;
        if (eof)
            break;
        if (f2_in_iram) {
            printf("f2 in iram; pc2 %o\n", pc2);
            break;
        }
    }
#endif

    count = 0;
    while (1) {
        r = get1();
        if (r)
            return -1;
        if (eof)
            break;

        r = get2();
        if (r)
            return -1;
        if (eof)
            break;

        if (count == 0) {
            if (pc1 < pc2)
                get1();
            if (pc1 > pc2)
                get2();
        }

        count++;
        if (max_count && count == max_count)
            break;

        if (count % 10000 == 0)
            printf("%d...\n", count);

        l1 = line_num1;
        l2 = line_num2;

        if (0) printf("%o (%d) %o (%d) %s\n",
                      pc1, l1, pc2, l2, pc1 == pc2 ? "=" : "!=");

#if 0
        if (pc1 < pc2)
            get1();
        if (pc1 > pc2)
            get2();
#endif

        if (pc1 != pc2) {
            gap = 0;

            lpc1 = pc1;
            lpc2 = pc2;

            while (1) {
                //check_mems();

                if (pc1 == pc2)
                    break;

if (pc2 == 0134) {
 get2();
} else
                get1();

                gap++;

                if (gap >= 400000) {
                    printf("gap too large @ %d %d\n", l1, l2);
                    dump_state();
                    exit(3);
                }
            }

            if (gap > 2) {
                printf("matching: %d\n", ok);
                printf("mismatch:\t%d\tpc1=%o pc2=%o; (1=%d-%d, 2=%d-%d)\n",
                       gap, lpc1, lpc2, l1, line_num1, l2, line_num2);
                ok = 0;
            }

        } else
            ok++;

        check_mems();

        if (show) printf("----\n");
    }

    return 0;
}

main(int argc, char *argv[])
{
    int i, ret;

    for (i = 1; i < argc; i++) {
        if (argv[i][0] == '-')
            switch (argv[i][1]) {
            case 'd': debug++; break;
            case 's': show++; break;
            case 'l': look++; break;
            case 'b': busy++; break;
            }
        else
            break;
    }

    if (i < argc) {
        fn1 = strdup(argv[i]);
        f1 = fopen(fn1, "r");
        if (f1 == NULL) {
            perror(fn1);
            exit(1);
        }
        i++;
    }

    if (i < argc) {
        fn2 = strdup(argv[i]);
        f2 = fopen(fn2, "r");
        if (f2 == NULL) {
            fclose(f1);
            perror(fn2);
            exit(1);
        }
        i++;
    }

    if (debug) {
        printf("1: %s\n", fn1);
        printf("2: %s\n", fn2);
    }

    signal(SIGINT, sigint_handler);

    if (look)
        ret = lookforrw();
    else
        ret = process();

    fclose(f1);
    fclose(f2);

    printf("comparison done\n");

    if (ret)
        exit(1);

    exit (0);
}



/*
 * Local Variables:
 * indent-tabs-mode:nil
 * c-basic-offset:4
 * End:
*/
