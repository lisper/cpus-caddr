/* pli_busint.c */

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <fcntl.h>

#ifdef unix
#include <unistd.h>
#endif

#ifdef _WIN32
typedef int off_t;
#endif

#include "vpi_user.h"

#ifdef __CVER__
#include "cv_vpi_user.h"
#endif

#ifdef __MODELSIM__
#include "veriuser.h"
#endif

PLI_INT32 pli_busint(void);
extern void register_my_systfs(void); 
extern void register_my_systfs(void);

char *instnam_tab[10]; 
int last_evh;

static struct state_s {
    vpiHandle busout_aref;

    char *filename;
    int file_inited;
    int disk_fd;
    int disk_byteswap;

    unsigned int disk_cmd;
    unsigned int disk_status;
    unsigned int disk_ma;
    unsigned int disk_da;
    unsigned int disk_ecc;
    unsigned int disk_clp;

    int cyls, heads, blocks_per_track;
    int cur_unit, cur_cyl, cur_head, cur_block;

} state[10];

#define MAX_RAM 1024*256
static unsigned int sdram[MAX_RAM];

static int getadd_inst_id(vpiHandle mhref)
{
    register int i;
    char *chp;
 
    chp = vpi_get_str(vpiFullName, mhref);
    //vpi_printf("getadd_inst_id() %s\n", chp);

    for (i = 1; i <= last_evh; i++) {
        if (strcmp(instnam_tab[i], chp) == 0)
            return(i);
    }

    instnam_tab[++last_evh] = malloc(strlen(chp) + 1);
    strcpy(instnam_tab[last_evh], chp);

    //vpi_printf("getadd_inst_id() done %d\n", last_evh);
    return(last_evh);
} 


static int read_phy_mem(unsigned int addr, unsigned int *pv)
{
    if (addr > MAX_RAM)
        return -1;

    *pv = sdram[addr];
    return 0;
}

static int write_phy_mem(unsigned int addr, unsigned int v)
{
    if (addr > MAX_RAM)
        return -1;

    sdram[addr] = v;
    return 0;
}


static void
_swaplongbytes(unsigned int *buf, int word_count)
{
  /* buf contains bytes from the file. Words in that file were written
   *   as little endian. The macintosh will interpret the word values
   *   as big-endian, however. This routine will swap bytes around so
   *   that the DISK_word values in the array will match what would
   *   have been read on a little-endian machine
   */
  int i;

#define SWAP_LONG(n) (n)
  for (i = 0; i < word_count; i++) {
    buf[i] = SWAP_LONG(buf[i]);
  }
}

/*
 * Disk Structure
 *
 * Each disk block contains one Lisp machine page worth of data,
 * i.e. 256. words or 1024. bytes.
 */
   
static int
_disk_read(struct state_s *s, int block_no, unsigned int *buffer)
{
	off_t offset, ret;
	int size;

	offset = block_no * (256*4);

	vpi_printf("disk: file image block %d(10), offset %ld(10)\n",
                   block_no, (long)offset);

	ret = lseek(s->disk_fd, offset, SEEK_SET);
	if (ret != offset) {
		printf("disk: image file seek error\n");
		perror("lseek");
		return -1;
	}

	size = 256*4;

	ret = read(s->disk_fd, buffer, size);
	if (ret != size) {
		printf("disk read error; ret %d, offset %lu, size %d\n",
		       (int)ret, (long)offset, size);
		perror("read");

		memset((char *)buffer, 0, size);
		return -1;
	}

	/* byte order fixups? */
	if (s->disk_byteswap) {
		_swaplongbytes((unsigned int *)buffer, 256);
	}

	return 0;
}

