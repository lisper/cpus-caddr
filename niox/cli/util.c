/*
 * util.c
 */

#include "diag.h"

#define printf xprintf

#if 0
char tohex(char b)
{
    b = b & 0xf;
    if (b < 10) return '0' + b;
    return 'a' + (b - 10);
}

void
dumpmem(char *ptr, int len)
{
    char line[80], chars[80], *p, b, *c, *end;
    int i, j;

    end = ptr + len;
    while (ptr < end) {

	p = line;
	c = chars;
	printf("%x ", ptr);

	*p++ = ' ';
	for (j = 0; j < 16; j++) {
		if (ptr < end) {
			b = *ptr++;
			*p++ = tohex(b >> 4);
			*p++ = tohex(b);
			*p++ = ' ';
			*c++ = ' ' <= b && b <= '~' ? b : '.';
		} else {
			*p++ = 'x';
			*p++ = 'x';
			*p++ = ' ';
			*c++ = 'x';
		}
	}
	*p = 0;
	*c = 0;
        printf("%s %s\n",
	       line, chars);
    }
}
#endif

void
dumpmem32(void *addr, int len)
{
    u32 *lp;
    int c;

    lp = (u32 *)addr;
    c = 0;

    while (len > 0) {
        if (c++ == 0) printf("%8x: ", lp);

        printf("%8x ", *lp++);

        if (c >= 4) {
            c = 0;
            printf("\n");
        }

        len--;
    }

    if (c > 0) printf("\n");
}

static int
getdig(char ch, int *pdig)
{
    if ('0' <= ch && ch <= '9') {
        *pdig = ch - '0';
        return 0;
    }

    if ('a' <= ch && ch <= 'f') {
        *pdig = ch - 'a' + 10;
        return 0;
    }

    if ('A' <= ch && ch <= 'F') {
        *pdig = ch - 'A' + 10;
        return 0;
    }

    printf("\ndigit? 0x%x %c\n", ch, ch);
    return -1;
}

int
getnumber(char *str, int *pnum)
{
    int radix, num, d;
    char *p;

    if (0) printf("getnumber() '%s'\n", str);

    radix = 10;
    p = str;
    num = 0;

    if (str[0] == '0' && str[1] == 'x') {
        radix = 16;
        p += 2;
    }

    if (0) printf("radix %d\n", radix);

    while (*p) {
        if (getdig(*p++, &d))
            return -1;
            
        num = (num * radix) + d;
    }

    if (0) printf("num %d (0x%x)\n", num, num);

    *pnum = num;
    return 0;
}



/*
 * Local Variables:
 * indent-tabs-mode:nil
 * c-basic-offset:4
 * End:
*/
