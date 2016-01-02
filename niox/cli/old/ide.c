/*
 * ide.c
 *
 * $Id: ide.c,v 1.3 2005/03/10 14:07:05 brad Exp $
 */

#include "types.h"
#include "diag.h"

#include "ide.h"

static int verbose = 1;
void *slot_base;
extern void *slot_attrib_base;
extern int boot_slot;

unsigned int disk_sectors_per_track;
unsigned int disk_heads;

#if 0
typedef volatile u8 ide_port_t;
#define PORT(n)		port[n]
#else
typedef volatile u32 ide_port_t;
static char ide_addr_swizzle[8] = { 0, 4, 2, 6, 1, 5, 3, 7 };
#define PORT(n)		port[ide_addr_swizzle[n]]
#endif

int
hd_busy_wait(ide_port_t *port)
{
  int count;
  u8 status, err;

#if 0
  printf("hd_busy_wait() status %8x\n", PORT(7) & 0x00ff);
#endif

  count = 0;
  while (count++ < 2500) {
    status = PORT(7) & 0x00ff;
    if ((status & BUSY) == 0)
      break;
    delayus();
  }

#if 0
  printf("busy_wait: count %d\n", count);
  printf("status %x\n", status);
#endif

  if (status & 0x01) {
    err = PORT(1) & 0x00ff;
    printf("err reg %2x\n", err);
    return -1;
  }

  return 0;
}

int
hd_recal(ide_port_t *port)
{
      int i, hd_drive, hd_head, sector;
      u8 status, hd_cmd[8];

      hd_drive = 0;
      sector = 0;
      hd_head = sector & 0xffff;

      hd_cmd[1] = 0;
      hd_cmd[2] = 1;			/* # sectors */
      hd_cmd[3] = 0;
      hd_cmd[4] = 0;
      hd_cmd[5] = 0;
      hd_cmd[6] = (hd_drive << 4) | (hd_head & 0x0f) | 0xa0;

      hd_busy_wait(port);

      for (i = 1; i < 7; i++) {
	hd_busy_wait(port);
	PORT(i) = hd_cmd[i];
      }

      PORT(7) = HDC_RECAL;

      if (hd_busy_wait(port))
	  return -1;

      return 0;
}

int
hd_identify(ide_port_t *port, ide_port_t *reg, char *buffer)
{
      int i;
      unsigned char status;

volatile u_char *pp1 = 0x60000000;
volatile u_char *pp2= 0x70000000;
volatile u_char b;
      hd_busy_wait(port);

b = pp1[0];
      PORT(1) = 0;
b = pp1[0];
      PORT(2) = 1;
b = pp1[0];
      PORT(3) = 0;
b = pp1[0];
      PORT(4) = 0;
b = pp1[0];
      PORT(5) = 0;
b = pp1[0];
      PORT(6) = 0xa0;
b = pp1[0];
      PORT(7) = HDC_IDENTIFY;
b = pp1[0];

      hd_busy_wait(port);

#if 0
      for (i = 0; i < 512; i++) {
	buffer[i] = PORT(0);
      }
#else
      for (i = 0; i < 512; i += 2) {
	      u16 p;
b = pp1[0];
	      p = PORT(0);
	      buffer[i] = p & 0xff;
	      buffer[i+1] = p >> 8;
b = pp2[0];
      }
#endif

      status = PORT(7) & 0x00ff;

#if 1
      printf("status %8x\n", status);
#endif

      if (status & ERROR) {
	  printf("identify status: %2x\n", status);
	  return -1;
      }

#if 1
      dumpmem(buffer, 128/*512*/);
#endif

      return 0;
}

int 
hd_read(ide_port_t *port, ide_port_t *reg,
	int head, int sector, int cyl, char *buffer)
{
      int i, hd_drive, hd_cyl, hd_head, hd_sector;
      u8 status, hd_cmd[8];

      hd_drive = 0;
      hd_cyl = cyl;
      hd_head = head;
      hd_sector = sector;

      hd_cmd[1] = 0;
      hd_cmd[2] = 1;			/* # sectors */
      hd_cmd[3] = hd_sector;		/* starting sector */
      hd_cmd[4] = cyl & 0xff;		/* cylinder low byte */
      hd_cmd[5] = (cyl >> 8) & 0xff;	/* cylinder hi byte */
      hd_cmd[6] = (hd_drive << 4) | (hd_head & 0x0f) | 0xa0;

      if (verbose > 2)
	  printf("hd_read() h=%d s=%d c=%d\n", hd_head, hd_sector, hd_cyl);

#if 0
      if (hd_head > 7) {
	//	hd_control |= 0x08;
	//	reg[0] = hd_control;
	//	hd_control &= 0xf7;
		reg[0] = 0x08;
      }
#endif

      /* --- */
      hd_busy_wait(port);

      for (i = 1; i < 7; i++) {
	hd_busy_wait(port);
	PORT(i) = hd_cmd[i];
      }

      PORT(7) = HDC_READ;

      hd_busy_wait(port);

#if 0
      for (i = 0; i < 512; i++) {
	buffer[i] = PORT(0);
      }
#endif

#if 0
      for (i = 0; i < 512; i += 2) {
	      u16 p;
	      p = PORT(0);
	      buffer[i] = p & 0xff;
	      buffer[i+1] = p >> 8;
      }
#endif

#if 1
      for (i = 0; i < 512; i += 2) {
	      u16 p1, p2, p3, p4;

	      p1 = PORT(0);
	      p2 = PORT(0);
	      p3 = PORT(0);
	      p4 = PORT(0);

	      buffer[i+0] = p1 & 0xff;
	      buffer[i+1] = p1 >> 8;

	      buffer[i+2] = p2 & 0xff;
	      buffer[i+3] = p2 >> 8;

	      buffer[i+4] = p3 & 0xff;
	      buffer[i+5] = p3 >> 8;

	      buffer[i+6] = p4 & 0xff;
	      buffer[i+7] = p4 >> 8;
      }
#endif

      status = PORT(7);

      if (status & ERROR) {
	  printf("read status: %2x\n", status);

	  printf("c=%d h=%d s=%d\n", hd_cyl, hd_head, hd_sector);
	  for (i = 1; i < 7; i++) {
	    printf("set reg[%d] %2x\n", i, hd_cmd[i]);
	  }
      }

      if (status & ERROR)
	  return -1;

      return 0;
}