static int
_disk_write(struct state_s *s, int block_no, unsigned int *buffer)
{
	off_t offset, ret;
	int size;

	offset = block_no * (256*4);

	vpi_printf("disk: file image block %d, offset %ld\n",
                   block_no, (long)offset);

	ret = lseek(s->disk_fd, offset, SEEK_SET);
	if (ret != offset) {
		printf("disk: image file seek error\n");
		perror("lseek");
		return -1;
	}

	size = 256*4;

	/* byte order fixups? */
	if (s->disk_byteswap) {
		_swaplongbytes((unsigned int *)buffer, 256);
	}

	ret = write(s->disk_fd, buffer, size);
	if (ret != size) {
		printf("disk write error; ret %d, offset %lu, size %d\n",
		       (int)ret, (long)offset, size);
		perror("write");
		return -1;
	}

	return 0;
}

static int
disk_read_block(struct state_s *s, unsigned int vma,
                int unit, int cyl, int head, int block)
{
	int block_no, i;
	unsigned int buffer[256];

	block_no =
		(cyl * s->blocks_per_track * s->heads) +
		(head * s->blocks_per_track) + block;

	if (s->disk_fd) {
            _disk_read(s, block_no, buffer);
#if 0
		if (block_no == 10312)
		for (i = 0; i < 32; i++) {
			tracedio("read; vma %011o <- %011o\n",
				 vma + i, buffer[i]);
		}
#endif
		for (i = 0; i < 256; i++) {
			write_phy_mem(vma + i, buffer[i]);
		}
		return 0;
	}

#define LABEL_LABL 	011420440514ULL
#define LABEL_BLANK	020020020020ULL

	/* hack to fake a disk label when no image is present */
	if (unit == 0 && cyl == 0 && head == 0 && block == 0) {
		write_phy_mem(vma + 0, LABEL_LABL); /* label LABL */
		write_phy_mem(vma + 1, 000000000001); /* version = 1 */
		write_phy_mem(vma + 2, 000000001000); /* # cyls */
		write_phy_mem(vma + 3, 000000000004); /* # heads */
		write_phy_mem(vma + 4, 000000000100); /* # blocks */
		write_phy_mem(vma + 5, 000000000400); /* heads*blocks */
		write_phy_mem(vma + 6, 000000001234); /* name of micr part */
		write_phy_mem(vma + 0200, 1); /* # of partitions */
		write_phy_mem(vma + 0201, 1); /* words / partition */

		write_phy_mem(vma + 0202, 01234); /* start of partition info */
		write_phy_mem(vma + 0203, 01000); /* micr address */
		write_phy_mem(vma + 0204, 010);   /* # blocks */
		/* pack text label - offset 020, 32 bytes */
		return 0;
	}

	return -1;
}

static int
disk_write_block(struct state_s *s, unsigned int vma,
                 int unit, int cyl, int head, int block)
{
	int block_no, i;
	unsigned int buffer[256];

	block_no =
		(cyl * s->blocks_per_track * s->heads) +
		(head * s->blocks_per_track) + block;

	if (s->disk_fd) {
		for (i = 0; i < 256; i++) {
			read_phy_mem(vma + i, &buffer[i]);
		}
#if 0
		if (block_no == 1812)
		for (i = 0; i < 32; i++) {
			tracedio("write; vma %011o <- %011o\n",
				 vma + i, buffer[i]);
		}
#endif
		_disk_write(s, block_no, buffer);
		return 0;
	}

	return 0;
}

static int
do_busint_setup(struct state_s *s)
{
	unsigned int label[256];

#ifdef __BIG_ENDIAN__
	disk_set_byteswap(1);
#endif

	printf("disk: opening %s\n", s->filename);

    s->disk_status = 1;

#ifndef O_BINARY
#define O_BINARY 0
#endif

    s->disk_fd = open(s->filename, O_RDWR | O_BINARY);
	if (s->disk_fd < 0) {
		s->disk_fd = 0;
		perror(s->filename);
                return -1;
	}

	_disk_read(s, 0, label);

	if (label[0] != LABEL_LABL) {
		printf("disk: invalid pack label - disk image ignored\n");
		printf("label %o\n", label[0]);
		close(s->disk_fd);
		s->disk_fd = 0;
	}

	s->cyls = label[2];
	s->heads = label[3];
	s->blocks_per_track = label[4];

	printf("disk: image CHB %o/%o/%o\n",
               s->cyls, s->heads, s->blocks_per_track);

	/* hack to find mcr symbol file from disk pack label */
	if (label[030] != 0 && label[030] != LABEL_BLANK) {
		char fn[1024], *s;
		memset(fn, 0, sizeof(fn));
		strcpy(fn, (char *)&label[030]);
#ifdef __BIG_ENDIAN__
		memcpy(fn, (char *)&label[030], 32);
		_swaplongbytes((unsigned int *)fn, 8);
#endif
		printf("disk: pack label comment '%s'\n", fn);
		s = strstr(fn, ".mcr.");
		if (s)
			memcpy(s, ".sym.", 5);
		//config_set_mcrsym_filename(fn);
	}

	return 0;
}

