/* */

typedef unsigned int u_char;
typedef unsigned int size_t;

typedef unsigned int u32;
typedef volatile unsigned int vu32;

size_t strlen(const char *s);
char *strcpy(char *dest, const char *src);
char *strncpy(char *dest, const char *src, size_t n);
int printf(const char *format, ...);
void *memcpy(void *dest, const void *src, size_t n);
void *memset(void *s, int c, size_t n);
int memcmp(const void *s1, const void *s2, size_t n);
