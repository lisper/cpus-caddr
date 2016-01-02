/**************************************************************************
Etherboot -  BOOTP/TFTP Bootstrap Program

Author: Martin Renters
  Date: Dec/93

Literature dealing with the network protocols:
	ARP - RFC826
	UDP - RFC768
	BOOTP - RFC951, RFC2132 (vendor extensions)
	DHCP - RFC2131, RFC2132 (options)
	TFTP - RFC1350, RFC2347 (options), RFC2348 (blocksize), RFC2349 (tsize)

**************************************************************************/

/* #define MDEBUG */

#define VERSION_MAJOR 1
#define VERSION_MINOR 0

#include "diag.h"
#include "tftp.h"

struct arptable_t	arptable[MAX_ARP];
static unsigned long	netmask;
char *hostname = "";
int hostnamelen = 0;
static unsigned long xid;
static int bootp_completed = 0;
unsigned char *end_of_rfc1533 = NULL;
static int vendorext_isvalid;
static struct bootpd_t bootp_data;

static const unsigned char vendorext_magic[] = {0xE4,0x45,0x74,0x68};/* ‰Eth */
//static const unsigned char broadcast[] = { 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF};
static const unsigned short broadcast[] = { 0xFFFF, 0xFFFF, 0xFFFF};

char *motd[RFC1533_VENDOR_NUMOFMOTD];

#ifdef	NO_DHCP_SUPPORT
char    rfc1533_cookie[5] = { RFC1533_COOKIE, RFC1533_END };
#else	/* !NO_DHCP_SUPPORT */
static int dhcp_reply;
static in_addr dhcp_server = { 0L };
static in_addr dhcp_addr = { 0L };
unsigned char rfc1533_cookie[] = { RFC1533_COOKIE};
unsigned char rfc1533_end[] = {RFC1533_END };
static const unsigned char dhcpdiscover[] = {
	RFC2132_MSG_TYPE,1,DHCPDISCOVER,
	RFC2132_MAX_SIZE,2,	/* request as much as we can */
	sizeof(struct bootpd_t) / 256, sizeof(struct bootpd_t) % 256,
	RFC2132_VENDOR_CLASS_ID,8,'B','l','o','b',
	'-',VERSION_MAJOR+'0','.',VERSION_MINOR+'0',
	RFC2132_PARAM_LIST,4,RFC1533_NETMASK,RFC1533_GATEWAY,
	RFC1533_HOSTNAME,RFC1533_VENDOR
};
static const unsigned char dhcprequest [] = {
	RFC2132_MSG_TYPE,1,DHCPREQUEST,
	RFC2132_SRV_ID,4,0,0,0,0,
	RFC2132_REQ_ADDR,4,0,0,0,0,
	RFC2132_MAX_SIZE,2,	/* request as much as we can */
	sizeof(struct bootpd_t) / 256, sizeof(struct bootpd_t) % 256,
	/* request parameters */
	RFC2132_PARAM_LIST,
	/* 5 standard + 5 vendortags + 8 motd + 16 menu items */
	5 + 5 + 8 + 16,
	/* Standard parameters */
	RFC1533_NETMASK, RFC1533_GATEWAY,
	RFC1533_HOSTNAME,RFC1533_VENDOR,
	RFC1533_ROOTPATH,	/* only passed to the booted image */
	/* Etherboot vendortags */
	RFC1533_VENDOR_MAGIC,
	RFC1533_VENDOR_ADDPARM,
	RFC1533_VENDOR_ETHDEV,
	RFC1533_VENDOR_MNUOPTS, RFC1533_VENDOR_SELECTION,
	/* 8 MOTD entries */
	RFC1533_VENDOR_MOTD,
	RFC1533_VENDOR_MOTD+1,
	RFC1533_VENDOR_MOTD+2,
	RFC1533_VENDOR_MOTD+3,
	RFC1533_VENDOR_MOTD+4,
	RFC1533_VENDOR_MOTD+5,
	RFC1533_VENDOR_MOTD+6,
	RFC1533_VENDOR_MOTD+7,
	/* 16 image entries */
	RFC1533_VENDOR_IMG,
	RFC1533_VENDOR_IMG+1,
	RFC1533_VENDOR_IMG+2,
	RFC1533_VENDOR_IMG+3,
	RFC1533_VENDOR_IMG+4,
	RFC1533_VENDOR_IMG+5,
	RFC1533_VENDOR_IMG+6,
	RFC1533_VENDOR_IMG+7,
	RFC1533_VENDOR_IMG+8,
	RFC1533_VENDOR_IMG+9,
	RFC1533_VENDOR_IMG+10,
	RFC1533_VENDOR_IMG+11,
	RFC1533_VENDOR_IMG+12,
	RFC1533_VENDOR_IMG+13,
	RFC1533_VENDOR_IMG+14,
	RFC1533_VENDOR_IMG+15,
};

#endif	/* NO_DHCP_SUPPORT */

static long pad1;
static char pad[2];
static char	packet[ETH_FRAME_LEN];
static char twiddling;