static void disk_set_cmd(struct state_s *s, unsigned int v)
{
    s->disk_cmd = v;

//    if ((s->disk_cmd & 06000) == 0)
//        deassert_xbus_interrupt();
}

static void disk_set_clp(struct state_s *s, unsigned int v)
{
    s->disk_clp = v;
}

static void disk_set_da(struct state_s *s, unsigned int v)
{
    s->disk_da = v;
}

void
disk_show_cur_addr(struct state_s *s)
{
    vpi_printf("disk: unit %d, CHB %o/%o/%o\n",
	       s->cur_unit, s->cur_cyl, s->cur_head, s->cur_block);
}

void
disk_decode_addr(struct state_s *s)
{
    s->cur_unit = (s->disk_da >> 28) & 07;
    s->cur_cyl = (s->disk_da >> 16) & 07777;
    s->cur_head = (s->disk_da >> 8) & 0377;
    s->cur_block = s->disk_da & 0377;
}

void
disk_undecode_addr(struct state_s *s)
{
    s->disk_da =
        ((s->cur_unit & 07) << 28) |
        ((s->cur_cyl & 07777) << 16) |
        ((s->cur_head & 0377) << 8) |
        ((s->cur_block & 0377));
}

void
disk_incr_block(struct state_s *s)
{
    s->cur_block++;
    if (s->cur_block >= s->blocks_per_track) {
        s->cur_block = 0;
        s->cur_head++;
		if (s->cur_head >= s->heads) {
                    s->cur_head = 0;
                    s->cur_cyl++;
		}
	}
}

static void
disk_throw_interrupt(struct state_s *s)
{
    //tracedio("disk: throw interrupt\n");
    s->disk_status |= 1<<3;
    //assert_xbus_interrupt();
}

static void
disk_future_interrupt(struct state_s *s)
{
}


void
disk_start_read(struct state_s *s)
{
	unsigned int ccw;
	unsigned int vma;
	int i;

	disk_decode_addr(s);

	/* process ccw's */
	for (i = 0; i < 65535; i++) {
		int f;

		f = read_phy_mem(s->disk_clp, &ccw);
		if (f) {
			printf("disk: mem[clp=%o] yielded fault (no page)\n",
			       s->disk_clp);

			/* huh.  what to do now? */
			return;
		}

		vpi_printf("disk: mem[clp=%o] -> ccw %08o\n", s->disk_clp, ccw);

		vma = ccw & ~0377;
		s->disk_ma = vma;

		disk_show_cur_addr(s);
		disk_read_block(s, vma,
                                s->cur_unit, s->cur_cyl, s->cur_head, 
                                s->cur_block);

		if ((ccw & 1) == 0) {
                    vpi_printf("disk: last ccw\n");
                    break;
		}

		disk_incr_block(s);

		s->disk_clp++;
	}

	disk_undecode_addr(s);

	if (s->disk_cmd & 04000) {
#if 0
		disk_throw_interrupt(s);
#else
		disk_future_interrupt(s);
#endif
	}
}

void
disk_start_read_compare(struct state_s *s)
{
	disk_decode_addr(s);
	disk_show_cur_addr(s);
}

