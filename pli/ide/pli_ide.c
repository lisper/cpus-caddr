/* pli_ide.c */
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

#include "vpi_user.h"

#ifdef __CVER__
#include "cv_vpi_user.h"
#endif

#ifdef __MODELSIM__
#include "veriuser.h"
#endif

PLI_INT32 pli_ide(void);
extern void register_my_systfs(void); 
extern void register_my_systfs(void);

char *instnam_tab[10]; 
int last_evh;

char last_dior_bit;
char last_diow_bit;

static struct state_s {
    vpiHandle bus_aref;
    unsigned short reg_seccnt, reg_secnum, reg_cyllow, reg_cylhigh, reg_drvhead;
    unsigned short status;

    int fifo_rd;
    int fifo_wr;
    int fifo_depth;
    unsigned short fifo[256 * 128];

    int file_inited;
    int file_fd;

    unsigned int lba;
} state[10];

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

    vpi_printf("pli_ide: lba %08x (%d), seccnt %d (read)\n",
               s->lba, s->lba*512,s->reg_seccnt);

    ret = lseek(s->file_fd, (off_t)s->lba*512, SEEK_SET);
    ret = read(s->file_fd, (char *)s->fifo, 512 * s->reg_seccnt);
    if (ret < 0)
        perror("read");

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

    vpi_printf("pli_ide: write prep\n");

    s->fifo_depth = (512 * s->reg_seccnt) / 2;
    s->fifo_rd = 0;
    s->fifo_wr = 0;

    s->status = (1<<IDE_STATUS_DRDY)|(1<<IDE_STATUS_DSC) | (1<<IDE_STATUS_DRQ);
}

static void
do_ide_write_done(struct state_s *s)
{
    int ret;

    vpi_printf("pli_ide: lba %08x (%d), seccnt %d (write)\n",
               s->lba, s->lba*512, s->reg_seccnt);

    ret = lseek(s->file_fd, (off_t)s->lba*512, SEEK_SET);
    ret = write(s->file_fd, (char *)s->fifo, 512 * s->reg_seccnt);
    if (ret < 0)
        perror("write");

    s->status = (1<<IDE_STATUS_DRDY)|(1<<IDE_STATUS_DSC);
}

/*
 *
 */