static int eth_dummy(struct nic *nic)
{
	return (0);
}

struct nic nic =
{
	(void (*)(struct nic *))eth_dummy,	/* reset */
	(int (*)(struct nic *))eth_dummy,	/* probe */
	(int (*)(struct nic *))eth_dummy,	/* poll */
	(void (*)(struct nic *, const char *,
		  unsigned int, unsigned int,
		  const char *))eth_dummy,	/* transmit */
	(void (*)(struct nic *))eth_dummy,	/* disable */
	0,			/* flags: no aui */
	0,			/* rom_info */
	arptable[ARP_CLIENT].node,	/* node_addr */
	packet+2,		/* packet */
	0,			/* packetlen */
	0,			/* priv_data */
};

int eth_probe(void)
{
	if (cs89x0_probe(&nic, NULL)) {
		return (1);
	}
	return (0);
}

void eth_reset(void)
{
	(*nic.reset)(&nic);
}

int eth_poll(void)
{
	return ((*nic.poll)(&nic));
}

void eth_transmit(const char *d, unsigned int t, unsigned int s, const void *p)
{
	(*nic.transmit)(&nic, d, t, s, p);
	if (twiddling) {
//		twiddle();
		putchar('.');
	}
}

void eth_disable(void)
{
	(*nic.disable)(&nic);
}

/*
 *	Normally I would arrange the functions in a file to avoid forward
 *	declarations, but in this case I like to see main() as the first
 *	routine.
 */
static int bootp(void);
static int load(void);
static int downloadkernel(unsigned char *data, int block, int len, int eof);
static unsigned short ipchksum(unsigned short *ip, int len);

/**************************************************************************
MAIN - Kick off routine
**************************************************************************/
int tftp_start(void)
{
	if (!eth_probe()) {
		printf("No adapter found\n");
		return -1;
	}

	while (1) {
		/* -1:	timeout or ESC
		   -2:	error return from loader
		   0,1:	retry tftp with possibly modified bootp reply
		   2:	retry bootp and tftp
		   255:	exit Etherboot */

		switch (load()) {
		case 0:
		case 1:
			break;
		case 2:
			bootp_completed = 0;
			break;

		default:
			return -1;
		}
	}
}

static void
fix_kernel_name(char *n)
{
	int i;

	for (i = 0; i < 256; i++) {
		if (*n < ' ' || *n > '~') {
			*n = 0;
			break;
		}
	}
}

/**************************************************************************
LOAD - Try to get booted
**************************************************************************/
static int load(void)
{
	/* Find a server to get BOOTP reply from */
	if (!bootp_completed ||
	    !arptable[ARP_CLIENT].ipaddr.s_addr ||
	    !arptable[ARP_SERVER].ipaddr.s_addr)
	{
		bootp_completed = 0;
#ifndef	NO_DHCP_SUPPORT
		printf("Searching for server (DHCP)...\n");
#else
		printf("Searching for server (BOOTP)...\n");
#endif

		if (!bootp()) {
			printf("No Server found\n");
			return -1;
		}
		bootp_completed++;
	}
	printf("Me: %I, Server: %I",
	       ntohl(arptable[ARP_CLIENT].ipaddr.s_addr),
	       ntohl(arptable[ARP_SERVER].ipaddr.s_addr));
	if (bootp_data.bootp_reply.bp_giaddr.s_addr)
		printf(", Relay: %I",
		       ntohl(bootp_data.bootp_reply.bp_giaddr.s_addr));
	if (arptable[ARP_GATEWAY].ipaddr.s_addr)
		printf(", Gateway %I",
		       ntohl(arptable[ARP_GATEWAY].ipaddr.s_addr));
	putchar('\n');

	if (vendorext_isvalid) {
		//show_motd();
	}

	/* Now use TFTP to load file */
	{
		const char	*kernel;

		kernel = KERNEL_BUF[0] != '\0' ? KERNEL_BUF : DEFAULT_BOOTFILE;
		fix_kernel_name(kernel);
		printf("Loading %I:%s ",
		       ntohl(arptable[ARP_SERVER].ipaddr.s_addr), kernel);
		if (!tftp(kernel, downloadkernel)) {
			printf("Unable to load file.\n");
			return -1;
		}
	}

	return -2;
}

/**************************************************************************
DEFAULT_NETMASK - Return default netmask for IP address
**************************************************************************/
static inline unsigned long default_netmask(void)
{
	int net = ntohl(arptable[ARP_CLIENT].ipaddr.s_addr) >> 24;
	if (net <= 127)
		return(htonl(0xff000000));
	else if (net < 192)
		return(htonl(0xffff0000));
	else
		return(htonl(0xffffff00));
}

