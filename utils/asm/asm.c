/*
 * simple microcode assembler for cadr
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

typedef unsigned long long u64;

unsigned long long opcode;
unsigned int pc;

u64 mem[01000];
char set[01000];

unsigned int a_mem[1024];
unsigned int m_mem[32];
unsigned int d_mem[2048];
unsigned int vmem0[2048];
unsigned int vmem1[1024];

int a_mem_set[1024];
int m_mem_set[32];
int d_mem_set[2048];
int vmem0_set[2048];
int vmem1_set[1024];

int vmem1_index;

char *skipwhite(char *p)
{
    if (*p == 0)
        return NULL;

    /* skip whitespace */
    while (*p) {
        if (*p != ' ' && *p != '\t')
            break;
        p++;
    }

    return p;
}

int wordis(char *s1, char *s2)
{
    return strcmp(s1, s2) == 0;
}

int prefixis(char *s1, char *s2)
{
    int l2 = strlen(s2);
    return memcmp(s1, s2, l2) == 0;
}

char *
getword(char *p, char *w)
{
    if (*p == 0)
        return NULL;

    p = skipwhite(p);

    /* collect */
    while (*p) {
        if (*p == ' ' || *p == '\t' || *p == ',' || *p == ':')
            break;
        *w++ = *p++;
    }
    *w = 0;

    return p;
}

char *
getnum(char *p, int *pv)
{
    char word[256];
    p = getword(p, word);
    if (word[0] == '0' && word[1] == 'x') {
        sscanf(word+2, "%x", pv);
    } else
        sscanf(word, "%o", pv);
    return p;
}

#define MAX_LABELS 100
char *label[MAX_LABELS];
unsigned int label_value[MAX_LABELS];
int label_count;

int
add_label(char *word, int pc)
{
    if (label_count >= MAX_LABELS)
        return -1;
    label[label_count] = strdup(word);
    label_value[label_count] = pc;
    label_count++;
    return 0;
}

int
find_label(char *word, int *ppc)
{
    int i;
    for (i = 0; i < label_count; i++) {
        if (strcmp(word, label[i]) == 0) {
            *ppc = label_value[i];
            return 0;
        }
    }

    return -1;
}

struct wordval_s {
    char *w;
    int value;
    unsigned char rot;
};

struct wordval_s alu_words[] = {
    { "setz", 0, 3 },
    { "and", 1, 3 },
    { "setm", 3, 3 },
    { "seta", 5, 3 },
    { "m+a", 1, 7 },
    { "m+a", 011, 3 },
    { "seto", 017, 3 },
    { 0, 0, 0 }
};

struct wordval_s disp_words[] = {
    { "!N+1", 1, 25 },
    { "ISH", 1, 24 },
    { "map-18", 1, 8 },
    { "map-19", 1, 9 },
    { "disp-addr=", -1, 12 },
};

int
get_word_bits(char *w, struct wordval_s *list, unsigned long long *bits)
{
    int i, hits = 0;
    unsigned long long b = 0;

    for (i = 0; list[i].w; i++) {
        if (list[i].value >= 0) {
            if (wordis(w, list[i].w)) {
                b |= (unsigned long long)list[i].value << list[i].rot;
                hits++;
            }
        } else {
            int v, l;
            if (prefixis(w, list[i].w)) {
                l = strlen(list[i].w);
                getnum(w+l, &v);
                if (0) printf("%s %s %d\n", w, w+l, v);
                b |= (unsigned long long)v << list[i].rot;
                hits++;
            }
        }
    }

    if (hits == 0)
        return -1;

    *bits = *bits | b;
    return 0;
}

