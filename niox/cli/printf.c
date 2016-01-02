#include <stdarg.h>

int printf(const char *format, ...);
int xprintf(const char *format, ...);

#ifdef TEST
#endif

static void
putdecbyte(int v)
{
  xprintf("%d", v & 0xff);
}

int
xprintf(const char *format, ...)
{
  static const char hex[] = "0123456789ABCDEF";
  char format_flag;
  unsigned int u_val, div_val, base, size, fill;
  char *ptr;
  va_list ap;

  va_start (ap, format);
  for (;;) {
    while ((format_flag = *format++) != '%') {      // Until '%' or '\0'
      if (!format_flag) {
	va_end (ap);
	return (0);
      }
      putchar(format_flag);
    }

    size = *format;
    fill = 0;

    if (size == '0') {
      fill = '0';
      size = *++format;
    }

    if ('1' <= size && size <= '9') {
      size -= '0';
      format++;
    }
    else
      size = 0;

    switch (format_flag = *format++) {
    case 'c': format_flag = va_arg(ap,int);
    default:  putchar(format_flag); continue;

    case 's':
      ptr = va_arg(ap,char *);
      while (*ptr) putchar(*ptr++);
      break;

#if 0
    case 'I':
      u_val = va_arg(ap,int);
      putdecbyte(u_val >> 24);
      putchar('.');
      putdecbyte(u_val >> 16);
      putchar('.');
      putdecbyte(u_val >> 8);
      putchar('.');
      putdecbyte(u_val);
      break;
#endif

    case 'd': base = 10; div_val = 100000000U; goto CONVERSION_LOOP;
//    case 'o': base = 8; div_val = 0100000000; goto CONVERSION_LOOP;
    case 'o': base = 8; div_val = 010000000000U; goto CONVERSION_LOOP;
    case 'x': base = 16; div_val = 0x10000000U;

    CONVERSION_LOOP:
    u_val = va_arg(ap,int);
    if (format_flag == 'd') {
      if (((int)u_val) < 0) {
	u_val = - u_val;
	putchar('-');
      }
      while (div_val > 1 && div_val > u_val) div_val /= 10;
    }
    if (size > 0) {
      static int pow10[] = { 0,1,10,100,1000,10000,100000,1000000,10000000 };
      switch (base) {
      case 8:  div_val = 1 << ((size-1) * 3); break;
      case 10: div_val = pow10[size]; break;
      case 16: div_val = 1 << ((size-1) * 4); break;
      }
    }
    do {
      putchar(hex[u_val / div_val]);
      u_val %= div_val;
      div_val /= base;
    } while (div_val);
    }
  }
}

#if 0
main()
{
  xprintf("hi\n");
  xprintf("dec %d\n", 1234);
  xprintf("hex %x\n", 0x1234);
  xprintf("oct %o\n", 01234);
  xprintf("str %s\n", "1234");
}
#endif