/**************************************************************************
UDP_TRANSMIT - Send a UDP datagram
**************************************************************************/
int udp_transmit(unsigned long destip, unsigned int srcsock,
	unsigned int destsock, int len, const void *buf)
{
	struct iphdr *ip;
	struct udphdr *udp;
	struct arprequest arpreq;
	int arpentry, i;
	int retry;

if (len > 512) len = 512;
	ip = (struct iphdr *)buf;
	udp = (struct udphdr *)((char *)buf + sizeof(struct iphdr));
	ip->verhdrlen = 0x45;
	ip->service = 0;
	ip->len = htons(len);
	ip->ident = 0;
	ip->frags = 0;
	ip->ttl = 60;
	ip->protocol = IP_UDP;
	ip->chksum = 0;
	ip->src.s_addr = arptable[ARP_CLIENT].ipaddr.s_addr;
	ip->dest.s_addr = destip;
	ip->chksum = ipchksum((unsigned short *)buf, sizeof(struct iphdr));
	udp->src = htons(srcsock);
	udp->dest = htons(destsock);
	udp->len = htons(len - sizeof(struct iphdr));
	udp->chksum = 0;
	if (destip == IP_BROADCAST) {
		eth_transmit(broadcast, IP, len, buf);
	} else {
		if (((destip & netmask) !=
			(arptable[ARP_CLIENT].ipaddr.s_addr & netmask)) &&
			arptable[ARP_GATEWAY].ipaddr.s_addr)
				destip = arptable[ARP_GATEWAY].ipaddr.s_addr;
		for(arpentry = 0; arpentry<MAX_ARP; arpentry++)
			if (arptable[arpentry].ipaddr.s_addr == destip) break;
		if (arpentry == MAX_ARP) {
			printf("%I is not in my arp table!\n", destip);
			return(0);
		}
		for (i = 0; i < ETH_ALEN; i++)
			if (arptable[arpentry].node[i])
				break;
		if (i == ETH_ALEN) {	/* Need to do arp request */
			arpreq.hwtype = htons(1);
			arpreq.protocol = htons(IP);
			arpreq.hwlen = ETH_ALEN;
			arpreq.protolen = 4;
			arpreq.opcode = htons(ARP_REQUEST);
			memcpy(arpreq.shwaddr, arptable[ARP_CLIENT].node, ETH_ALEN);
			memcpy(arpreq.sipaddr, &arptable[ARP_CLIENT].ipaddr, sizeof(in_addr));
			memset(arpreq.thwaddr, 0, ETH_ALEN);
			memcpy(arpreq.tipaddr, &destip, sizeof(in_addr));
			for (retry = 1; retry <= MAX_ARP_RETRIES; retry++) {
				eth_transmit(broadcast, ARP, sizeof(arpreq),
					&arpreq);
				if (await_reply(AWAIT_ARP, arpentry,
						arpreq.tipaddr, TIMEOUT))
					goto xmit;
				if (!rfc951_sleep(retry))
					return 0;
				/* We have slept for a while - the packet may
				 * have arrived by now.  If not, we have at
				 * least some room in the Rx buffer for the
				 * next reply.  */
				if (await_reply(AWAIT_ARP, arpentry,
						arpreq.tipaddr, 0))
					goto xmit;
			}
			return(0);
		}
xmit:
		eth_transmit(arptable[arpentry].node, IP, len, buf);
	}
	return(1);
}

static char *dl_ptr;

#define KERNEL_RAM_BASE 0xc0800000

void os_bootkernel(void)
{
	extern void move_and_boot(void), move_and_boot_end(void);
	void (*boot)(int);

	printf("\nmove and boot kernel\n");

	/* copy relocator code to low memory */
	memcpy((char *)0xc0000000, (char *)move_and_boot, 
	       (char *)move_and_boot_end - (char *)move_and_boot);

	/* move kernel to correct location and call it */
	boot = (void (*)(int))0xc0000000;
	(*boot)(997);
}

int os_download(unsigned int block, unsigned char *data, unsigned int len)
{
	if (len == 0) {
		os_bootkernel();
		return 0;
	}

	if (block == 1) {
		dl_ptr = (char *)0xc1000000;
	}

	if (dl_ptr+len > (char *)0xc1ffffff)
		return 0;

	memcpy(dl_ptr, data, len);
	dl_ptr += len;

	return 1;
}

/**************************************************************************
DOWNLOADKERNEL - Try to load file
**************************************************************************/
static int downloadkernel(unsigned char *data, int block, int len, int eof)
{
	static int rlen = 0;

	if (twiddling) {
		twiddling = 0;
		printf("\n");
	}

	if (!(block % 4) || eof) {
		int size;
		size = ((block-1) * rlen + len) / 1024;

		putchar('\b');
		putchar('\b');
		putchar('\b');
		putchar('\b');

		putchar('0' + (size/1000)%10);
		putchar('0' + (size/100)%10);
		putchar('0' + (size/10)%10);
		putchar('0' + (size/1)%10);
	}

	if (block == 1)
	{
		rlen=len;

		if (eof /*|| *((unsigned long *)data) != 0x464C457FL*/)
		{
			printf("error: not a valid image\n");
			return(0); /* error */
		}
	}
	if (len != 0) {
		if (!os_download(block, data, len))
			return(0); /* error */
	}
	if (eof) {
		os_download(block+1, data, 0); /* does not return */
		return(0); /* error */
	}
	return(-1); /* there is more data */
}