void
disk_start_write(struct state_s *s)
{
#ifndef ALLOW_DISK_WRITE
	disk_decode_addr(s);
	disk_show_cur_addr(s);
#else
	unsigned int ccw;
	unsigned int vma;
	int i;

	disk_decode_addr(s);

	/* process ccw's */
	for (i = 0; i < 65535; i++) {
		int f;

		f = read_phy_mem(disk_clp, &ccw);
		if (f) {
			printf("disk: mem[clp=%o] yielded fault (no page)\n",
			       disk_clp);

			/* huh.  what to do now? */
			return;
		}

		tracedio("disk: mem[clp=%o] -> ccw %08o\n", disk_clp, ccw);

		vma = ccw & ~0377;
		disk_ma = vma;

		disk_show_cur_addr(s);

		disk_write_block(vma, cur_unit, cur_cyl, cur_head, cur_block);

//		disk_incr_block();
			
		if ((ccw & 1) == 0) {
			tracedio("disk: last ccw\n");
			break;
		}

                disk_incr_block(s);

                s->disk_clp++;
	}

	disk_undecode_addr(s);

	if (disk_cmd & 04000) {
#ifdef DELAY_DISK_INTERRUPT
		disk_future_interrupt(s);
#else
		disk_throw_interrupt(s);
#endif
	}
#endif
}

static void disk_start(struct state_s *s)
{
    switch (s->disk_cmd & 01777) {
    case 0:
        disk_start_read(s);
        break;
    case 010:
        disk_start_read_compare(s);
        break;
    case 011:
        disk_start_write(s);
        break;
    case 01005:
        vpi_printf("recalibrate\n");
        break;
    case 0405:
        vpi_printf("fault clear\n");
        break;
    default:
        vpi_printf("unknown\n");
        break;
    }
}

/*
 *
 */
