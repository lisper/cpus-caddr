/*
 */

#include "diag.h"

size_t
strlen(const char *s)
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
strcpy(char *t, const char *f)
{
    char *tmp = t;

    while ((*t++ = *f++) != '\0')
        ;

    return tmp;
}

void *memcpy(void *t, const void *f, size_t n)
{
  char *to = (char *)t;
  char *from = (char *)f;
  int len = n;

  while (len--)
    *to++ = *from++;

  return to;
}

void *memset(void *t, int b, size_t n)
{
  char *to = (char *)t;
  int len = n;

  while (len--)
    *to++ = b;

  return to;
}

int memcmp(const void *t, const void *f, size_t n)
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

char *strncpy(char *to, const char *from, size_t len)
{
  char *orig_to = to;
  while (len--)
    if ((*to++ = *from++) == 0)
      break;
  return orig_to;
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


/*
 * Local Variables:
 * indent-tabs-mode:nil
 * c-basic-offset:4
 * End:
*/
