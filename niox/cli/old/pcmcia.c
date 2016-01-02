/* 
 * pcmcia.c
 *
 * $Id: pcmcia.c,v 1.3 2005/03/10 14:07:05 brad Exp $
 */

#include "types.h"
#include "diag.h"
#include "lh7a400.h"
#include "eframe.h"
#include "cis.h"

volatile u32 *pcmcia_memory;
volatile u32 *pcmcia_attrib;
volatile u32 *pcmcia_io;
volatile u32 *pcmcia_npcstatre;

static void
print_funcid(int func)
{
    printf("function id: ");
    switch (func) {
    case CISTPL_FUNCID_MULTI:
        printf("Multi-Function");
        break;
    case CISTPL_FUNCID_MEMORY:
        printf("Memory");
        break;
    case CISTPL_FUNCID_SERIAL:
        printf("Serial Port");
        break;
    case CISTPL_FUNCID_PARALLEL:
        printf("Parallel Port");
        break;
    case CISTPL_FUNCID_FIXED:
        printf("Fixed Disk");
        break;
    case CISTPL_FUNCID_VIDEO:
        printf("Video Adapter");
        break;
    case CISTPL_FUNCID_NETWORK:
        printf("Network Adapter");
        break;
    case CISTPL_FUNCID_AIMS:
        printf("AIMS Card");
        break;
    case CISTPL_FUNCID_SCSI:
        printf("SCSI Adapter");
        break;
    default:
        printf("Unknown");
        break;
    }
    printf(" Card\n");
}

static void
print_fixed(volatile u_char *p)
{
    if (p == NULL)
        return;

    switch (*p) {
    case CISTPL_FUNCE_IDE_IFACE:
    {
        u_char iface = *(p+2);

        printf((iface == CISTPL_IDE_INTERFACE) ? " IDE" : " unknown");
        printf(" interface ");
        break;
    }
    case CISTPL_FUNCE_IDE_MASTER:
    case CISTPL_FUNCE_IDE_SLAVE:
    {
        u_char f1 = *(p+2);
        u_char f2 = *(p+4);

        printf((f1 & CISTPL_IDE_SILICON) ? " [silicon]" : " [rotating]");

        if (f1 & CISTPL_IDE_UNIQUE) printf(" [unique]");

        printf((f1 & CISTPL_IDE_DUAL) ? " [dual]" : " [single]");

        if (f2 & CISTPL_IDE_HAS_SLEEP) printf(" [sleep]");
        if (f2 & CISTPL_IDE_HAS_STANDBY) printf(" [standby]");
        if (f2 & CISTPL_IDE_HAS_IDLE) printf(" [idle]");
        if (f2 & CISTPL_IDE_LOW_POWER) printf(" [low power]");
        if (f2 & CISTPL_IDE_REG_INHIBIT) printf(" [reg inhibit]");
        if (f2 & CISTPL_IDE_HAS_INDEX) printf(" [index]");
        if (f2 & CISTPL_IDE_IOIS16) printf(" [IOis16]");

        break;
    }
    }
    printf("\n");
}

int identify(volatile u_char *p)
{
    u_char id_str[MAX_IDENT_CHARS];
    u_char data;
    u_char *t;
    u_char **card;
    int i, done;

    if (p == NULL)
        return 0;

    t = id_str;
    done =0;

    for (i=0; i<=4 && !done; ++i, p+=2) {
        while ((data = *p) != '\0') {
            if (data == 0xFF) {
                done = 1;
                break;
            }
            *t++ = data;
            if (t == &id_str[MAX_IDENT_CHARS-1]) {
                done = 1;
                break;
            }
            p += 2;
        }
        if (!done)
            *t++ = ' ';
    }
    *t = '\0';
    while (--t > id_str) {
        if (*t == ' ')
            *t = '\0';
        else
            break;
    }
    printf("%s\n", id_str);

    return 0;
}

/* parse config tuples to find config register and enable PCMCIA card */
int
check_ide_device(void *cfg_mem_addr)
{
    volatile u_char *ident = NULL;
    volatile u_char *feature_p[MAX_FEATURES];
    volatile u_char *p, *start;
    int n_features = 0;
    u_char func_id = ~0;
    u_char code, len;
    u_short config_base = 0;
    int found = 0;
    int i;

    printf("PCMCIA attrib mem %8x\n", cfg_mem_addr);

    start = p = (volatile u_char *)cfg_mem_addr;

    while ((p - start) < MAX_TUPEL_SZ) {

        code = *p;
        p += 2;

        if (code == 0xFF) {
            /* end of chain */
            break;
        }

        len = *p;
        p += 2;

        if (1) {
            volatile u_char *q = p;
            printf("\nTuple code %2x  length %d\n\tData:", code, len);

            for (i = 0; i < len; ++i) {
                printf(" %2x", *q);
                q += 2;
            }
        }

        switch (code) {
        case CISTPL_VERS_1:
            ident = p + 4;
            break;
        case CISTPL_FUNCID:
            func_id = *p;
            break;
        case CISTPL_FUNCE:
            if (n_features < MAX_FEATURES)
                feature_p[n_features++] = p;
            break;
        case CISTPL_CONFIG:
            config_base = (*(p+6) << 8) + (*(p+4));
            printf("Config base %x\n", config_base);
        default:
            break;
        }
        p += 2 * len;
    }

    found = identify(ident);

    if (func_id != ((u_char)~0)) {
        print_funcid(func_id);

        if (func_id == CISTPL_FUNCID_FIXED)
            found = 1;
        else
            /* no disk drive */
            return -1;
    }

    for (i = 0; i < n_features; ++i) {
        print_fixed(feature_p[i]);
    }

    if (!found) {
        printf("unknown card type\n");
        return -1;
    }

#define COR_FUNC_ENA		0x01
    /* set configuration option register to enable card */
    *((u_char *)(cfg_mem_addr + config_base)) = COR_FUNC_ENA;

    return (0);
}

