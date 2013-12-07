#include "svdpi.h"
#include "Vtest__Dpi.h"

#include <stdio.h>

#ifdef __cplusplus
extern "C" {
#endif

/*
 * block device emulation
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

int last_start_bit, last_rd_bit, last_wr_bit;

static int debug;

int fifo_rd;
int fifo_wr;
int fifo_depth;
unsigned short fifo[256 * 128];

static int file_inited;
static int file_fd;

unsigned int lba;
unsigned int rw_status;

static int busy_delay;
static int pending_read;
static int wr_stream;
static int rd_stream;
static int rd_blocks;
static int wr_blocks;

static int bsy_state;
static int rdy_state;
static int err_state;
static int iordy_state;
static int data_out_state;

static void
do_file_setup(void)
{
    file_fd = open("disk.img", O_RDWR);
    if (debug) printf("block_dev: fd %d\n", file_fd);

    fifo_depth = 0;
    fifo_rd = 0;
    fifo_wr = 0;

    wr_stream = 0;
    rd_stream = 0;
}

static void
do_bd_read(void)
{
    int ret;

    printf("block_dev: %d (lba %d) (read)\n",
               lba*512, lba);

    ret = lseek(file_fd, (off_t)lba*512, SEEK_SET);
    ret = read(file_fd, (char *)fifo, 512*2);
    if (ret < 0)
        perror("read");

    if (debug) printf("block_dev: buffer %06o %06o %06o %06o\n",
                      fifo[0], fifo[1], fifo[2], fifo[3]);

    fifo_depth = 512; /* 1024 bytes */
    fifo_rd = 0;
    fifo_wr = 0;
}

static void
do_bd_write(void)
{
    if (0) printf("block_dev: %d (lba %d) (write)\n",
		  lba*512, lba);

    if (debug) printf("block_dev: write prep\n");

    fifo_depth = 512; /* 1024 bytes */
    fifo_rd = 0;
    fifo_wr = 0;
}

static void
do_bd_write_done(void)
{
    int ret;

    printf("block_dev: %d (lba %d) (write)\n",
	   lba*512, lba);

    ret = lseek(file_fd, (off_t)lba*512, SEEK_SET);
    ret = write(file_fd, (char *)fifo, 512*2);
    if (ret < 0) {
        perror("write");
    }
}

void do_busy_delay(void)
{
	busy_delay = 20;
}

/*
 *
 */
void block_dev(int cmd, int start, int* bsy, int* rdy, int* err, int addr,
	       int data_in, int* data_out, int rd, int wr, int* iordy)
{
    int start_start, start_stop, read_start, read_stop, write_start, write_stop;

    if (0) printf("block_dev: cmd %x start %d\n", cmd, start);

    if (file_inited == 0) {
	file_inited = 1;
        do_file_setup();
    }

    /* */
    start_start = 0;
    start_stop = 0;
    read_start = 0;
    read_stop = 0;
    write_start = 0;
    write_stop = 0;

    if (start != last_start_bit) {
        if (start == 1) start_start = 1;
        if (start == 0) start_stop = 1;
    }
    last_start_bit = start;

    if (rd != last_rd_bit) {
        if (rd == 1) read_start = 1;
        if (rd == 0) read_stop = 1;
    }
    last_rd_bit = rd;

    if (wr != last_wr_bit) {
        if (wr == 1) write_start = 1;
        if (wr == 0) write_stop = 1;
    }
    last_wr_bit = wr;

    iordy_state = 1;

    /* */
    if (start_start) {
	    rdy_state = 0;
	    bsy_state = 1;
	    err_state = 0;
	    data_out_state = 0;

	    lba = addr;

	    switch (cmd) {
	    case 0: /* reset */
		    printf("block_dev: reset\n");
		    do_busy_delay();
		    bsy_state = 1;
		    break;
	    case 1: /* read */
		    printf("block_dev: read\n");
		    do_bd_read();
		    do_busy_delay();
		    bsy_state = 1;
		    pending_read = 1;
		    rd_blocks = 2;
		    break;
	    case 2: /* write */
		    printf("block_dev: write\n");
		    do_bd_write();
		    do_busy_delay();
		    bsy_state = 1;
		    iordy_state = 1;
		    wr_blocks = 1;
		    break;
	    }
    }

    if (write_start) {
            if (debug) printf("block_dev: write start\n");
	    wr_stream = 1;
	    iordy_state = 1;
    }

    if (write_stop) {
            if (debug) printf("block_dev: write stop\n");
	    wr_stream = 0;
//	    iordy_state = 0;
    }

    if (wr && wr_stream) {
            fifo[fifo_wr] = data_in;

            if (debug) printf("block_dev: write data [%d/%d] %o\n",
                              fifo_wr, fifo_depth, data_in);

            if (fifo_wr < fifo_depth)
                fifo_wr++;

            if (fifo_wr >= fifo_depth) {
                do_bd_write_done();
		fifo_wr = 0;
		lba++;

		wr_blocks--;
		if (wr_blocks == 0)
			rdy_state = 1;
            }

	    iordy_state = 1;
    }

    if (read_start) {
        if (debug) printf("block_dev: read start\n");
	rd_stream = 1;
	iordy_state = 1;
    }

    if (read_stop) {
        if (debug) printf("block_dev: read stop\n");
	rd_stream = 0;
	iordy_state = 0;
    }

    if (rd && rd_stream) {
	data_out_state = fifo[fifo_rd];
	if (debug) printf("block_dev: read data [%d/%d] %o\n",
		      fifo_rd, fifo_depth, data_out_state);
	if (fifo_rd < fifo_depth)
                fifo_rd++;

	if (fifo_rd >= fifo_depth) {
            if (debug) printf("block_dev: fifo empty\n");
	    iordy_state = 0;
	}
    }

    if (busy_delay) {
	    busy_delay--;
	    if (busy_delay == 0) {
		    bsy_state = 0;
		    rdy_state = 1;

		    if (pending_read) {
			    pending_read = 0;
			    iordy_state = 1;
		    }

	    }
    }

    *bsy = bsy_state;
    *rdy = rdy_state;
    *iordy = iordy_state;
    *data_out = data_out_state;
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