/* read, mapping abs [0..max] sector # into head, sector, cylinder */
int 
hd_read_mapped(int sector_num, char *buffer)
{
    int head, sector, cyl;
    ide_port_t *port = (ide_port_t *)(slot_base + HD_PORT);
    ide_port_t *reg = (ide_port_t *)(slot_base + HD_REG_PORT);

    if (verbose > 2)
	printf("hd_read_mapped(sector_num=%d, buffer=%x)\n",
	       sector_num, buffer);

    sector = (sector_num % disk_sectors_per_track) + 1;
    sector_num /= disk_sectors_per_track;

    head = sector_num % disk_heads;
    sector_num /= disk_heads;

    cyl = sector_num;

    return hd_read(port, reg, head, sector, cyl, buffer);
}

/* structure returned by HDIO_GET_IDENTITY, as per ANSI ATA2 rev.2f spec */
struct hd_driveid {
	unsigned short	config;		/* lots of obsolete bit flags */
	unsigned short	cyls;		/* "physical" cyls */
	unsigned short	reserved2;	/* reserved (word 2) */
	unsigned short	heads;		/* "physical" heads */
	unsigned short	track_bytes;	/* unformatted bytes per track */
	unsigned short	sector_bytes;	/* unformatted bytes per sector */
	unsigned short	sectors;	/* "physical" sectors per track */
	unsigned short	vendor0;	/* vendor unique */
	unsigned short	vendor1;	/* vendor unique */
	unsigned short	vendor2;	/* vendor unique */
	unsigned char	serial_no[20];	/* 0 = not_specified */
	unsigned short	buf_type;
	unsigned short	buf_size;	/* 512 byte increments; 0 = not_specified */
	unsigned short	ecc_bytes;	/* for r/w long cmds; 0 = not_specified */
	unsigned char	fw_rev[8];	/* 0 = not_specified */
	unsigned char	model[40];	/* 0 = not_specified */
	unsigned char	max_multsect;	/* 0=not_implemented */
	unsigned char	vendor3;	/* vendor unique */
	unsigned short	dword_io;	/* 0=not_implemented; 1=implemented */
	unsigned char	vendor4;	/* vendor unique */
	unsigned char	capability;	/* bits 0:DMA 1:LBA 2:IORDYsw 3:IORDYsup*/
	unsigned short	reserved50;	/* reserved (word 50) */
	unsigned char	vendor5;	/* vendor unique */
	unsigned char	tPIO;		/* 0=slow, 1=medium, 2=fast */
	unsigned char	vendor6;	/* vendor unique */
	unsigned char	tDMA;		/* 0=slow, 1=medium, 2=fast */
	unsigned short	field_valid;	/* bits 0:cur_ok 1:eide_ok */
	unsigned short	cur_cyls;	/* logical cylinders */
	unsigned short	cur_heads;	/* logical heads */
	unsigned short	cur_sectors;	/* logical sectors per track */
	unsigned short	cur_capacity0;	/* logical total sectors on drive */
	unsigned short	cur_capacity1;	/*  (2 words, misaligned int)     */
	unsigned char	multsect;	/* current multiple sector count */
	unsigned char	multsect_valid;	/* when (bit0==1) multsect is ok */
	unsigned int	lba_capacity;	/* total number of sectors */
	unsigned short	dma_1word;	/* single-word dma info */
	unsigned short	dma_mword;	/* multiple-word dma info */
	unsigned short  eide_pio_modes; /* bits 0:mode3 1:mode4 */
	unsigned short  eide_dma_min;	/* min mword dma cycle time (ns) */
	unsigned short  eide_dma_time;	/* recommended mword dma cycle time (ns) */
	unsigned short  eide_pio;       /* min cycle time (ns), no IORDY  */
	unsigned short  eide_pio_iordy; /* min cycle time (ns), with IORDY */
	unsigned short	words69_70[2];	/* reserved words 69-70 */
	/* HDIO_GET_IDENTITY currently returns only words 0 through 70 */
	unsigned short	words71_74[4];	/* reserved words 71-74 */
	unsigned short  queue_depth;	/*  */
	unsigned short  words76_79[4];	/* reserved words 76-79 */
	unsigned short  major_rev_num;	/*  */
	unsigned short  minor_rev_num;	/*  */
	unsigned short  command_set_1;	/* bits 0:Smart 1:Security 2:Removable 3:PM */
	unsigned short  command_set_2;	/* bits 14:Smart Enabled 13:0 zero */
	unsigned short  cfsse;		/* command set-feature supported extensions */
	unsigned short  cfs_enable_1;	/* command set-feature enabled */
	unsigned short  cfs_enable_2;	/* command set-feature enabled */
	unsigned short  csf_default;	/* command set-feature default */
	unsigned short  dma_ultra;	/*  */
	unsigned short	word89;		/* reserved (word 89) */
	unsigned short	word90;		/* reserved (word 90) */
	unsigned short	CurAPMvalues;	/* current APM values */
	unsigned short	word92;		/* reserved (word 92) */
	unsigned short	hw_config;	/* hardware config */
	unsigned short  words94_125[32];/* reserved words 94-125 */
	unsigned short	last_lun;	/* reserved (word 126) */
	unsigned short	word127;	/* reserved (word 127) */
	unsigned short	dlf;		/* device lock function
					 * 15:9	reserved
					 * 8	security level 1:max 0:high
					 * 7:6	reserved
					 * 5	enhanced erase
					 * 4	expire
					 * 3	frozen
					 * 2	locked
					 * 1	en/disabled
					 * 0	capability
					 */
	unsigned short  csfo;		/* current set features options
					 * 15:4	reserved
					 * 3	auto reassign
					 * 2	reverting
					 * 1	read-look-ahead
					 * 0	write cache
					 */
	unsigned short	words130_155[26];/* reserved vendor words 130-155 */
	unsigned short	word156;
	unsigned short	words157_159[3];/* reserved vendor words 157-159 */
	unsigned short	words160_255[95];/* reserved words 160-255 */
};

