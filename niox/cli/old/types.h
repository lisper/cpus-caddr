/*
 */

#ifndef __TYPES_H_
#define __TYPES_H_

typedef unsigned long u32;
typedef unsigned short u16;
typedef unsigned char u8;

typedef unsigned long u_int32;
typedef unsigned char u_char;
typedef unsigned short u_short;

#ifndef _BIT
#define _BIT(n)	(1 << (n))
#endif

#ifndef _SBF
#define _SBF(f,v) ((v) << (f))
#endif

#define _BITMASK(field_width) ( _BIT(field_width) - 1)

#define NULL 0

#define __constant_htonl(x) \
        ((unsigned long int)((((unsigned long int)(x) & 0x000000ffU) << 24) | \
                             (((unsigned long int)(x) & 0x0000ff00U) <<  8) | \
                             (((unsigned long int)(x) & 0x00ff0000U) >>  8) | \
                             (((unsigned long int)(x) & 0xff000000U) >> 24)))

#define __constant_htons(x) \
        ((unsigned short int)((((unsigned short int)(x) & 0x00ff) << 8) | \
                              (((unsigned short int)(x) & 0xff00) >> 8)))

#define ntohl(x) \
(__builtin_constant_p(x) ? \
 __constant_htonl((x)) : \
 __swap32(x))
#define htonl(x) \
(__builtin_constant_p(x) ? \
 __constant_htonl((x)) : \
 __swap32(x))
#define ntohs(x) \
(__builtin_constant_p(x) ? \
 __constant_htons((x)) : \
 __swap16(x))
#define htons(x) \
(__builtin_constant_p(x) ? \
 __constant_htons((x)) : \
 __swap16(x))

static inline unsigned long __swap32(unsigned long x)
{
	return
        ((unsigned long int)((((unsigned long int)(x) & 0x000000ffU) << 24) |
                             (((unsigned long int)(x) & 0x0000ff00U) <<  8) |
                             (((unsigned long int)(x) & 0x00ff0000U) >>  8) |
                             (((unsigned long int)(x) & 0xff000000U) >> 24)));
}

static inline unsigned short __swap16(unsigned short x)
{
	return
        ((unsigned short)((((unsigned short)(x) & 0x00ff) << 8) |
			  (((unsigned short)(x) & 0xff00) >> 8)));
}

/* Make routines available to all */
#define	swap32(x)	__swap32(x)
#define	swap16(x)	__swap16(x)

#endif /* __TYPES_H_ */