int
pcmcia_cis_scan(void)
{
    return check_ide_device((void *)pcmcia_attrib);
}

void
pcmcia_init_ptrs(void)
{
    pcmcia_memory = (volatile u32 *)0x4c000000;
    pcmcia_attrib = (volatile u32 *)0x48000000;
    pcmcia_npcstatre = (volatile u32 *)0x44000000;
    pcmcia_io = (volatile u32 *)0x40000000;
}

int
pcmcia_init(int slots, int wait)
{
    SMCREGS *smc = (SMCREGS *)0x80002000;
    u32 v;

    printf("initializing for %d slot(s)\n", slots);

    pcmcia_init_ptrs();

    smc->pc1_attribute =
        PCMCIA_CFG_W8 | PCMCIA_CFG_PC(255) |
        PCMCIA_CFG_HT(15) | PCMCIA_CFG_AC(255);

    smc->pc1_common =
        PCMCIA_CFG_W8 | PCMCIA_CFG_PC(255) |
        PCMCIA_CFG_HT(15) | PCMCIA_CFG_AC(255);

    smc->pc1_io =
        PCMCIA_CFG_W8 | PCMCIA_CFG_PC(255) |
        PCMCIA_CFG_HT(15) | PCMCIA_CFG_AC(255);

    printf("pcmcia_control before %8x\n", smc->pcmcia_control);

    switch (slots) {
    case 1:
        v = PCMCIA_CONTROL_AUTOPREG |
            (wait ? PCMCIA_CONTROL_WEN1 : 0) |
            PCMCIA_CONTROL_PC1NORMAL | 
            PCMCIA_CONTROL_PC;
        break;
    case 2:
        v = PCMCIA_CONTROL_AUTOPREG |
            (wait ? (PCMCIA_CONTROL_WEN2 | PCMCIA_CONTROL_WEN1) : 0) |
            PCMCIA_CONTROL_PC1NORMAL | 
            PCMCIA_CONTROL_PC2NORMAL | 
            PCMCIA_CONTROL_CFPC;
        break;
    }

    printf("write %8x -> %8x\n", v, &smc->pcmcia_control);

    smc->pcmcia_control = v;

    printf("pcmcia_control after %8x\n", smc->pcmcia_control);

    return 0;
}

int
pcmcia_shutdown(void)
{
    SMCREGS *smc = (SMCREGS *)0x80002000;
    smc->pcmcia_control = 0;
    return 0;
}

int
pcmcia_status_loop(void)
{
    volatile u32 s1, s;

    if (pcmcia_npcstatre == 0) {
        pcmcia_init_ptrs();
    }

    while (1) {
        s = *(volatile u16 *)pcmcia_npcstatre;
        if (serial_poll())
            break;
    }

    return 0;
}

int
pcmcia_status(void)
{
    volatile u32 s1, s;

    if (pcmcia_npcstatre == 0) {
        pcmcia_init_ptrs();
    }

//    s1 = *pcmcia_io; /* dummy read to set up buffers */
    s = *pcmcia_npcstatre;
    printf("pcmcia status (@%8x) %8x\n", pcmcia_npcstatre, s);

    if (s & PCMCIA_STAT_PC1_BVD1) printf("pc1_bvd1 ");
    if (s & PCMCIA_STAT_PC1_BVD2) printf("pc1_bvd2 ");
    if (s & PCMCIA_STAT_NPC_VS1) printf("npc_vs1 ");
    if (s & PCMCIA_STAT_NPC_VS2) printf("npc_vs2 ");
    if (s & PCMCIA_STAT_PC1_CD) printf("pc1_cd ");
    if (s & PCMCIA_STAT_CONF_SW2) printf("conf_sw2 ");
    if (s & PCMCIA_STAT_CONF_SW3) printf("conf_sw3 ");
    if (s & PCMCIA_STAT_CONF_SW4) printf("conf_sw4 ");
    printf("\n");

    return 0;
}

int
cmd_pcmcia(int argc, char *argv[])
{
    u32 s;

    if (argc > 1 && strcmp(argv[1], "init") == 0) {
        pcmcia_init(1, 0);
    }

    if (argc > 1 && strcmp(argv[1], "initw") == 0) {
        pcmcia_init(1, 1);
    }

    if (argc > 1 && strcmp(argv[1], "init2") == 0) {
        pcmcia_init(2, 0);
    }

    if (argc > 1 && strcmp(argv[1], "init2w") == 0) {
        pcmcia_init(2, 1);
    }

    if (argc > 1 && strcmp(argv[1], "stop") == 0) {
        pcmcia_shutdown();
    }

    if (argc > 1 && strcmp(argv[1], "loop") == 0) {
        pcmcia_status_loop();
    }

    if (argc > 1 && strcmp(argv[1], "cis") == 0) {
        pcmcia_cis_scan();
    }

    pcmcia_status();


    return 0;
}

int
cmd_switches(int argc, char *argv[])
{
    if (argc > 1 && strcmp(argv[1], "init") == 0) {
    }

    pcmcia_status();

    return 0;
}


/*
 * Local Variables:
 * indent-tabs-mode:nil
 * c-basic-offset:4
 * End:
*/
