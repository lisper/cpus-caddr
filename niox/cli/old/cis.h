/*
 * cis.h
 *
 * PCMCIA CIS defines
 */

/* defines for PCMCIA configuration information */
#define MAX_TUPEL_SZ    512
#define MAX_FEATURES    4

#define MAX_IDENT_CHARS         64
#define MAX_IDENT_FIELDS        4

#define CISTPL_VERS_1           0x15
#define CISTPL_FUNCID           0x21
#define CISTPL_FUNCE            0x22
#define CISTPL_CONFIG           0x1a

/*
 * CIS Function ID codes
 */
#define CISTPL_FUNCID_MULTI     0x00
#define CISTPL_FUNCID_MEMORY    0x01
#define CISTPL_FUNCID_SERIAL    0x02
#define CISTPL_FUNCID_PARALLEL  0x03
#define CISTPL_FUNCID_FIXED     0x04
#define CISTPL_FUNCID_VIDEO     0x05
#define CISTPL_FUNCID_NETWORK   0x06
#define CISTPL_FUNCID_AIMS      0x07
#define CISTPL_FUNCID_SCSI      0x08

/*
 * Fixed Disk FUNCE codes
 */
#define CISTPL_IDE_INTERFACE    0x01

#define CISTPL_FUNCE_IDE_IFACE  0x01
#define CISTPL_FUNCE_IDE_MASTER 0x02
#define CISTPL_FUNCE_IDE_SLAVE  0x03

/* First feature byte */
#define CISTPL_IDE_SILICON      0x04
#define CISTPL_IDE_UNIQUE       0x08
#define CISTPL_IDE_DUAL         0x10

/* Second feature byte */
#define CISTPL_IDE_HAS_SLEEP    0x01
#define CISTPL_IDE_HAS_STANDBY  0x02
#define CISTPL_IDE_HAS_IDLE     0x04
#define CISTPL_IDE_LOW_POWER    0x08
#define CISTPL_IDE_REG_INHIBIT  0x10
#define CISTPL_IDE_HAS_INDEX    0x20
#define CISTPL_IDE_IOIS16       0x40

