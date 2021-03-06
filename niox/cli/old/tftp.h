/**************************************************************************
Etherboot -  BOOTP/TFTP Bootstrap Program

Author: Martin Renters
  Date: Dec/93

**************************************************************************/

//#include "osdep.h"

#define ESC		'\033'

/*  Edit this to change the path to hostspecific kernel image
    kernel.<client_ip_address> in RARP boot */
#ifndef	DEFAULT_KERNELPATH
#define	DEFAULT_KERNELPATH	"/tftpboot/kernel.%I"
#endif

/* Edit this to change the default fallback kernel image.
   This is used if bootp/dhcp-server doesn't provide the kernel path */
#ifndef	DEFAULT_BOOTFILE
#define DEFAULT_BOOTFILE	"/tftpboot/kernel"
#endif

#ifndef	MAX_TFTP_RETRIES
#define MAX_TFTP_RETRIES	20
#endif

#ifndef	MAX_BOOTP_RETRIES
#define MAX_BOOTP_RETRIES	20
#endif

#define MAX_BOOTP_EXTLEN	(ETH_FRAME_LEN-ETH_HLEN-sizeof(struct bootp_t))

#ifndef	MAX_ARP_RETRIES
#define MAX_ARP_RETRIES		20
#endif

#define	TICKS_PER_SEC		(ticks_per_sec())

/* Inter-packet retry in ticks */
#define TIMEOUT			(10*TICKS_PER_SEC)

/* These settings have sense only if compiled with -DCONGESTED */
/* total retransmission timeout in ticks */
#define TFTP_TIMEOUT		(30*TICKS_PER_SEC)
/* packet retransmission timeout in ticks */
#define TFTP_REXMT		(3*TICKS_PER_SEC)

#ifndef	NULL
#define NULL	((void *)0)
#endif

/*
   I'm moving towards the defined names in linux/if_ether.h for clarity.
   The confusion between 60/64 and 1514/1518 arose because the NS8390
   counts the 4 byte frame checksum in the incoming packet, but not
   in the outgoing packet. 60/1514 are the correct numbers for most
   if not all of the other NIC controllers. I will be retiring the
   64/1518 defines in the lead-up to 5.0.
*/

#define ETH_ALEN		6	/* Size of Ethernet address */
#define ETH_HLEN		14	/* Size of ethernet header */
#define	ETH_ZLEN		60	/* Minimum packet */
/*#define ETH_MIN_PACKET		64*/
#define	ETH_FRAME_LEN		1514	/* Maximum packet */
/*#define ETH_MAX_PACKET		1518*/

#define ARP_CLIENT	0
#define ARP_SERVER	1
#define ARP_GATEWAY	2
#define ARP_ROOTSERVER	3
#define ARP_SWAPSERVER	4
#define MAX_ARP		ARP_SWAPSERVER+1

#define	RARP_REQUEST	3
#define	RARP_REPLY	4

#define IP		0x0800
#define ARP		0x0806
#define	RARP		0x8035

#define BOOTP_SERVER	67
#define BOOTP_CLIENT	68
#define TFTP_PORT	69
#define SUNRPC_PORT	111

#define IP_UDP		17
/* Same after going through htonl */
#define IP_BROADCAST	0xFFFFFFFF

#define ARP_REQUEST	1
#define ARP_REPLY	2

#define BOOTP_REQUEST	1
#define BOOTP_REPLY	2