/**************************************************************************
TFTP - Download extended BOOTP data, or kernel image
**************************************************************************/
int tftp(const char *name, int (*fnc)(unsigned char *, int, int, int))
{
	int             retry = 0;
	static unsigned short iport = 2000;
	unsigned short  oport;
	unsigned short  len, block = 0, prevblock = 0;
	int		bcounter = 0;
	struct tftp_t  *tr;
	struct tftpreq_t tp;
	int		rc;
	int		packetsize = TFTP_DEFAULTSIZE_PACKET;

	/* Clear out the Rx queue first.  It contains nothing of interest,
	 * except possibly ARP requests from the DHCP/TFTP server.  We use
	 * polling throughout Etherboot, so some time may have passed since we
	 * last polled the receive queue, which may now be filled with
	 * broadcast packets.  This will cause the reply to the packets we are
	 * about to send to be lost immediately.  Not very clever.  */
	await_reply(AWAIT_QDRAIN, 0, NULL, 0);

	tp.opcode = htons(TFTP_RRQ);
	/* Warning: the following assumes the layout of bootp_t.
	   But that's fixed by the IP, UDP and BOOTP specs. */
#if 0
	len = sizeof(tp.ip) + sizeof(tp.udp) + sizeof(tp.opcode) +
		sprintf((char *)tp.u.rrq, "%s%coctet%cblksize%c%d",
		name, 0, 0, 0, TFTP_MAX_PACKET) + 1;
#else
	{
		int l = strlen(name);
		char *p = tp.u.rrq;

		len = sizeof(tp.ip) + sizeof(tp.udp) + sizeof(tp.opcode) + 1;

		memcpy(tp.u.rrq, name, l);
		p += l;
		*p++ = 0;
		memcpy(p, "octet", 6);
		p += 6;
		memcpy(p, "blksize", 8);
		p += 8;
		memcpy(p, "1432", 5);
		p += 5;

		len += p - tp.u.rrq;
	}
//	printf("len %d\n", len);
//	dumpmem((char *)tp.u.rrq, 64);
//	printf("tp\n");
//	dumpmem((char *)&tp, 64);
#endif
	if (!udp_transmit(arptable[ARP_SERVER].ipaddr.s_addr, ++iport,
			  TFTP_PORT, len, &tp))
		return (0);
	for (;;)
	{
#ifdef	CONGESTED
		if (!await_reply(AWAIT_TFTP, iport, NULL,
				 (block ? TFTP_REXMT : TIMEOUT)))
#else
		if (!await_reply(AWAIT_TFTP, iport, NULL, TIMEOUT))
#endif
		{
			if (!block && retry++ < MAX_TFTP_RETRIES)
			{	/* maybe initial request was lost */
				if (!rfc951_sleep(retry))
					return 0;
				if (!udp_transmit(arptable[ARP_SERVER].ipaddr.s_addr,
					++iport, TFTP_PORT, len, &tp))
					return (0);
				continue;
			}
#ifdef	CONGESTED
			if (block && ((retry += TFTP_REXMT) < TFTP_TIMEOUT))
			{	/* we resend our last ack */
#ifdef	MDEBUG
				printf("<REXMT>\n");
#endif
				udp_transmit(arptable[ARP_SERVER].ipaddr.s_addr,
					iport, oport,
					TFTP_MIN_PACKET, &tp);
				continue;
			}
#endif
			break;	/* timeout */
		}
		tr = (struct tftp_t *)&nic.packet[ETH_HLEN];
		if (tr->opcode == ntohs(TFTP_ERROR))
		{
			printf("TFTP error %d (%s)\n",
			       ntohs(tr->u.err.errcode),
			       tr->u.err.errmsg);
			break;
		}

		if (tr->opcode == ntohs(TFTP_OACK)) {
			char *p = tr->u.oack.data, *e;

			if (prevblock)		/* shouldn't happen */
				continue;	/* ignore it */
			len = ntohs(tr->udp.len) - sizeof(struct udphdr) - 2;
			if (len > TFTP_MAX_PACKET)
				goto noak;
			e = p + len;
			while (*p != '\000' && p < e) {
				if (!strcasecmp("blksize", p)) {
					p += 8;
					if ((packetsize = getdec(&p)) <
					    TFTP_DEFAULTSIZE_PACKET)
						goto noak;
					while (p < e && *p) p++;
					if (p < e)
						p++;
				}
				else {
				noak:
					tp.opcode = htons(TFTP_ERROR);
					tp.u.err.errcode = 8;
/*
 *	Warning: the following assumes the layout of bootp_t.
 *	But that's fixed by the IP, UDP and BOOTP specs.
 */
#if 0
					len = sizeof(tp.ip) + sizeof(tp.udp) + sizeof(tp.opcode) + sizeof(tp.u.err.errcode) +
						sprintf((char *)tp.u.err.errmsg,
						"RFC1782 error") + 1;
#else
					len = sizeof(tp.ip) + sizeof(tp.udp) + sizeof(tp.opcode) + sizeof(tp.u.err.errcode) + 13 + 1;
					memcpy((char *)tp.u.err.errmsg,
					       "RFC1782 error", 13);
#endif
					udp_transmit(arptable[ARP_SERVER].ipaddr.s_addr,
						     iport, ntohs(tr->udp.src),
						     len, &tp);
					return (0);
				}
			}
			if (p > e)
				goto noak;
			block = tp.u.ack.block = 0; /* this ensures, that */
						/* the packet does not get */
						/* processed as data! */
		}
		else if (tr->opcode == htons(TFTP_DATA)) {
			len = ntohs(tr->udp.len) - sizeof(struct udphdr) - 4;
			if (len > packetsize)	/* shouldn't happen */
				continue;	/* ignore it */
			block = ntohs(tp.u.ack.block = tr->u.data.block); }
		else /* neither TFTP_OACK nor TFTP_DATA */
			break;

		if ((block || bcounter) && (block != prevblock+1)) {
			/* Block order should be continuous */
			tp.u.ack.block = htons(block = prevblock);
		}
		tp.opcode = htons(TFTP_ACK);
		oport = ntohs(tr->udp.src);
		udp_transmit(arptable[ARP_SERVER].ipaddr.s_addr, iport,
			oport, TFTP_MIN_PACKET, &tp);	/* ack */
		if ((unsigned short)(block-prevblock) != 1) {
			/* Retransmission or OACK, don't process via callback
			 * and don't change the value of prevblock.  */
			continue;
		}
		prevblock = block;
		retry = 0;	/* It's the right place to zero the timer? */
		if ((rc = fnc(tr->u.data.download,
			      ++bcounter, len, len < packetsize)) >= 0)
			return(rc);
		if (len < packetsize)		/* End of data */
			return (1);
	}
	return (0);
}