PLI_INT32 pli_ide(void)
{
    vpiHandle href, iter, mhref;
    vpiHandle busref, diorref, diowref, csref, daref;
    struct state_s *s;

    int numargs, inst_id;

    s_vpi_value tmpval, outval;

    char bus_bits[17], cs_bits[3], da_bits[4], diow_bit, dior_bit;
    unsigned int cs, da, bus;

    int read_start, read_stop, write_start, write_stop;


    //vpi_printf("pli_ide:\n");

    href = vpi_handle(vpiSysTfCall, NULL); 
    if (href == NULL) {
        vpi_printf("** ERR: $pli_ide PLI 2.0 can't get systf call handle\n");
        return(0);
    }

    mhref = vpi_handle(vpiScope, href);

    if (vpi_get(vpiType, mhref) != vpiModule)
        mhref = vpi_handle(vpiModule, mhref); 

    inst_id = getadd_inst_id(mhref);

    //vpi_printf("pli_ide: inst_id %d\n", inst_id);
    s = &state[inst_id];

    if (!s->file_inited) {
        s->file_inited = 1;
        do_ide_setup(s);
    }

    iter = vpi_iterate(vpiArgument, href);

    numargs = vpi_get(vpiSize, iter);

    /* data_bus[15:0], ide_dior, ide_diow, ide_cs[1:0], ide_da[2:0] */
    busref = vpi_scan(iter);
    diorref = vpi_scan(iter);
    diowref = vpi_scan(iter);
    csref = vpi_scan(iter);
    daref = vpi_scan(iter);

    if (busref == NULL || diorref == NULL || diowref == NULL ||
        csref == NULL || daref == NULL)
    {
        vpi_printf("**ERR: $pli_ide bad args\n");
        return(0);
    }

    tmpval.format = vpiBinStrVal; 
    vpi_get_value(busref, &tmpval);
    strcpy(bus_bits, tmpval.value.str);

    tmpval.format = vpiIntVal; 
    vpi_get_value(busref, &tmpval);
    bus = tmpval.value.integer;

    tmpval.format = vpiBinStrVal; 
    vpi_get_value(csref, &tmpval);
    strcpy(cs_bits, tmpval.value.str);

    tmpval.format = vpiIntVal; 
    vpi_get_value(csref, &tmpval);
    cs = tmpval.value.integer;

    tmpval.format = vpiBinStrVal; 
    vpi_get_value(daref, &tmpval);
    strcpy(da_bits, tmpval.value.str);

    tmpval.format = vpiIntVal; 
    vpi_get_value(daref, &tmpval);
    da = tmpval.value.integer;

    tmpval.format = vpiBinStrVal; 
    vpi_get_value(diorref, &tmpval);
    dior_bit =  tmpval.value.str[0];

    tmpval.format = vpiBinStrVal; 
    vpi_get_value(diowref, &tmpval);
    diow_bit =  tmpval.value.str[0];

    /* */
    read_start = 0;
    read_stop = 0;
    write_start = 0;
    write_stop = 0;

    if (dior_bit != last_dior_bit) {
        if (dior_bit == '0') read_start = 1;
        if (dior_bit == '1') read_stop = 1;
    }

    if (diow_bit != last_diow_bit) {
        if (diow_bit == '0') write_start = 1;
        if (diow_bit == '1') write_stop = 1;
    }

    last_dior_bit = dior_bit;
    last_diow_bit = diow_bit;

    if (0) {
        if (read_start) vpi_printf("pli_ide: read start\n");
        if (read_stop) vpi_printf("pli_ide: read stop\n");
        if (write_start) vpi_printf("pli_ide: write start\n");
        if (write_stop) vpi_printf("pli_ide: write stop\n");
    }

    /* */
    if (write_start) {
        if (0) vpi_printf("pli_ide: write %s %s %d\n", cs_bits, da_bits, da);

        switch (cs << 3 | da) {
        case ATA_ALTER:
        case ATA_DEVCTRL:
            break;
        case ATA_FEATURE:
            break;

        case ATA_SECCNT: s->reg_seccnt = bus; break;
        case ATA_SECNUM: s->reg_secnum = bus; break;
        case ATA_CYLLOW:
            if (0) vpi_printf("pli_ide: cyllow %04x %s\n", bus, bus_bits);
            s->reg_cyllow = bus;
            break;
        case ATA_CYLHIGH:
            if (0) vpi_printf("pli_ide: cylhigh %04x %s\n", bus, bus_bits);
            s->reg_cylhigh = bus;
            break;
        case ATA_DRVHEAD:
            if (0) vpi_printf("pli_ide: drvhead %04x %s\n", bus, bus_bits);
            s->reg_drvhead = bus;
            break;

        case ATA_DATA:
            s->fifo[s->fifo_wr] = bus;

            if (1) vpi_printf("pli_ide: write data [%d/%d] %o\n",
                              s->fifo_wr, s->fifo_depth, bus);

            if (s->fifo_wr < s->fifo_depth)
                s->fifo_wr++;

            if (s->fifo_wr >= s->fifo_depth) {
                do_ide_write_done(s);
            }
            break;

        case ATA_COMMAND:
            vpi_printf("pli_ide: command %04x\n", bus);
            switch (bus) {
            case 0x0020:
                vpi_printf("pli_ide: XXX READ\n");
                do_ide_read(s);
                break;
            case 0x0030:
                vpi_printf("pli_ide: XXX WRITE\n");
                do_ide_write(s);
                break;
            }
            break;
        }
    }

    if (read_start) {
        if (0) vpi_printf("pli_ide: read %s %s %d\n", cs_bits, da_bits, da);

        switch (cs << 3 | da) {
        case ATA_DATA:
            bus = s->fifo[s->fifo_rd];
            if (1) vpi_printf("pli_ide: read data [%d/%d] %04o\n",
                              s->fifo_rd, s->fifo_depth, bus);
            if (s->fifo_rd < s->fifo_depth)
                s->fifo_rd++;

            if (s->fifo_rd >= s->fifo_depth) {
                vpi_printf("pli_ide: fifo empty\n");
                s->status = (1<<IDE_STATUS_DRDY)|(1<<IDE_STATUS_DSC);
            }
            break;

        case ATA_STATUS:
            bus = s->status;
            vpi_printf("pli_ide: read status %04x\n", bus);
            break;
        }

#ifdef __CVER__
        if (s->bus_aref == 0)
            s->bus_aref = vpi_put_value(busref, NULL, NULL, vpiAddDriver);
#else
        s->bus_aref = busref;
#endif

        outval.format = vpiIntVal;
        outval.value.integer = bus;
        vpi_put_value(s->bus_aref, &outval, NULL, vpiNoDelay);
    }

    if (read_stop) {
        outval.format = vpiBinStrVal;
        outval.value.str = "zzzzzzzzzzzzzzzz";
//        outval.value.str = "0000000000000000";
        if (s->bus_aref)
            vpi_put_value(s->bus_aref, &outval, NULL, vpiNoDelay);
    }

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
        { vpiSysTask, 0, "$pli_ide", pli_ide, NULL, NULL, NULL },
        { 0, 0, NULL, NULL, NULL, NULL, NULL }
    };

    systf_data_p = &(systf_data_list[0]);
    while (systf_data_p->type != 0) vpi_register_systf(systf_data_p++);
}

#ifdef __CVER__
static void (*ide_vlog_startup_routines[]) () =
{
 register_my_systfs, 
 0
};

/* dummy +loadvpi= boostrap routine - mimics old style exec all routines */
/* in standard PLI vlog_startup_routines table */
void ide_vpi_compat_bootstrap(void)
{
    int i;

    for (i = 0;; i++) 
    {
        if (ide_vlog_startup_routines[i] == NULL) break; 
        ide_vlog_startup_routines[i]();
    }
}

void vpi_compat_bootstrap(void)
{
    ide_vpi_compat_bootstrap();
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