int
process_line(char *line, FILE *list)
{
    int n;
    char *p;
    char word[256];
    unsigned int addr, value;

    opcode = 0;

    if (line[0] == '#' || !line[0]) {
        goto print;
    }

    p = line;
    while ((p = getword(p, word))) {

        if (0) printf("word '%s'\n", word);

        if (word[0] == '#')
            goto ok;

        if (*p == ':') {
            add_label(word, pc);
            goto print;
        }

        if (wordis(word, ".org")) {
            n = sscanf(p+1, "%o", &pc);
            goto print;
        }

        if (wordis(word, ".op")) {
            n = sscanf(p+1, "%llo", &opcode);
            goto ok;
        }

        if (wordis(word, ".map")) {
            int i;
            unsigned int virt, l1_index, l2_index, l1, l2, pn, r, w, b18, b19;
            char opts[256];

            opts[0] = opts[1] = 0;
            n = sscanf(p+1, "%o %s", &addr, opts);

            r = w = b18 = b19 = 0;
            for (i = 0; opts[i]; i++) {
                switch (opts[i]) {
                case 'R': r = 1; break;
                case 'W': w = 1; break;
                case '+': r = 1; w = 1; break;
                case '8': b18 = 1; break;
                case '9': b19 = 1; break;
                }
            }

            virt = addr;
            pn = (addr >> 8) & 037777;

            l1 = vmem1_index;
            l2 = (r << 23) | (w << 22) | (pn & 037777) | (b18 << 18) | (b19 << 19);

            /* 11 bit l1 index */
            l1_index = (virt >> 13) & 03777;
            vmem0[l1_index] = l1;
            vmem0_set[l1_index] = 1;

            /* 10 bit l2 index */
            l2_index = (l1 << 5) | ((virt >> 8) & 037);
            vmem1[l2_index] = l2;
            vmem1_set[l2_index] = 1;
            if (0) printf("virt %o, l1_index %d, l2_index %d\n",
                          virt, l1_index, l2_index);

            vmem1_index++;
            goto print;
        }

        if (wordis(word, ".amem")) {
            n = sscanf(p+1, "%o %o", &addr, &value);
            a_mem[addr] = value;
            a_mem_set[addr] = 1;
            goto print;
        }

        if (wordis(word, ".mmem")) {
            n = sscanf(p+1, "%o %o", &addr, &value);
            m_mem[addr] = value;
            m_mem_set[addr] = 1;
            goto print;
        }

        if (wordis(word, ".ammem")) {
            p = skipwhite(p);
            p = getnum(p, &addr);
            p = skipwhite(p);
            p = getnum(p, &value);

            a_mem[addr] = value;
            a_mem_set[addr] = 1;
            m_mem[addr] = value;
            m_mem_set[addr] = 1;
            goto print;
        }

        if (wordis(word, ".dmem")) {
            n = sscanf(p+1, "%o %o", &addr, &value);
            if (n != 2) {
                char l[256], flags[256];
                unsigned int lpc;
                n = sscanf(p+1, "%o %s %s", &addr, l, flags);
                find_label(l, &lpc);
                value = lpc;
                if (n == 3) {
                    int i;
                    for (i = 0; i < strlen(flags); i++) {
                        if (flags[i] == 'N')
                            value |= 1 << 14;
                        if (flags[i] == 'P')
                            value |= 1 << 15;
                        if (flags[i] == 'R')
                            value |= 1 << 16;
                    }
                }
            }

            d_mem[addr] = value;
            d_mem_set[addr] = 1;
            goto print;
        }

        if (wordis(word, ".vmem0")) {
            n = sscanf(p+1, "%o %o", &addr, &value);
            vmem0[addr] = value;
            vmem0_set[addr] = 1;
            goto print;
        }

        if (wordis(word, ".vmem1")) {
            n = sscanf(p+1, "%o %o", &addr, &value);
            vmem1[addr] = value;
            vmem1_set[addr] = 1;
            goto print;
        }

        /* */

        if (wordis(word, "noop")) {
            opcode = 010000;
            break;
        }

        if (wordis(word, "alu")) {
            char alu[256];

            p = getword(p, alu);
            if (get_word_bits(alu, alu_words, &opcode))
                goto err;
        }

        if (wordis(word, "dispatch")) {
            char disp[256];

            opcode |= 2LL << 43;

            while ((p = getword(p, disp))) {
                if (get_word_bits(disp, disp_words, &opcode)) {
                    strcpy(word, disp);
                    break;
                }
            }
        }

        if (wordis(word, "byte")) {
            char byte[256];
            opcode |= 3LL << 43;

            while ((p = getword(p, byte))) {
                if (wordis(byte, "ldb"))
                    opcode |= 1LL << 12;
                else
                if (wordis(byte, "sdb"))
                    opcode |= 2LL << 12;
                else
                if (wordis(byte, "dpb"))
                    opcode |= 3LL << 12;
                else
                if (prefixis(byte, "pos=")) {
                    int pos;
                    sscanf(byte, "pos=%o", &pos);
                    opcode |= (u64)(pos) & 037;
                }
                else
                if (prefixis(byte, "width=")) {
                    int width;
                    sscanf(byte, "width=%o", &width);
                    if (width) width--;
                    opcode |= (u64)(width) << 5;
                }
                else {
                    strcpy(word, byte);
                    break;
                }
            }
        }

        if (wordis(word, "jump"))
            opcode |= 1LL << 43;

        if (wordis(word, "alu->"))
            opcode |= 1LL << 12;
        if (wordis(word, "alu>>+s"))
            opcode |= 2LL << 12;
        if (wordis(word, "alu<<+q31"))
            opcode |= 3LL << 12;

        if (wordis(word, "c=1"))
            opcode |= 1LL << 2;

        if (wordis(word, "<<q"))
            opcode |= 1LL << 0;
        if (wordis(word, ">>q"))
            opcode |= 2LL << 0;
        if (wordis(word, "q-r"))
            opcode |= 3LL << 0;

        if (prefixis(word, "a=")) {
            int a;
            sscanf(word, "a=%o", &a);
            if (0) printf("a=%o\n", a);
            opcode |= (u64)a << 32;
        }

        if (prefixis(word, "m=")) {
            int a;
            n = sscanf(word, "m=%o", &a);
            if (n == 1) {
                if (0) printf("m=%o\n", a);
                opcode |= (u64)a << 26;
            } else {
                opcode |= (u64)1 << 31;

                n = sscanf(word, "m=%s", word);
                if (0) printf("m '%s'\n", word);
                if (wordis(word, "q"))
                    opcode |= (u64)007 << 26;
                if (wordis(word, "vma"))
                    opcode |= (u64)010 << 26;
                if (wordis(word, "map"))
                    opcode |= (u64)011 << 26;
                if (wordis(word, "md"))
                    opcode |= (u64)012 << 26;
                if (wordis(word, "lc"))
                    opcode |= (u64)013 << 26;
                if (wordis(word, "pdl[ptr]+pop"))
                    opcode |= (u64)024 << 26;
            }
        }

        if (prefixis(word, "misc=")) {
            int m;
            n = sscanf(word, "misc=%o", &m);
            opcode |= (u64)m << 10;
        }

        if (wordis(word, "R"))
            opcode |= (u64)1 << 9;

        if (wordis(word, "P"))
            opcode |= (u64)1 << 8;

        if (wordis(word, "N") || wordis(word, "!next"))
            opcode |= (u64)1 << 7;

        if (wordis(word, "!jump"))
            opcode |= (u64)1 << 6;

        if (wordis(word, "m-src<a-src")) {
            opcode |= (u64)1 << 5;
            opcode |= (u64)1 << 0;
        }

        if (wordis(word, "m-srcM<=a-src")) {
            opcode |= (u64)1 << 5;
            opcode |= (u64)2 << 0;
        }

        if (wordis(word, "m-src==a-src")) {
            opcode |= (u64)1 << 5;
            opcode |= (u64)3 << 0;
        }

        if (wordis(word, "pf")) {
            opcode |= (u64)1 << 5;
            opcode |= (u64)4 << 0;
        }

        if (wordis(word, "pf-or-int")) {
            opcode |= (u64)1 << 5;
            opcode |= (u64)5 << 0;
        }

        if (wordis(word, "pf-or-int-or-sb")) {
            opcode |= (u64)1 << 5;
            opcode |= (u64)6 << 0;
        }

        if (wordis(word, "T")) {
            opcode |= (u64)1 << 5;
            opcode |= (u64)7 << 0;
        }

        if (prefixis(word, "pc=")) {
            int a;
            char l[256];
            unsigned int lpc;
            if (sscanf(word, "pc=%o", &lpc) != 1) {
                sscanf(word, "pc=%s", l);
                find_label(l, &lpc);
            }
            opcode |= (u64)(lpc) << 12;
        }

        if (prefixis(word, "m-rot<<=")) {
            unsigned int rot;
            sscanf(word, "m-rot<<=%d", &rot);
            opcode |= (u64)(rot) << 0;
        }

        if (prefixis(word, "->")) {
            int a, m;
            char dest[256];
            p = &word[2];

            while ((p = getword(p, dest))) {
                if (prefixis(dest, "a[")) {
                    opcode |= (u64)1 << 25;
                    n = sscanf(dest, "a[%o]", &a);
                    opcode |= (u64)a << 14;
                }
                if (prefixis(dest, "m[")) {
                    n = sscanf(dest, "m[%o]", &m);
                    opcode |= (u64)m << 14;
                }
                if (wordis(dest, "pdl[ptr]+push")) {
                    opcode |= (u64)011 << 19;
                }
                if (wordis(dest, "vma")) {
                    opcode |= (u64)020 << 19;
                }
                if (wordis(dest, "vma+read")) {
                    opcode |= (u64)021 << 19;
                }
                if (wordis(dest, "vma+write")) {
                    opcode |= (u64)022 << 19;
                }
                if (wordis(dest, "md")) {
                    opcode |= (u64)030 << 19;
                }
                if (wordis(dest, "md+read")) {
                    opcode |= (u64)031 << 19;
                }
                if (wordis(dest, "md+write")) {
                    opcode |= (u64)032 << 19;
                }
            }
        }

        if (!p)
            break;
    }

ok:
    if (list) fprintf(list, "%03o %016llo %s\n", pc, opcode, line);

    if (list) fprintf(list, "\t");
    disassemble_ucode_loc(pc, opcode, list);

    if (0) printf("\n");

    mem[pc] = opcode;
    set[pc]++;

    pc++;
    return 0;

print:
    if (list) fprintf(list, "                      %s\n", line);
    return 0;

err:
    if (list) fprintf(list, "error                 %s\n", line);
    return -1;
}