/**************************************************************************
BOOTP - Get my IP address and load information
**************************************************************************/
static int bootp(void)
{
	int retry;
#ifndef	NO_DHCP_SUPPORT
	int reqretry;
#endif	/* NO_DHCP_SUPPORT */
	struct bootpip_t ip;
	unsigned long  starttime;

	memset(&ip, 0, sizeof(struct bootpip_t));
	ip.bp.bp_op = BOOTP_REQUEST;
	ip.bp.bp_htype = 1;
	ip.bp.bp_hlen = ETH_ALEN;
	starttime = currticks();
	/* Use lower 32 bits of node address, more likely to be
	   distinct than the time since booting */
	memcpy(&xid, &arptable[ARP_CLIENT].node[2], sizeof(xid));
	ip.bp.bp_xid = htonl(xid += htonl(starttime));
	memcpy(ip.bp.bp_hwaddr, arptable[ARP_CLIENT].node, ETH_ALEN);
#ifdef	NO_DHCP_SUPPORT
	/* request RFC-style options */
	memcpy(ip.bp.bp_vend, rfc1533_cookie, 5);
#else
	/* request RFC-style options */
	memcpy(ip.bp.bp_vend, rfc1533_cookie, sizeof rfc1533_cookie);
	memcpy(ip.bp.bp_vend + sizeof rfc1533_cookie,
	       dhcpdiscover, sizeof dhcpdiscover);

	memcpy(ip.bp.bp_vend + sizeof rfc1533_cookie + sizeof dhcpdiscover,
	       rfc1533_end, sizeof rfc1533_end);
#endif	/* NO_DHCP_SUPPORT */

	for (retry = 0; retry < MAX_BOOTP_RETRIES; ) {

		/* Clear out the Rx queue first.  It contains nothing of
		 * interest, except possibly ARP requests from the DHCP/TFTP
		 * server.  We use polling throughout Etherboot, so some time
		 * may have passed since we last polled the receive queue,
		 * which may now be filled with broadcast packets.  This will
		 * cause the reply to the packets we are about to send to be
		 * lost immediately.  Not very clever.  */
		await_reply(AWAIT_QDRAIN, 0, NULL, 0);

		udp_transmit(IP_BROADCAST, BOOTP_CLIENT, BOOTP_SERVER,
			sizeof(struct bootpip_t), &ip);
#ifdef	NO_DHCP_SUPPORT
		if (await_reply(AWAIT_BOOTP, 0, NULL, TIMEOUT))
			return(1);
#else
		if (await_reply(AWAIT_BOOTP, 0, NULL, TIMEOUT)) {
//printf("got reply %d want %d\n", dhcp_reply, DHCPOFFER);
			/* If not a DHCPOFFER then must be just a BOOTP reply,
			   be backward compatible with BOOTP then */
			if (dhcp_reply != DHCPOFFER)
				return(1);
			dhcp_reply = 0;
			memcpy(ip.bp.bp_vend, rfc1533_cookie, sizeof rfc1533_cookie);
			memcpy(ip.bp.bp_vend + sizeof rfc1533_cookie, dhcprequest, sizeof dhcprequest);
			memcpy(ip.bp.bp_vend + sizeof rfc1533_cookie + sizeof dhcprequest, rfc1533_end, sizeof rfc1533_end);
			/* Beware: the magic numbers 9 and 15 depend on
			   the layout of dhcprequest */
			memcpy(ip.bp.bp_vend + 9, &dhcp_server, sizeof(in_addr));
			memcpy(ip.bp.bp_vend + 15, &dhcp_addr, sizeof(in_addr));
			for (reqretry = 0; reqretry < MAX_BOOTP_RETRIES; ) {
				udp_transmit(IP_BROADCAST, BOOTP_CLIENT,
					     BOOTP_SERVER,
					     sizeof(struct bootpip_t), &ip);
				dhcp_reply=0;
				if (await_reply(AWAIT_BOOTP, 0, NULL, TIMEOUT))
					if (dhcp_reply == DHCPACK)
						return(1);
				if (!rfc951_sleep(++reqretry))
					return 0;
			}
		}
		if (!rfc951_sleep(++retry))
			return 0;
#endif	/* NO_DHCP_SUPPORT */
		ip.bp.bp_secs = htons((currticks()-starttime)/TICKS_PER_SEC);
	}
	return(0);
}

