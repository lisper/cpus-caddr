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

int line_num1, line_num2;
int l1, l2;
unsigned int lpc1, lpc2;
int gap, ok;

int f1_in_iram, f2_in_iram;

int instr1, instr2;
int disk_busy1, disk_busy2;

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


int get1(void)
{
    if (state1 == 0) {
        while (1) {
            advance1();
            getline1();
            if (strstr(line1, "A="))
                break;
        }
    }
    state1 = 1;

    if (eof)
        return 0;

    while (1) {
        int n;
        getline1();
        n = sscanf(line1, "%o %llo A=%x M=%x N%d R=%x LC=%x",
                   &pc1, &ir1, &a1, &m1, &n1, &r1, &lc1);
        advance1();
        if (n == 7)
            break;

        if (line1[1] == 0)
            continue;

        printf("1: confusion %d (line %d) '%s'\n", n, line_num1, line1);
        exit(2);
    }

    reset_events(1);
    if (show) printf("1: %o\n", pc1);
    instr1++;

    while (1) {
        getline1();

        if (line1[1] == 0) {
            advance1();
            continue;
        }

        if (line1[0] == 's' && line1[1] == 'p' && line1[3] == ':') {
            if (line1[5] == 'W') {
                sscanf(line1, "spc: W addr %o val %o",
                       &spcaddr[1], &spcwrite[1]);
                e_spcwrite[1] = 1;
            }
            advance1();
            continue;
        }

        if (line1[0] == 'p' && line1[1] == 'd' && line1[3] == ':') {
            if (line1[5] == 'W') {
                sscanf(line1, "pdl: W addr %o val %o",
                       &pdladdr[1], &pdlwrite[1]);
                e_pdlwrite[1] = 1;
            }
            advance1();
            continue;
        }

        if (memcmp(line1, "load md", 7) == 0) {
            advance1();
            continue;
        }

       if (line1[0] == 's' && line1[1] == 'p' && line1[3] == ':') {
            if (line1[5] == 'W') {
                sscanf(line1, "spc: W addr %o val %o",
                       &spcaddr[1], &spcwrite[1]);
                e_spcwrite[1] = 1;
            }
            advance1();
            continue;
        }

       if (line1[0] == 'i' && line1[1] == 'r' && line1[4] == ':') {
            if (line1[6] == 'W') {
                sscanf(line1, "iram: W addr %o val %llo",
                       &iraddr[1], &irwrite[1]);
                e_spcwrite[1] = 1;
            }
            advance1();
            continue;
        }

        if (line1[0] == 'v' && line1[1] == 'm' && line1[4] == '0') {
            if (line1[7] == 'W') {
                sscanf(line1, "vmem0: W addr %o <- val %o;",
                       &l1addr[1], &l1write[1]);
                e_l1write[1] = 1;
            }
            advance1();
            continue;
        }

        if (line1[0] == 'v' && line1[1] == 'm' && line1[4] == '1') {
            if (line1[7] == 'W') {
                sscanf(line1, "vmem1: W addr %o <- val %o;",
                       &l2addr[1], &l2write[1]);
                e_l2write[1] = 1;
            }
            advance1();
            continue;
        }

        if (line1[0] == 'v' && line1[1] == 'm' &&
            (line1[2] == '0' || line1[2] == '1'))
        {
            advance1();
            continue;
        }

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

        if (line1[0] == 'd' && line1[1] == 'd' && line1[2] == 'r')
        {
            advance1();
            continue;
        }

        if (memcmp(line1, "disk:", 5) == 0) {
            if (line1[6] == 'd' && line1[7] == 'a') {
                unsigned da, u, c, h, b, lba;
                sscanf(line1, "disk: da %o (unit%d cyl %d head %d block %d) lba 0x%x",
                       &da, &u, &c, &h, &b, &lba);
                if (0) printf("1: %s\n", line1);
            }

            advance1();
            continue;
        }

        if (memcmp(line1, "dispatch:", 9) == 0) {
            advance1();
            continue;
        }

        if (line1[0] == 't' && line1[1] == 'v')
        {
            advance1();
            continue;
        }

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
            advance1();
            continue;
        }

        if (memcmp(line1, "s_read2:", 8) == 0) {
            advance1();
            continue;
        }

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
        }
    }
    state2 = 1;

    while (1) {
        getline2();
        if (eof)
            return 0;

        n = sscanf(line2, "%o %llo", &pc2, &ir2);
        if (n == 2)
            break;
    }

    if (show) printf("2: %o\n", pc2);
    instr2++;

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
            sscanf(line2, "a_memory[%o] <- %o", &aaddr[2], &awrite[2]);
            e_awrite[2] = 1;
        }
        if (line2[0] == 'm' && line2[1] == '_' && line2[2] == 'm') {
            sscanf(line2, "m_memory[%o] <- %o", &maddr[2], &mwrite[2]);
            e_mwrite[2] = 1;
        }

        if (line2[0] == 'w' && line2[1] == 'r' && line2[2] == 'i')
        {
            if (line2[8] == 's') {
                sscanf(line2, "writing spc[%o] <- %o,",
                       &spcaddr[2], &spcwrite[2]);
                e_spcwrite[2] = 1;
            }
            if (line2[8] == 'p') {
                sscanf(line2, "writing pdl[%o] <- %o,",
                       &pdladdr[2], &pdlwrite[2]);
                e_pdlwrite[2] = 1;
            }
            if (line2[8] == 'I') {
                sscanf(line2, "writing IC <- %o,", &icwrite[2]);
                e_icwrite[2] = 1;
            }
        }

        if (line2[0] == 'l' && line2[1] == '1' && line2[3] == 'm') {
            sscanf(line2, "l1_map[%o] <- %o", &l1addr[2], &l1write[2]);
            e_l1write[2] = 1;
        }
        if (line2[0] == 'l' && line2[1] == '2' && line2[3] == 'm') {
            sscanf(line2, "l2_map[%o] <- %o", &l2addr[2], &l2write[2]);
            e_l2write[2] = 1;
        }

        if (line2[0] == 'r' && line2[1] == 'e' && line2[5] == 'm') {
            unsigned int vaddr, l1a, l1, l2a, l2, pn, o, v;
            sscanf(line2, "read_mem(vaddr=%o) l1[%o]=%o, l2[%o]=%o, pn=%o offset=%o; v %o",
                   &vaddr, &l1a, &l1, &l2a, &l2, &pn, &o, &v);
        }
        if (line2[0] == 'w' && line2[1] == 'r' && line2[5] == 'm') {
            unsigned int vaddr, l1a, l1, l2a, l2, pn, o, v;
            sscanf(line2, "write_mem(vaddr=%o) l1[%o]=%o, l2[%o]=%o, pn=%o offset=%o; v %o",
                   &vaddr, &l1a, &l1, &l2a, &l2, &pn, &o, &v);
        }

        if (memcmp(line2, "disk:", 5) == 0) {
            if (line2[6] == 'd' && line2[7] == 'a') {
                unsigned da, u, c, h, b, lba;
                sscanf(line2, "disk: da %o (unit%d cyl %d head %d block %d) lba 0x%x",
                       &da, &u, &c, &h, &b, &lba);
                if (0) printf("2: %s\n", line2);
            }
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

    /* advance file1 to iram */
    while (1) {
        r = get1();
        if (r)
            return -1;
        if (eof)
            break;
        if (f1_in_iram)
            break;
    }

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

int process(void)
{
    int r, count;

    /* advance file1 to iram */
    while (1) {
        r = get1();
        if (r)
            return -1;
        if (eof)
            break;
        if (f1_in_iram)
            break;
    }

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

        count++;
        if (max_count && count == max_count)
            break;

        if (count % 10000 == 0)
            printf("%d...\n", count);

        l1 = line_num1;
        l2 = line_num2;

        if (pc1 != pc2) {
            gap = 0;

            lpc1 = pc1;
            lpc2 = pc2;

            while (1) {
                if (pc1 == pc2)
                    break;

                get1();
                gap++;

                if (gap > 400000) {
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
