/*
 * ide.h
 *
 * definitions for accessing an IDE drive...
 */

/* HDC Status Register Bit Masks (1F7h) */
#define BUSY        0x80  /* busy.. can't talk now! */
#define READY       0x40  /* Drive Ready  */
#define WRITE_FAULT 0x20  /* Bad news */
#define SEEKOK      0x10  /* Seek Complete */
#define DATA_REQ    0x08  /* Sector buffer needs servicing */
#define CORRECTED   0x04  /* ECC corrected data was read */
#define REV_INDEX   0x02  /* Set once each disk revolution */
#define ERROR       0x01  /* data address mark not found */

/* HDC Error Register Bit Masks (1F1h) */
#define BAD_SECTOR  0x80  /* bad block */
#define BAD_ECC     0x40  /* bad data ecc */
#define BAD_IDMARK  0x10  /* id not found */
#define BAD_CMD     0x04  /* aborted command */
#define BAD_SEEK    0x02  /* trk 0 not found on recalibrate, or bad seek */
#define BAD_ADDRESS 0x01  /* data address mark not found */


/* HDC internal command bytes (HDC_Cmd[7]) */
#define HDC_RECAL      0x10   /* 0001 0000 */
#define HDC_READ       0x20   /* 0010 0000 */
#define HDC_READ_LONG  0x22   /* 0010 0010 */
#define HDC_WRITE      0x30   /* 0011 0000 */
#define HDC_WRITE_LONG 0x32   /* 0011 0010 */
#define HDC_VERIFY     0x40   /* 0100 0000 */
#define HDC_FORMAT     0x50   /* 0101 0000 */
#define HDC_SEEK       0x70   /* 0111 0000 */
#define HDC_DIAG       0x90   /* 1001 0000 */
#define HDC_SET_PARAMS 0x91   /* 1001 0001 */
#define HDC_IDENTIFY   0xEC   /* ask drive to identify itself	*/

//#define HD_PORT 0x1f0
#define HD_PORT 0x0
#define HD_REG_PORT 0x4000

