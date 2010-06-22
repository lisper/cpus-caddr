#include "svdpi.h"
#include "Vtest__Dpi.h"

#include <stdio.h>

#ifdef __cplusplus
extern "C" {
#endif

/*
 * simple IDE/ATA drive bus level emulation
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

int last_evh;

char last_dior_bit;
char last_diow_bit;
unsigned short last_read;

int running_cver;

static struct state_s {
    unsigned short reg_seccnt, reg_secnum, reg_cyllow, reg_cylhigh, reg_drvhead;
    unsigned short status;

    int fifo_rd;
    int fifo_wr;
    int fifo_depth;
    unsigned short fifo[256 * 128];

    int file_inited;
    int file_fd;

    unsigned int lba;
} state;

#define ATA_ALTER    0x0e
#define ATA_DEVCTRL  0x1e 
#define ATA_DATA     0x10
#define ATA_ERROR    0x11
#define ATA_FEATURE  0x11
#define ATA_SECCNT   0x12
#define ATA_SECNUM   0x13
#define ATA_CYLLOW   0x14
#define ATA_CYLHIGH  0x15
#define ATA_DRVHEAD  0x16
#define ATA_STATUS   0x17
#define ATA_COMMAND  0x17

#define IDE_STATUS_BSY   7
#define IDE_STATUS_DRDY  6
#define IDE_STATUS_DWF   5
#define IDE_STATUS_DSC   4
#define IDE_STATUS_DRQ   3
#define IDE_STATUS_CORR  2
#define IDE_STATUS_IDX   1
#define IDE_STATUS_ERR   0

#define ATA_CMD_READ  0x0020
#define ATA_CMD_WRITE  0x0030


static void
do_ide_setup(struct state_s *s)
{
    s->file_fd = open("disk.img", O_RDWR);

    s->status = (1<<IDE_STATUS_DRDY)|(1<<IDE_STATUS_DSC);
    s->fifo_depth = 0;
    s->fifo_rd = 0;
    s->fifo_wr = 0;
}

static void
do_ide_read(struct state_s *s)
{
    int ret;

    s->lba =
        ((s->reg_drvhead & 0x0f) << 24) |
        ((s->reg_cylhigh & 0xff) << 16) |
        ((s->reg_cyllow & 0xff) << 8) |
        (s->reg_secnum & 0xff);

    printf("dpi_ide: %d (lba %d), seccnt %d (read)\n",
               s->lba*512, s->lba, s->reg_seccnt);

    ret = lseek(s->file_fd, (off_t)s->lba*512, SEEK_SET);
    ret = read(s->file_fd, (char *)s->fifo, 512 * s->reg_seccnt);
    if (ret < 0)
        perror("read");

    printf("dpi_ide: buffer %06o %06o %06o %06o\n",
               s->fifo[0], s->fifo[1], s->fifo[2], s->fifo[3]);

    s->fifo_depth = (512 * s->reg_seccnt) / 2;
    s->fifo_rd = 0;
    s->fifo_wr = 0;

    s->status = (1<<IDE_STATUS_DRDY)|(1<<IDE_STATUS_DSC) | (1<<IDE_STATUS_DRQ);
}

static void
do_ide_write(struct state_s *s)
{
    s->lba =
        ((s->reg_drvhead & 0x0f) << 24) |
        ((s->reg_cylhigh & 0xff) << 16) |
        ((s->reg_cyllow & 0xff) << 8) |
        (s->reg_secnum & 0xff);

    if (0) printf("dpi_ide: %d (lba %d), seccnt %d (write)\n",
               s->lba*512, s->lba, s->reg_seccnt);

    printf("dpi_ide: write prep\n");

    s->fifo_depth = (512 * s->reg_seccnt) / 2;
    s->fifo_rd = 0;
    s->fifo_wr = 0;

    s->status = (1<<IDE_STATUS_DRDY)|(1<<IDE_STATUS_DSC) | (1<<IDE_STATUS_DRQ);
}

static void
do_ide_write_done(struct state_s *s)
{
    int ret;

    printf("dpi_ide: %d (lba %d), seccnt %d (write)\n",
              s->lba*512, s->lba, s->reg_seccnt);

    ret = lseek(s->file_fd, (off_t)s->lba*512, SEEK_SET);
    ret = write(s->file_fd, (char *)s->fifo, 512 * s->reg_seccnt);
    if (ret < 0)
        perror("write");

    s->status = (1<<IDE_STATUS_DRDY)|(1<<IDE_STATUS_DSC);
}

/*
 *
 */
void dpi_ide(int data_in, int* data_out, int dior, int diow, int cs, int da)
{
    struct state_s *s;
    int read_start, read_stop, write_start, write_stop;

    s = &state;

    if (!s->file_inited) {
        s->file_inited = 1;
        do_ide_setup(s);
    }

    /* */
    read_start = 0;
    read_stop = 0;
    write_start = 0;
    write_stop = 0;

    if (dior != last_dior_bit) {
        if (dior == 0) read_start = 1;
        if (dior == 1) read_stop = 1;
    }

    if (diow != last_diow_bit) {
        if (diow == 0) write_start = 1;
        if (diow == 1) write_stop = 1;
    }

    last_dior_bit = dior;
    last_diow_bit = diow;

    if (0) {
        if (read_start) printf("dpi_ide: read start\n");
        if (read_stop) printf("dpi_ide: read stop\n");
        if (write_start) printf("dpi_ide: write start\n");
        if (write_stop) printf("dpi_ide: write stop\n");
    }

    /* */
    if (write_start) {
        if (0) printf("dpi_ide: write %x %x %d\n", cs, da, da);

        switch (cs << 3 | da) {
        case ATA_ALTER:
        case ATA_DEVCTRL:
            break;
        case ATA_FEATURE:
            break;

        case ATA_SECCNT: s->reg_seccnt = data_in; break;
        case ATA_SECNUM: s->reg_secnum = data_in; break;
        case ATA_CYLLOW:
            if (0) printf("dpi_ide: cyllow %04x\n", data_in);
            s->reg_cyllow = data_in;
            break;
        case ATA_CYLHIGH:
            if (0) printf("dpi_ide: cylhigh %04x\n", data_in);
            s->reg_cylhigh = data_in;
            break;
        case ATA_DRVHEAD:
            if (0) printf("dpi_ide: drvhead %04x\n", data_in);
            s->reg_drvhead = data_in;
            break;

        case ATA_DATA:
            s->fifo[s->fifo_wr] = data_in;

            if (1) printf("dpi_ide: write data [%d/%d] %o\n",
                              s->fifo_wr, s->fifo_depth, data_in);

            if (s->fifo_wr < s->fifo_depth)
                s->fifo_wr++;

            if (s->fifo_wr >= s->fifo_depth) {
                do_ide_write_done(s);
            }
            break;

        case ATA_COMMAND:
            printf("dpi_ide: command %04x\n", data_in);
            switch (data_in) {
            case 0x0020:
                printf("dpi_ide: XXX READ\n");
                do_ide_read(s);
                break;
            case 0x0030:
                printf("dpi_ide: XXX WRITE\n");
                do_ide_write(s);
                break;
            }
            break;
        }
    }

    if (read_start) {
        if (0) printf("dpi_ide: read cs=%x da=%x %d\n", cs, da, da);

        switch (cs << 3 | da) {
        case ATA_DATA:
            *data_out = last_read = s->fifo[s->fifo_rd];
            if (1) printf("dpi_ide: read data [%d/%d] %o\n",
                              s->fifo_rd, s->fifo_depth, *data_out);
            if (s->fifo_rd < s->fifo_depth)
                s->fifo_rd++;

            if (s->fifo_rd >= s->fifo_depth) {
                printf("dpi_ide: fifo empty\n");
                s->status = (1<<IDE_STATUS_DRDY)|(1<<IDE_STATUS_DSC);
            }
            break;

        case ATA_STATUS:
            *data_out = last_read = s->status;
            if (1) printf("dpi_ide: read status %04x\n", *data_out);
            break;
        }
    }

    if (!read_start && !write_start && dior == 0) {
        if (0) printf("dpi_ide: read %04x\n", last_read);
        *data_out = last_read;
    }

    if (read_stop) {
    }
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