PLI_INT32 pli_busint(void)
{
    vpiHandle href, iter, mhref;
    vpiHandle wrref, addrref, businref, busoutref;
    struct state_s *s;

    int numargs, inst_id;

    s_vpi_value tmpval, outval;

    char wr_bit, addr_bits[128], busin_bits[128];
    unsigned int addr, busin, busout;

    //vpi_printf("pli_busint:\n");

    href = vpi_handle(vpiSysTfCall, NULL); 
    if (href == NULL) {
        vpi_printf("** ERR: $pli_busint PLI 2.0 can't get systf call handle\n");
        return(0);
    }

    mhref = vpi_handle(vpiScope, href);

    if (vpi_get(vpiType, mhref) != vpiModule)
        mhref = vpi_handle(vpiModule, mhref); 

    inst_id = getadd_inst_id(mhref);

    s = &state[inst_id];

    if (!s->file_inited) {
        s->file_inited = 1;
        s->filename = "pli.dsk";
        do_busint_setup(s);
    }

    iter = vpi_iterate(vpiArgument, href);

    numargs = vpi_get(vpiSize, iter);

    /* wr, addr, busin, busout */
    wrref = vpi_scan(iter);
    addrref = vpi_scan(iter);
    businref = vpi_scan(iter);
    busoutref = vpi_scan(iter);

    if (wrref == NULL || addrref == NULL ||
        businref == NULL || busoutref == NULL)
    {
        vpi_printf("**ERR: $pli_busint bad args\n");
        return(0);
    }

    tmpval.format = vpiBinStrVal; 
    vpi_get_value(wrref, &tmpval);
    wr_bit =  tmpval.value.str[0];

    tmpval.format = vpiBinStrVal; 
    vpi_get_value(addrref, &tmpval);
    strcpy(addr_bits, tmpval.value.str);

    tmpval.format = vpiIntVal; 
    vpi_get_value(addrref, &tmpval);
    addr = tmpval.value.integer;

    tmpval.format = vpiBinStrVal; 
    vpi_get_value(businref, &tmpval);
    strcpy(busin_bits, tmpval.value.str);

    tmpval.format = vpiIntVal; 
    vpi_get_value(businref, &tmpval);
    busin = tmpval.value.integer;

    vpi_free_object(iter);
    vpi_free_object(href);

    vpi_printf("pli_busint: wr %c, addr %08x bus %08x\n", wr_bit, addr, busin);

    /* */
    if (wr_bit == '0') {
        if (0) vpi_printf("pli_busint: write @ %08x %08x\n", addr, busin);

        if (addr < MAX_RAM)
            sdram[addr] = busin;
        else
            switch (addr) {
            case 0x3dfff8:
                break;
            case 0x3dfffc:
                disk_set_cmd(s, busin);
                break;
            case 0x3dfffd:
                disk_set_clp(s, busin);
                break;
            case 0x3dfffe:
                disk_set_da(s, busin);
                break;
            case 0x3dffff:
                disk_start(s);
                break;
            }
    }

    if (wr_bit == '1') {
        if (0) vpi_printf("pli_busint: read @ %08x\n", addr);

        busout = 0xffffffff;

        if (addr < MAX_RAM)
            busout = sdram[addr];
        else
            switch (addr) {
            case 0x3dff00:
                break;
            case 0x3ff605:
                break;

            case 0x3dfff8: /* disk status */
                busout = s->disk_status;
                break;
            case 0x3dfff9:
                busout = s->disk_ma;
                break;
            case 0x3dfffa:
                busout = s->disk_da;
                break;
            case 0x3dfffb:
                busout = s->disk_ecc;
                break;
            case 0x3dfffc: /* disk status */
                busout = s->disk_status;
                break;
            case 0x3dfffd:
                busout = s->disk_clp;
                break;
            case 0x3dfffe:
                busout = s->disk_da;
                break;
            case 0x3dffff:
                busout = 0;
                break;
            }

#ifdef __CVER__
        if (s->busout_aref == 0)
            s->busout_aref = vpi_put_value(busoutref, NULL, NULL, vpiAddDriver);
#else
        s->bus_aref = busoutref;
#endif

        outval.format = vpiIntVal;
        outval.value.integer = busout;
        vpi_put_value(s->busout_aref, &outval, NULL, vpiNoDelay);
    }

//    if (wr_bit == 0) {
//        outval.format = vpiBinStrVal;
//        outval.value.str = "zzzzzzzzzzzzzzzz";
//        if (s->busout_aref)
//            vpi_put_value(s->busout_aref, &outval, NULL, vpiNoDelay);
//    }

    vpi_free_object(wrref);
    vpi_free_object(addrref);
    vpi_free_object(businref);
    vpi_free_object(busoutref);

    return(0);
}

/*
 * register all vpi_ PLI 2.0 style user system tasks and functions
 */
void register_my_systfs(void)
{
    p_vpi_systf_data systf_data_p;

    /* use predefined table form - could fill systf_data_list dynamically */
    static s_vpi_systf_data systf_data_list[] = {
        { vpiSysTask, 0, "$pli_busint", pli_busint, NULL, NULL, NULL },
        { 0, 0, NULL, NULL, NULL, NULL, NULL }
    };

    systf_data_p = &(systf_data_list[0]);
    while (systf_data_p->type != 0) vpi_register_systf(systf_data_p++);
}

#ifdef __CVER__
static void (*busint_vlog_startup_routines[]) () =
{
 register_my_systfs, 
 0
};

/* dummy +loadvpi= boostrap routine - mimics old style exec all routines */
/* in standard PLI vlog_startup_routines table */
void busint_vpi_compat_bootstrap(void)
{
    int i;

    for (i = 0;; i++) 
    {
        if (busint_vlog_startup_routines[i] == NULL) break; 
        busint_vlog_startup_routines[i]();
    }
}

void vpi_compat_bootstrap(void)
{
    busint_vpi_compat_bootstrap();
}

void __stack_chk_fail_local(void) {}
#endif

#ifdef __MODELSIM__
static void (*vlog_startup_routines[]) () =
{
 register_my_systfs, 
 0
};
#endif


/*
 * Local Variables:
 * indent-tabs-mode:nil
 * c-basic-offset:4
 * End:
*/
