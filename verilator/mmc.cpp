#include "svdpi.h"
#include "Vtest__Dpi.h"

#include <stdio.h>

#ifdef __cplusplus
extern "C" {
#endif

/* dpi_mmc.c */
/*
 * simple MMC card SPI emulation
 */

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

typedef unsigned char u8;

static char *instnam_tab[10]; 
//int last_evh;

static int last_sclk_bit;
static int last_cs_bit;

static int debug;

static struct state_s {
    unsigned short status;
    unsigned long long cmd_reg;
    int cmd_bits;
    int unselected_count;
    int mode;
    int initializing;
    int initializing_count;
    int do_state;
    int blksize;
    int cs_deassert_wait;

    u8 resp[4];
    int resp_delay;
    int resp_size;
    int resp_bit;
    int resp_index;

    int fifo_rd;
    int fifo_wr;
    int fifo_depth;
    u8 fifo[512 * 128];

    int file_inited;
    int file_fd;

    unsigned int lba;
} state[10];

enum {
    M_POWERUP = -1,
    M_IDLE = 0,
    M_CMD = 1,
    M_CMD_RESP = 2,
    M_READ_RESP = 3,
    M_READ = 4,
    M_WRITE_RESP = 5,
    M_WRITE = 6
};

#define R1_IDLE			0x01
#define R1_ERASE_RESET		0x02
#define R1_ILLEGAL_CMD		0x04
#define R1_CMD_CRC_ERR		0x08
#define R1_ERASE_SEQ_ERR	0x10
#define R1_ADDR_ERR		0x20
#define R1_PARM_ERR		0x40

void mmc_set_mode(struct state_s *s, int mode);

static void
do_mmc_setup(struct state_s *s)
{
    char *dif, disk_image_filename[1024];

    /* allow default name to be overridden */
    strcpy(disk_image_filename, "mmc.img");
    if ((dif = getenv("MMCIMAGE"))) {
        strncpy(disk_image_filename, dif, sizeof(disk_image_filename));
    }

    printf("dpi_mmc: using disk image '%s'\n", disk_image_filename);

    s->file_fd = open(disk_image_filename, O_RDWR);
    if (s->file_fd < 0)
        perror(disk_image_filename);

    s->status = 0;
    s->mode = M_POWERUP;
    s->blksize = 256;
    s->fifo_depth = 0;
    s->fifo_rd = 0;
    s->fifo_wr = 0;

    s->do_state = 0;
}

static void
do_mmc_read(struct state_s *s)
{
    int ret;

    printf("dpi_mmc: %d (lba %d) (read)\n",
               s->lba*s->blksize, s->lba);

    ret = lseek(s->file_fd, (off_t)s->lba*s->blksize, SEEK_SET);
    ret = read(s->file_fd, (char *)s->fifo, s->blksize);
    if (ret < 0)
        perror("read");

    printf("dpi_mmc: buffer %03o %03o %03o %03o (%02x %02x %02x %02x)\n",
               s->fifo[0], s->fifo[1], s->fifo[2], s->fifo[3],
               s->fifo[0], s->fifo[1], s->fifo[2], s->fifo[3]);

    s->fifo_depth = s->blksize;
    s->fifo_rd = 0;
    s->fifo_wr = 0;

    s->status = 1;

    /* crc */
    s->fifo[s->fifo_depth++] = 0;
    s->fifo[s->fifo_depth++] = 0;
}

static void
do_mmc_write(struct state_s *s)
{
    if (debug) printf("dpi_mmc: %d (lba %d) (write)\n",
                      s->lba*s->blksize, s->lba);

    printf("dpi_mmc: write prep\n");

    s->fifo_depth = s->blksize;
    s->fifo_rd = 0;
    s->fifo_wr = 0;

    s->status = 1;
}

static void
do_mmc_write_done(struct state_s *s)
{
    int ret;

    printf("dpi_mmc: %d (lba %d), (write done)\n",
               s->lba*s->blksize, s->lba);

    ret = lseek(s->file_fd, (off_t)s->lba*s->blksize, SEEK_SET);
    ret = write(s->file_fd, (char *)s->fifo, s->blksize);
    if (ret < 0)
        perror("write");

    s->cmd_reg = 0;
    s->status = 1;
}

void mmc_resp(struct state_s *s, int len, char *resp, int delay)
{
    int i;
    s->resp_size = len;
    s->resp_index = 0;
    s->resp_bit = 0;
    for (i = 0; i < len; i++)
        s->resp[i] = resp[i];
    s->resp_delay = delay;

    if (debug) printf("dpi_mmc: queue resp; size %d, delay %d\n", len, delay);
}

void mmc_resp_r1(struct state_s *s, char r1, int delay)
{
    char r[1];
    r[0] = r1;
    mmc_resp(s, 1, r, delay);
}

void mmc_read_fifo(struct state_s *s)
{
    char d[1];
    if (debug || 1) printf("dpi_mmc: data[%d] -> %o (0x%02x)\n", s->fifo_rd, s->fifo[s->fifo_rd], s->fifo[s->fifo_rd]);
    d[0] = s->fifo[s->fifo_rd];
    s->fifo_rd++;
    if (s->fifo_rd == s->fifo_depth) {
//        do_mmc_read_done(s);
        mmc_set_mode(s, M_CMD);
    }

    mmc_resp(s, 1, d, 0);
}

void mmc_write_fifo(struct state_s *s)
{
    if (debug) printf("dpi_mmc: data[%d] <- 0x%08x\n", s->fifo_wr, (unsigned int)(s->cmd_reg & 0xff));
    s->fifo[s->fifo_wr] = s->cmd_reg & 0xff;
    s->fifo_wr++;
    if (s->fifo_wr == s->fifo_depth) {
        do_mmc_write_done(s);
        mmc_set_mode(s, M_CMD);
    }
}


char *mmc_mode_name(int mode)
{
    switch (mode) {
    case M_POWERUP: return (char *)"M_POWERUP"; break;
    case M_IDLE: return (char *)"M_IDLE"; break;
    case M_CMD: return (char *)"M_CMD"; break;
    case M_CMD_RESP: return (char *)"M_CMD_RESP"; break;
    case M_READ_RESP: return (char *)"M_READ_RESP"; break;
    case M_READ: return (char *)"M_READ"; break;
    case M_WRITE_RESP: return (char *)"M_WRITE_RESP"; break;
    case M_WRITE: return (char *)"M_WRITE"; break;
    default: return (char *)"???"; break;
    }
}

void mmc_set_mode(struct state_s *s, int mode)
{
    if (debug) printf("pli_mmc: mode %s->%s\n", mmc_mode_name(s->mode), mmc_mode_name(mode));
    s->mode = mode;
}

int mmc_responding(struct state_s *s)
{
    if (s->mode == M_CMD_RESP || s->mode == M_READ_RESP || s->mode == M_WRITE_RESP)
        return 1;

    if (s->mode == M_READ)
        return 1;

    return 0;
}

/*
 *
 */
void dpi_mmc(int m_di, int* m_do, int m_cs, int m_sclk)
{
    struct state_s *s;

    int inst_id;
    char do_bit, sclk_bit, di_bit, cs_bit;

    int sclk_pos_edge, sclk_neg_edge, cs_edge, cs_asserted;
    int di_asserted, do_asserted;

    if (0) printf("dpi_mmc: entry\n");
    if (0) printf("dpi_mmc(m_di=%x, m_cs=%x m_sclk=%x)\n", m_di, m_cs, m_sclk);

    inst_id = 0;
    debug = 1;

    //printf("dpi_mmc: inst_id %d\n", inst_id);
    s = &state[inst_id];

    if (!s->file_inited) {
        s->file_inited = 1;
        do_mmc_setup(s);
    }

    do_bit = *m_do & 1;
    sclk_bit = m_sclk & 1;
    di_bit = m_di & 1;
    cs_bit = m_cs & 1;

    /* sclk */
    sclk_pos_edge = 0;
    sclk_neg_edge = 0;
    if (sclk_bit != last_sclk_bit) {
        if (sclk_bit == 1) sclk_pos_edge = 1;
        if (sclk_bit == 0) sclk_neg_edge = 1;
    }
    last_sclk_bit = sclk_bit;

    if (debug > 1 && (sclk_pos_edge || sclk_neg_edge))
	    printf("dpi_mmc: sclk_bit %d, sclk_edge %c\n",
		   sclk_bit, sclk_pos_edge ? '+' : (sclk_neg_edge ? '-' : ' '));

    /* chip select (negative polarity) */
    if (cs_bit == 1) cs_asserted = 0;
    if (cs_bit == 0) cs_asserted = 1;

    cs_edge = 0;
    if (cs_bit != last_cs_bit) {
        /*if (cs_bit == 1)*/ cs_edge = 1;
    }
    last_cs_bit = cs_bit;

    /* data in */
    if (di_bit == 0) di_asserted = 0;
    if (di_bit == 1) di_asserted = 1;

    if (debug > 1) {
        if (sclk_pos_edge) printf("dpi_mmc: sclk pos edge, di %d\n", di_asserted);
        if (sclk_neg_edge) printf("dpi_mmc: sclk neg edge, di %d\n", di_asserted);
	if (cs_edge && cs_asserted != 0) printf("dpi_mmc: cs asserted\n");
	if (cs_edge && cs_asserted == 0) printf("dpi_mmc: cs deasserted\n");
    }

    if (cs_edge && cs_asserted) {
        s->cmd_reg = 0;
        s->cmd_bits = 0;
        s->resp_bit = 0;
    }

    if (cs_edge && !cs_asserted) {
        s->do_state = 0;
        s->cs_deassert_wait = 0;
    }

    if (s->cs_deassert_wait)
        goto done;

    if (cs_asserted && (sclk_pos_edge == 0 && sclk_neg_edge == 0)) {
        if ((s->mode == M_READ_RESP || s->mode == M_WRITE_RESP) && s->resp_delay)
            s->do_state = 1;
    }

    if (sclk_pos_edge && cs_asserted) {
        s->unselected_count = 0;
        s->cmd_reg <<= 1;
        s->cmd_reg |= di_asserted ? 1 : 0;
        s->cmd_bits++;

#define CMD0	0x40
#define CMD1	0x41
#define CMD16	0x50
#define CMD17	0x51
#define CMD24	0x58

        if (debug > 1 && s->mode == M_CMD)
            printf("dpi_mmc: mode%d bits %d reg %12llx\n", s->mode, s->cmd_bits, s->cmd_reg);

        switch (s->mode) {
        case M_READ_RESP:
        case M_WRITE_RESP:
            if (s->cmd_bits == 8) {
                if (s->resp_delay > 0) {
                    s->resp_delay--;
                    if (debug) printf("dpi_mmc: resp_delay %d\n", s->resp_delay);
                    if (s->resp_delay == 0)
                        s->cs_deassert_wait = 1;
                } else {
                    if (s->mode == M_READ_RESP) {
                        mmc_set_mode(s, M_READ);
                        mmc_read_fifo(s);
                        s->cs_deassert_wait = 1;
                    }
                    if (s->mode == M_WRITE_RESP) {
                        mmc_set_mode(s, M_WRITE);
                    }
                }
                s->cmd_bits = 0;
            }
            break;

        case M_READ:
            if (s->resp_size == 0) {
                mmc_read_fifo(s);
                s->cs_deassert_wait = 1;
            }
            break;


        case M_WRITE:
            if (s->cmd_bits == 8) {
                mmc_write_fifo(s);
            }
            break;

        case M_IDLE:
        case M_CMD:
            // In idle state, the card accepts only CMD0, CMD1, ACMD41,CMD58 and CMD59
            if (s->cmd_bits == 48) {
                u8 parity = s->cmd_reg & 0xff;
                u8 cmd = (s->cmd_reg >> 40) & 0xff;

                if (debug) printf("dpi_mmc: cmd %02x %llx\n", cmd, s->cmd_reg);

                switch (cmd) {
                case CMD0:// cmd0
                    if (parity == 0x95) {
                        if (debug) printf("dpi_mmc: CMD0\n");
                        if (cs_asserted)
//                            mmc_set_mode(s, M_CMD);
                        mmc_set_mode(s, M_CMD_RESP);
                        s->initializing = 0;
                        mmc_resp_r1(s, R1_IDLE, 0);
                    }
                    break;
                case CMD1:// cmd1
                    if (debug) printf("dpi_mmc: CMD1\n");
                    s->initializing = 1;
                    s->initializing_count = 0;
                    mmc_set_mode(s, M_CMD_RESP);
                    mmc_resp_r1(s, R1_IDLE, 0);
                    break;
                case CMD16:
                    s->blksize = (s->cmd_reg >> 8) & 0xffff;
                    if (debug) printf("dpi_mmc: CMD16 blksize=%d\n", s->blksize);
                    mmc_set_mode(s, M_CMD_RESP);
                    mmc_resp_r1(s, 0, 0);
                    break;
                case CMD17:
                    if (debug) printf("dpi_mmc: CMD17\n");
                    s->lba = (s->cmd_reg >> 8) & 0xffffffff;
                    do_mmc_read(s);
                    mmc_resp_r1(s, 0, 5);
                    mmc_set_mode(s, M_READ_RESP);
                    break;
                case CMD24:
                    if (debug) printf("dpi_mmc: CMD24\n");
                    s->lba = (s->cmd_reg >> 8) & 0xffffffff;
                    do_mmc_write(s);
                    mmc_resp_r1(s, 0, 5*8);
                    mmc_set_mode(s, M_WRITE_RESP);
                    break;
                }

                //wrong
                //s->cs_deassert_wait = 1;
                s->cmd_bits = 0;
                s->clk_posedge_wait = 1;
                goto done;
            }
            break;
        }
    }

    if (sclk_pos_edge && !cs_asserted && di_asserted) {
        s->unselected_count++;
        if (debug > 1) printf("dpi_mmc: unselected_count %d\n", s->unselected_count);
        if (s->unselected_count >= 74) {
            if (s->mode != M_IDLE) printf("dpi_mmc: going idle\n");
            mmc_set_mode(s, M_IDLE);
        }
    }

    do_asserted = s->do_state;

    if (mmc_responding(s)) {
        if (sclk_pos_edge && cs_asserted) {

            if (s->initializing && s->resp_size == 0) {
                s->initializing_count++;
                if (s->initializing_count > 2)
                    s->initializing = 0;
                if (debug) printf("dpi_mmc: initializing %d\n", s->initializing_count);
                mmc_resp_r1(s, s->initializing ? R1_IDLE : 0, 0);
            }
        }

        if ((sclk_neg_edge && cs_asserted) || (cs_edge && cs_asserted)) {
            if (s->resp_size == 0) {
                mmc_set_mode(s, M_CMD);
	    } else {
                if (s->resp_delay == 0) {
                    if (s->resp[s->resp_index] & (1 << (7 - s->resp_bit)))
                        do_asserted = 1;
                    else
                        do_asserted = 0;

                    if (debug > 1) printf("dpi_mmc: resp, index/size/bit=%d/%d/%d, do=%d\n",
					  s->resp_index, s->resp_size, s->resp_bit, do_asserted);

                    s->resp_bit++;
                    if (s->resp_bit == 8) {
                        s->resp_bit = 0;
                        s->resp_index++;
                    }

                    if (s->resp_index == s->resp_size) {
                        s->resp_size = 0;
                    }
                }
            }
        }
    }

done:
    *m_do = do_asserted ? 1 : 0;
    s->do_state = do_asserted;

    if (0) printf("dpi_mmc: exit\n");
}

#ifdef __cplusplus
}
#endif


/*
 * Local Variables:
 * indent-tabs-mode:nil
 * c-basic-offset:4
 * End:
*/