static int process_arp(int type, int ival, void *ptr)
{
	struct	arprequest *arpreply;
	unsigned long tmp;

	if (0) printf("process ARP\n");

	arpreply = (struct arprequest *) &nic.packet[ETH_HLEN];

	if (arpreply->opcode == htons(ARP_REPLY) &&
	    !memcmp(arpreply->sipaddr, ptr, sizeof(in_addr)) &&
	    type == AWAIT_ARP) {
		memcpy(arptable[ival].node, arpreply->shwaddr, ETH_ALEN);
		return 1;
	}

	memcpy(&tmp, arpreply->tipaddr, sizeof(in_addr));

	if (arpreply->opcode == htons(ARP_REQUEST) &&
	    tmp == arptable[ARP_CLIENT].ipaddr.s_addr) {
		arpreply->opcode = htons(ARP_REPLY);
		memcpy(arpreply->tipaddr, arpreply->sipaddr, sizeof(in_addr));
		memcpy(arpreply->thwaddr, arpreply->shwaddr, ETH_ALEN);
		memcpy(arpreply->sipaddr, &arptable[ARP_CLIENT].ipaddr,
		       sizeof(in_addr));
		memcpy(arpreply->shwaddr, arptable[ARP_CLIENT].node, ETH_ALEN);

		eth_transmit(arpreply->thwaddr, ARP, sizeof(struct arprequest),
			     arpreply);
#ifdef	MDEBUG
		memcpy(&tmp, arpreply->tipaddr, sizeof(in_addr));
		printf("Sent ARP reply to: %I\n",tmp);
#endif	/* MDEBUG */
	}

	return 0;
}

int process_bootp(int type, int ival, void *ptr)
{
	struct	bootp_t *bootpreply;

	printf("process BOOTP\n");

	if (nic.packetlen < (ETH_HLEN +
			     sizeof(struct iphdr) +
			     sizeof(struct udphdr) +
#ifdef	NO_DHCP_SUPPORT
			     sizeof(struct bootp_t)
#else
			     sizeof(struct bootp_t)-DHCP_OPT_LEN
#endif	/* NO_DHCP_SUPPORT */
			     )) {
		printf("process BOOTP; drop\n");
		return 0;
	}

	/* BOOTP ? */
	bootpreply = (struct bootp_t *)&nic.packet[ETH_HLEN +
						  sizeof(struct iphdr) +
						  sizeof(struct udphdr)];

	if (bootpreply->bp_op != BOOTP_REPLY ||
	    bootpreply->bp_xid != htonl(xid)) {
		printf("process BOOTP; drop, not reply or xid mismatch\n");
#if 0
		printf("bp_op %2x, want %2x\n", bootpreply->bp_op, BOOTP_REPLY);
		printf("bp_xid %x, want %x\n", bootpreply->bp_xid, htonl(xid));

		printf("bp_op %2x, bp_htype %2x, bp_hlen %2x, bp_hops %2x\n",
		       bootpreply->bp_op, bootpreply->bp_htype,
		       bootpreply->bp_hlen, bootpreply->bp_hops);

		printf("bp_hwaddr %2x:%2x\n",
		       bootpreply->bp_hwaddr[0], bootpreply->bp_hwaddr[1]);

		printf("&bp_xid %x\n", &bootpreply->bp_xid);
		dumpmem((char *)bootpreply, 64);
#endif
		return 0;
	}

	if (memcmp(broadcast, bootpreply->bp_hwaddr, ETH_ALEN) != 0 &&
	    memcmp(arptable[ARP_CLIENT].node, bootpreply->bp_hwaddr, ETH_ALEN) != 0) {
		printf("process BOOTP; drop, bad hw address\n");
		return 0;
	}

	/* bootp response ok */
	arptable[ARP_CLIENT].ipaddr.s_addr = bootpreply->bp_yiaddr.s_addr;
#ifndef	NO_DHCP_SUPPORT
	dhcp_addr.s_addr = bootpreply->bp_yiaddr.s_addr;
#endif	/* NO_DHCP_SUPPORT */
	netmask = default_netmask();
	arptable[ARP_SERVER].ipaddr.s_addr = bootpreply->bp_siaddr.s_addr;
	memset(arptable[ARP_SERVER].node, 0, ETH_ALEN);  /* Kill arp */
	arptable[ARP_GATEWAY].ipaddr.s_addr = bootpreply->bp_giaddr.s_addr;
	memset(arptable[ARP_GATEWAY].node, 0, ETH_ALEN);  /* Kill arp */
	/* bootpreply->bp_file will be copied to KERNEL_BUF in the memcpy */
	memcpy((char *)&bootp_data, (char *)bootpreply, sizeof(struct bootpd_t));
	decode_rfc1533(bootp_data.bootp_reply.bp_vend,
#ifdef	NO_DHCP_SUPPORT
		       0, BOOTP_VENDOR_LEN + MAX_BOOTP_EXTLEN,
#else
		       0, DHCP_OPT_LEN + MAX_BOOTP_EXTLEN,
#endif	/* NO_DHCP_SUPPORT */
		       1);

	return 1;
}

