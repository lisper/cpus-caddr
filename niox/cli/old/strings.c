/*
 */

int
strlen(char *s)
{
    int l = 0;

    while (*s++)
        l++;

    return l;
}

int
strncasecmp(char *s1, char *s2, int n)
{
    int res = 0;

    while (n) {
        if ((res = *s1 - *s2++) != 0 || !*s1++)
            break;
        n--;
    }

    return res;
}

char *
strcpy(char *t, char *f)
{
    char *tmp = t;

    while ((*t++ = *f++) != '\0')
        ;

    return tmp;
}

void *memcpy(void *t, const void *f, unsigned long n)
{
  char *to = (char *)t;
  char *from = (char *)f;
  int len = n;

  while (len--)
    *to++ = *from++;

  return to;
}

void *memset(void *t, const char b, unsigned long n)
{
  char *to = (char *)t;
  int len = n;

  while (len--)
    *to++ = b;

  return to;
}

int memcmp(void *t, const void *f, unsigned long n)
{
  char *to = (char *)t;
  char *from = (char *)f;
  int len = n;

  while (len--)
    if (*to != *from)
      return *to - *from;
    else
      to++, from++;

  return 0;
}

void strncpy(char *to, char *from, int len)
{
  while (len--)
    if ((*to++ = *from++) == 0)
      break;
}

int strcmp(char *s1, char *s2)
{
  while (*s1 && *s2) {
    if (*s1 != *s2)
      return *s1 - *s2;
    s1++, s2++;
  }

  return *s1 - *s2;
}

int strcasecmp(char *s1, char *s2)
{
  return strcmp(s1, s2);
}

unsigned long
udivmodsi4(unsigned long num, unsigned long den, int modwanted)
{
  unsigned long bit = 1;
  unsigned long res = 0;

  while (den < num && bit && !(den & (1L<<31)))
    {
      den <<=1;
      bit <<=1;
    }
  while (bit)
    {
      if (num >= den)
	{
          num -= den;
          res |= bit;
	}
      bit >>=1;
      den >>=1;
    }
  if (modwanted) return num;
  return res;
}

long
__udivsi3 (long a, long b)
{
  return udivmodsi4 (a, b, 0);
}

long
__umodsi3 (long a, long b)
{
  return udivmodsi4 (a, b, 1);
}

long
__divsi3 (long a, long b)
{
  int neg = 0;
  long res;

  if (a < 0)
    {
      a = -a;
      neg = !neg;
    }

  if (b < 0)
    {
      b = -b;
      neg = !neg;
    }

  res = udivmodsi4 (a, b, 0);

  if (neg)
    res = -res;

  return res;
}



/*
 * Local Variables:
 * indent-tabs-mode:nil
 * c-basic-offset:4
 * End:
*/