char id_buffer[512];

void ide_fixstring (u8 *s, const int bytecount, const int byteswap)
{
	u8 *p = s, *end = &s[bytecount & ~1]; /* bytecount must be even */

	if (byteswap) {
		/* convert from big-endian to host byte order */
		for (p = end ; p != s;) {
			unsigned short *pp = (unsigned short *) (p -= 2);
//			*pp = ntohs(*pp);
			*pp = ((*pp >> 8) & 0xff) | ((*pp & 0xff) << 8);
		}
	}

	/* strip leading blanks */
	while (s != end && *s == ' ')
		++s;

	/* compress internal blanks and strip trailing blanks */
	while (s != end && *s) {
		if (*s++ != ' ' || (s != end && *s && *s != ' '))
			*p++ = *(s-1);
	}

	/* wipe out trailing garbage */
	while (p != end)
		*p++ = '\0';
}

/* do an "ide indentify" command to the ATA drive to get it's geometry */
int
ide_identify_drive()
{
    ide_port_t *port = (ide_port_t *)(slot_base + HD_PORT);
    ide_port_t *reg = (ide_port_t *)(slot_base + HD_REG_PORT);
    struct hd_driveid *id;

    printf("port %8x, reg %8x\n", port, reg);

    memset(id_buffer, 0, sizeof(id_buffer));

    if (hd_identify(port, reg, id_buffer)) {
      return -1;
    }

    id = (struct hd_driveid *)id_buffer;

    ide_fixstring (id->model, sizeof(id->model), 1);

    printf("model: %s\n", id->model);
    printf("CHS:   %d/%d/%d\n", id->cyls, id->heads, id->sectors);

    if (id->sectors && id->heads) {
      disk_sectors_per_track = id->sectors;
      disk_heads = id->heads;
    }


    return 0;
}

int
ide_test_read(void)
{
    if (disk_sectors_per_track && disk_heads) {
	    int s, ret;
	    for (s = 0; s < 1024; s++) {
		    printf("%d   \r", s);
		    ret = hd_read_mapped(s, id_buffer);
		    if (ret) printf("read block %d failed\n", s);
	    }
    }

    return 0;
}


int
ide_show_regs(void)
{
    ide_port_t *port = (ide_port_t *)(slot_base + HD_PORT);
    ide_port_t *reg = (ide_port_t *)(slot_base + HD_REG_PORT);
    int i;

    printf("slot_base %8x, port %8x, reg %8x\n", slot_base, port, reg);

    printf("ide ports:\n");
    for (i = 0; i < 8; i++) {
	    u_char pv;
	    pv = PORT(i);
pv = 0x01;
	    printf("[%d] = %2x\n", i, pv);
    }

    return 0;
}