#define TAG_LEN(p)		(*((p)+1))
#define RFC1533_COOKIE		99, 130, 83, 99
#define RFC1533_PAD		0
#define RFC1533_NETMASK		1
#define RFC1533_TIMEOFFSET	2
#define RFC1533_GATEWAY		3
#define RFC1533_TIMESERVER	4
#define RFC1533_IEN116NS	5
#define RFC1533_DNS		6
#define RFC1533_LOGSERVER	7
#define RFC1533_COOKIESERVER	8
#define RFC1533_LPRSERVER	9
#define RFC1533_IMPRESSSERVER	10
#define RFC1533_RESOURCESERVER	11
#define RFC1533_HOSTNAME	12
#define RFC1533_BOOTFILESIZE	13
#define RFC1533_MERITDUMPFILE	14
#define RFC1533_DOMAINNAME	15
#define RFC1533_SWAPSERVER	16
#define RFC1533_ROOTPATH	17
#define RFC1533_EXTENSIONPATH	18
#define RFC1533_IPFORWARDING	19
#define RFC1533_IPSOURCEROUTING	20
#define RFC1533_IPPOLICYFILTER	21
#define RFC1533_IPMAXREASSEMBLY	22
#define RFC1533_IPTTL		23
#define RFC1533_IPMTU		24
#define RFC1533_IPMTUPLATEAU	25
#define RFC1533_INTMTU		26
#define RFC1533_INTLOCALSUBNETS	27
#define RFC1533_INTBROADCAST	28
#define RFC1533_INTICMPDISCOVER	29
#define RFC1533_INTICMPRESPOND	30
#define RFC1533_INTROUTEDISCOVER 31
#define RFC1533_INTROUTESOLICIT	32
#define RFC1533_INTSTATICROUTES	33
#define RFC1533_LLTRAILERENCAP	34
#define RFC1533_LLARPCACHETMO	35
#define RFC1533_LLETHERNETENCAP	36
#define RFC1533_TCPTTL		37
#define RFC1533_TCPKEEPALIVETMO	38
#define RFC1533_TCPKEEPALIVEGB	39
#define RFC1533_NISDOMAIN	40
#define RFC1533_NISSERVER	41
#define RFC1533_NTPSERVER	42
#define RFC1533_VENDOR		43
#define RFC1533_NBNS		44
#define RFC1533_NBDD		45
#define RFC1533_NBNT		46
#define RFC1533_NBSCOPE		47
#define RFC1533_XFS		48
#define RFC1533_XDM		49
#ifndef	NO_DHCP_SUPPORT
#define RFC2132_REQ_ADDR	50
#define RFC2132_MSG_TYPE	53
#define RFC2132_SRV_ID		54
#define RFC2132_PARAM_LIST	55
#define RFC2132_MAX_SIZE	57
#define	RFC2132_VENDOR_CLASS_ID	60

#define DHCPDISCOVER		1
#define DHCPOFFER		2
#define DHCPREQUEST		3
#define DHCPACK			5
#endif	/* NO_DHCP_SUPPORT */

#define RFC1533_VENDOR_MAJOR	0
#define RFC1533_VENDOR_MINOR	0

#define RFC1533_VENDOR_MAGIC	128
#define RFC1533_VENDOR_ADDPARM	129
#define	RFC1533_VENDOR_ETHDEV	130
#ifdef	IMAGE_FREEBSD
#define RFC1533_VENDOR_HOWTO    132
#endif
#define RFC1533_VENDOR_MNUOPTS	160
#define RFC1533_VENDOR_SELECTION 176
#define RFC1533_VENDOR_MOTD	184
#define RFC1533_VENDOR_NUMOFMOTD 8
#define RFC1533_VENDOR_IMG	192
#define RFC1533_VENDOR_NUMOFIMG	16

#define RFC1533_END		255

#define BOOTP_VENDOR_LEN	64
#ifndef	NO_DHCP_SUPPORT
#define DHCP_OPT_LEN		312
#endif	/* NO_DHCP_SUPPORT */

#define	TFTP_DEFAULTSIZE_PACKET	512
#define	TFTP_MAX_PACKET		1432 /* 512 */

#define TFTP_RRQ	1
#define TFTP_WRQ	2
#define TFTP_DATA	3
#define TFTP_ACK	4
#define TFTP_ERROR	5
#define TFTP_OACK	6

#define TFTP_CODE_EOF	1
#define TFTP_CODE_MORE	2
#define TFTP_CODE_ERROR	3
#define TFTP_CODE_BOOT	4
#define TFTP_CODE_CFG	5

#define AWAIT_ARP	0
#define AWAIT_BOOTP	1
#define AWAIT_TFTP	2
#define AWAIT_RARP	3
#define AWAIT_RPC	4
#define AWAIT_QDRAIN	5	/* drain queue, process ARP requests */

typedef struct {
	unsigned long	s_addr;
} in_addr;

struct arptable_t {
	in_addr ipaddr;
	unsigned char node[6];
};

/*
 * A pity sipaddr and tipaddr are not longword aligned or we could use
 * in_addr. No, I don't want to use #pragma packed.
 */
struct arprequest {
	unsigned short hwtype;
	unsigned short protocol;
	char hwlen;
	char protolen;
	unsigned short opcode;
	char shwaddr[6];
	char sipaddr[4];
	char thwaddr[6];
	char tipaddr[4];
};

struct iphdr {
	char verhdrlen;
	char service;
	unsigned short len;
	unsigned short ident;
	unsigned short frags;
	char ttl;
	char protocol;
	unsigned short chksum;
	in_addr src;
	in_addr dest;
};

struct udphdr {
	unsigned short src;
	unsigned short dest;
	unsigned short len;
	unsigned short chksum;
};