int process_ip(int type, int ival, void *ptr)
{
	struct	iphdr *ip;
	struct	udphdr *udp;

	if (0) printf("process IP\n");

	ip = (struct iphdr *)&nic.packet[ETH_HLEN];

	if (ip->verhdrlen != 0x45 ||
	    ipchksum((unsigned short *)ip, sizeof(struct iphdr)) ||
	    ip->protocol != IP_UDP)
	{
		printf("process IP; drop\n");
		return 0;
	}

	udp = (struct udphdr *)&nic.packet[ETH_HLEN + sizeof(struct iphdr)];

	switch (htons(udp->dest)) {
	case BOOTP_CLIENT:
		if (type != AWAIT_BOOTP)
			return 0;

//		process_bootp(type, ival, ptr);
		if (process_bootp(type, ival, ptr))
			return 1;
		break;

	default:
		/* TFTP ? */
		if (type == AWAIT_TFTP &&
		    ntohs(udp->dest) == ival) {
			return 1;
		}

		printf("process IP; ignore, dest udp port %d\n",
		       htons(udp->dest));
		break;
	}

	return 0;
}

/**************************************************************************
AWAIT_REPLY - Wait until we get a response for our request
**************************************************************************/
int await_reply(int type, int ival, void *ptr, int timeout)
{
	unsigned long time;
	unsigned short ptype;

	unsigned int protohdrlen = ETH_HLEN + sizeof(struct iphdr) +
				sizeof(struct udphdr);
	time = timeout + currticks();
	/* The timeout check is done below.  The timeout is only checked if
	 * there is no packet in the Rx queue.  This assumes that eth_poll()
	 * needs a negligible amount of time.  */
	for (;;) {
		if (eth_poll()) {	/* We have something! */
					/* Check for ARP - No IP hdr */
			if (nic.packetlen < ETH_HLEN)
				continue;

			ptype = ((unsigned short) nic.packet[12]) << 8
				| ((unsigned short) nic.packet[13]);

			if (0) printf("rx: ptype %x\n", ptype);

			switch (ptype) {
			case ARP:
				if (nic.packetlen >= ETH_HLEN +
				    sizeof(struct arprequest)) {
					if (process_arp(type, ival, ptr))
						return 1;
					continue;
				}
				break;

			case IP:
				if (type == AWAIT_QDRAIN)
					continue;

				if (nic.packetlen < protohdrlen)
					continue;

				if (process_ip(type, ival, ptr))
					return 1;

				break;

			default:
				break;
			}


		} else {
			/* Check for abort key only if the Rx queue is empty -
			 * as long as we have something to process, don't
			 * assume that something failed.  It is unlikely that
			 * we have no processing time left between packets.  */
			if (iskey()) {
				if (getchar() == ESC)
					return 0;
			}

			/* Do the timeout after at least a full queue walk.  */
			if ((timeout == 0) || (currticks() > time)) {
				break;
			}
		}
	}
	return(0);
}