int
process_lines(FILE *in, FILE *list)
{
    char line[1024];
    int errors = 0;

    while (fgets(line, sizeof(line), in)) {
        int l = strlen(line);
        if (l && line[l-1] == '\n')
            line[l-1] = 0;
        if (process_line(line, list))
            errors++;
    }

    if (errors) {
        fprintf(stderr, "%d errors\n", errors);
    }
}

int
dump_output(FILE *out)
{
    int i;

    for (i = 0; i < 01000; i++) {
        if (set[i]) {
            fprintf(out, "I %04o %016llo\n", i, mem[i]);
        }
    }

    for (i = 0; i < 1024; i++) {
        if (a_mem_set[i])
            fprintf(out, "A %04o %o\n", i, a_mem[i]);
    }

    for (i = 0; i < 32; i++) {
        if (m_mem_set[i])
            fprintf(out, "M %04o %o\n", i, m_mem[i]);
    }

    for (i = 0; i < 2048; i++) {
        if (d_mem_set[i])
            fprintf(out, "D %04o %o\n", i, d_mem[i]);
    }

    for (i = 0; i < 2048; i++) {
        if (vmem0_set[i])
            fprintf(out, "0 %04o %o\n", i, vmem0[i]);
    }

    for (i = 0; i < 1024; i++) {
        if (vmem1_set[i])
            fprintf(out, "1 %04o %o\n", i, vmem1[i]);
    }
}

extern char *optarg;

main(int argc, char *argv[])
{
    int i, c;
    char *in_filename;
    char *out_filename;
    char *list_filename;
    FILE *in, *out, *list;

    in_filename = NULL;
    out_filename = "output";
    list_filename = NULL;

    out = NULL;
    list = NULL;
    in = stdin;

    while ((c = getopt(argc, argv, "l:o:")) != -1) {
        switch (c) {
        case 'o':
            out_filename = strdup(optarg);
            break;
        case 'l':
            list_filename = strdup(optarg);
            break;
        }
    }

    if (in_filename)
        in = fopen(in_filename, "r");

    if (!in) {
        perror(in_filename ? in_filename : "stdin");
        exit(1);
    }

    if (list_filename)
        list = fopen(list_filename, "w");
    else
        list = stdout;

    process_lines(in, list);

    fclose(in);
    if (list)
        fclose(list);

    out = fopen(out_filename, "w");

    if (!out) {
        perror(out_filename);
        exit(1);
    }

    dump_output(out);

    fclose(out);

    exit(0);
}



/*
 * Local Variables:
 * indent-tabs-mode:nil
 * c-basic-offset:4
 * End:
*/