/* Format of a bootp packet */
struct bootp_t {
	char bp_op;
	char bp_htype;
	char bp_hlen;
	char bp_hops;
	unsigned long bp_xid;
	unsigned short bp_secs;
	unsigned short unused;
	in_addr bp_ciaddr;
	in_addr bp_yiaddr;
	in_addr bp_siaddr;
	in_addr bp_giaddr;
	char bp_hwaddr[16];
	char bp_sname[64];
	char bp_file[128];
#ifdef	NO_DHCP_SUPPORT
	char bp_vend[BOOTP_VENDOR_LEN];
#else
	char bp_vend[DHCP_OPT_LEN];
#endif	/* NO_DHCP_SUPPORT */
} __attribute__((packed));

/* Format of a bootp IP packet */
struct bootpip_t
{
	struct iphdr ip;
	struct udphdr udp;
	struct bootp_t bp;
} __attribute__((packed));

/* Format of bootp packet with extensions */
struct bootpd_t {
	struct bootp_t bootp_reply;
	unsigned char  bootp_extension[MAX_BOOTP_EXTLEN];
} __attribute__((packed));

#define	KERNEL_BUF	(bootp_data.bootp_reply.bp_file)

struct tftp_t {
	struct iphdr ip;
	struct udphdr udp;
	unsigned short opcode;
	union {
		char rrq[TFTP_DEFAULTSIZE_PACKET];
		struct {
			unsigned short block;
			char download[TFTP_MAX_PACKET];
		} data;
		struct {
			unsigned short block;
		} ack;
		struct {
			unsigned short errcode;
			char errmsg[TFTP_DEFAULTSIZE_PACKET];
		} err;
		struct {
			char data[TFTP_DEFAULTSIZE_PACKET+2];
		} oack;
	} u;
} __attribute__((packed));

/* define a smaller tftp packet solely for making requests to conserve stack
   512 bytes should be enough */
struct tftpreq_t {
	struct iphdr ip;
	struct udphdr udp;
	unsigned short opcode;
	union {
		char rrq[512];
		struct {
			unsigned short block;
		} ack;
		struct {
			unsigned short errcode;
			char errmsg[512-2];
		} err;
	} u;
} __attribute__((packed));

#define TFTP_MIN_PACKET	(sizeof(struct iphdr) + sizeof(struct udphdr) + 4)

/*
 *	Structure returned from eth_probe and passed to other driver
 *	functions.
 */

struct nic
{
	void		(*reset)(struct nic *);
	int		(*probe)(struct nic *);
	int		(*poll)(struct nic *);
	void		(*transmit)(struct nic *, const char *d,
				unsigned int t, unsigned int s, const char *p);
	void		(*disable)(struct nic *);
	int		flags;	/* driver specific flags */
	struct rom_info	*rom_info;	/* -> rom_info from main */
	unsigned char	*node_addr;
	char		*packet;
	unsigned int	packetlen;
	void		*priv_data;	/* driver can hang private data here */
};

/***************************************************************************
External prototypes
***************************************************************************/

extern int tftp (const char *name, int (*)(unsigned char *, int, int, int));
extern int udp_transmit (unsigned long destip, unsigned int srcsock,
			   unsigned int destsock, int len, const void *buf);
extern int await_reply (int type, int ival, void *ptr, int timeout);
extern int decode_rfc1533 (unsigned char *, int, int, int);
extern int rfc951_sleep (int);
extern void cleanup (void);

extern void eth_reset(void);
extern int eth_probe(void);
extern int eth_poll(void);
extern void eth_transmit(const char *d, unsigned int t, unsigned int s, const void *p);
extern void eth_disable(void);

extern int os_download (unsigned int, unsigned char *,unsigned int);

/* misc.c */
extern void twiddle (void);
extern int strcasecmp (char *a, char *b);
extern int getdec (char **);
extern void printf (const char *, ...);
extern int sprintf (char *, const char *, ...);

extern void putchar (int);
extern int getchar (void);
extern int iskey (void);

extern unsigned long currticks (void);

/***************************************************************************
External variables
***************************************************************************/

extern char *hostname;
extern int hostnamelen;
extern struct arptable_t arptable[MAX_ARP];
extern char *motd[RFC1533_VENDOR_NUMOFMOTD];
extern struct bootpd_t bootp_data;
extern unsigned char *end_of_rfc1533;
extern struct nic nic;

/* created by linker */
extern char _start[], edata[], end[];


/*
 * Local Variables:
 * indent-tabs-mode:nil
 * c-basic-offset:4
 * End:
*/