/**************************************************************************
DECODE_RFC1533 - Decodes RFC1533 header
**************************************************************************/
int decode_rfc1533(unsigned char *p, int block, int len, int eof)
{
	static unsigned char *extdata = NULL, *extend = NULL;
	unsigned char        *extpath = NULL;
	unsigned char        *endp;

	if (block == 0) {
		memset(motd, 0, sizeof(motd));
		end_of_rfc1533 = NULL;
		vendorext_isvalid = 0;

		if (memcmp(p, rfc1533_cookie, 4))
			return(0); /* no RFC 1533 header found */
		p += 4;
		endp = p + len;
	} else {
		if (block == 1) {
			if (memcmp(p, rfc1533_cookie, 4))
				return(0); /* no RFC 1533 header found */
			p += 4;
			len -= 4; }
		if (extend + len <= (unsigned char *)&(bootp_data.bootp_extension[MAX_BOOTP_EXTLEN])) {
			memcpy(extend, p, len);
			extend += len;
		} else {
			printf("Overflow in vendor data buffer! Aborting...\n");
			*extdata = RFC1533_END;
			return(0);
		}
		p = extdata; endp = extend;
	}
	if (!eof)
		return (-1);
	while (p < endp) {
		unsigned char c = *p;
		if (c == RFC1533_PAD) {
			p++;
			continue;
		}
		else if (c == RFC1533_END) {
			end_of_rfc1533 = endp = p;
			continue;
		}
		else if (c == RFC1533_NETMASK)
			memcpy(&netmask, p+2, sizeof(in_addr));
		else if (c == RFC1533_GATEWAY) {
			/* This is a little simplistic, but it will
			   usually be sufficient.
			   Take only the first entry */
			if (TAG_LEN(p) >= sizeof(in_addr))
				memcpy(&arptable[ARP_GATEWAY].ipaddr, p+2, sizeof(in_addr));
		}
		else if (c == RFC1533_EXTENSIONPATH)
			extpath = p;
#ifndef	NO_DHCP_SUPPORT
		else if (c == RFC2132_MSG_TYPE)
			dhcp_reply=*(p+2);
		else if (c == RFC2132_SRV_ID)
			memcpy(&dhcp_server, p+2, sizeof(in_addr));
#endif	/* NO_DHCP_SUPPORT */
		else if (c == RFC1533_HOSTNAME) {
			hostname = p + 2;
			hostnamelen = *(p + 1);
		}
		else if (c == RFC1533_VENDOR_MAGIC
			 && TAG_LEN(p) >= 6 &&
			  !memcmp(p+2,vendorext_magic,4) &&
			  p[6] == RFC1533_VENDOR_MAJOR)
		{
			vendorext_isvalid++;
		}
		else if (c >= RFC1533_VENDOR_MOTD &&
			 c < RFC1533_VENDOR_MOTD +
			 RFC1533_VENDOR_NUMOFMOTD)
			motd[c - RFC1533_VENDOR_MOTD] = p;
		else {
//#if 0
			unsigned char *q;
			printf("Unknown RFC1533-tag ");
			for(q=p;q<p+2+TAG_LEN(p);q++)
				printf("%2x ",*q);
			putchar('\n');
//#endif
		}
		p += TAG_LEN(p) + 2;
	}
	extdata = extend = endp;
	if (block == 0 && extpath != NULL) {
		char fname[64];
		memcpy(fname, extpath+2, TAG_LEN(extpath));
		fname[(int)TAG_LEN(extpath)] = '\000';
		printf("Loading BOOTP-extension file: %s\n",fname);
		tftp(fname, decode_rfc1533);
	}
	return (-1);	/* proceed with next block */
}

/**************************************************************************
IPCHKSUM - Checksum IP Header
**************************************************************************/
static unsigned short ipchksum(unsigned short *ip, int len)
{
	unsigned long sum = 0;
	len >>= 1;
	while (len--) {
		sum += *(ip++);
		if (sum > 0xFFFF)
			sum -= 0xFFFF;
	}
	return((~sum) & 0x0000FFFF);
}

/**************************************************************************
RFC951_SLEEP - sleep for expotentially longer times
**************************************************************************/
int rfc951_sleep(int exp)
{
	static long seed = 0;
	long q;
	unsigned long tmo;

#ifdef BACKOFF_LIMIT
	if (exp > BACKOFF_LIMIT)
		exp = BACKOFF_LIMIT;
#endif
	if (!seed) /* Initialize linear congruential generator */
		seed = currticks() + *(long *)&arptable[ARP_CLIENT].node
		       + ((short *)arptable[ARP_CLIENT].node)[2];
	/* simplified version of the LCG given in Bruce Scheier's
	   "Applied Cryptography" */
	q = seed/53668;
	if ((seed = 40014*(seed-53668*q) - 12211*q) < 0) seed += 2147483563l;
	/* compute mask */
	for (tmo = 63; tmo <= 60*TICKS_PER_SEC && --exp > 0; tmo = 2*tmo+1);
	/* sleep */
	printf("<sleep>\n");
	for (tmo = (tmo&seed)+currticks(); currticks() < tmo; )
		if (iskey()) {
			if (getchar() == ESC)
				return 0;
		}
	return 1;
}

/**************************************************************************
CLEANUP - shut down networking and console so that the OS may be called 
**************************************************************************/
void tftp_cleanup(void)
{
	eth_disable();
}

int getdec(char **ptr)
{
	char *p = *ptr;
	int ret=0;
	if ((*p < '0') || (*p > '9')) return(-1);
	while ((*p >= '0') && (*p <= '9')) {
		ret = ret*10 + (*p - '0');
		p++;
	}
	*ptr = p;
	return(ret);
}

int
cmd_tftp(int argc, char *argv[])
{
	twiddling = 1;

	if (tftp_start()) {
	}

	tftp_cleanup();
}


/*
 * Local variables:
 *  c-basic-offset: 8
 * End:
 */

