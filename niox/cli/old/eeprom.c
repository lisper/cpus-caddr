/*
 * read/write the cs8900 eeprom
 *
 * $Id: eeprom.c,v 1.2 2005/03/10 14:07:05 brad Exp $
 */

#include "diag.h"
#include "types.h"

#define PP_EECMD 0x40     /* EEPROM Command PP register */
#define PP_EEData 0x42    /* EEPROM Data PP register */
#define PP_SelfST 0x136 
#define EISA_ID 0x00
#define SI_BUSY  0x100
#define EEPROM_PRESENT 0x200
#define MAX_VECTOR 0xFF
#define IN 1
#define OUT 0
#define MAXLINE 0xFF
#define UNKNOWN 0

typedef struct {
    u16 ee_addr;
    u16 w_count;
} BLOCK;

/* Globals */

u16 IO_base, crnt_word, EE_data[80], ia_word[3], sn_word[2];
BLOCK blocks[40];
u8 blk_count;

enum {NO_EEPROM, EEPROM_OK, EEPROM_ACCESS_ERR, NO_CS8900};

static volatile u32 *io_base;

#define byte_swap(n) (n)

/* WritePP Routine
 * Writes word to PacketPage register @ PP_offset.
 */
void writePP( u16 PP_offset, u16 outword )
{
    io_base[0x0A*4] = PP_offset;
    io_base[0x0C*4] = outword;
}


/* ReadPP Routine
 * Returns word from PacketPage register @ PP_offset.
 */
u16 readPP( u16 PP_offset )
{
    u16 reg_val;

    io_base[0x0A*4] = PP_offset;
    reg_val = io_base[0x0C*4];
    return reg_val;
}

/* ISA I/O instructions take ~1.0 microseconds. Reading the NMI Status
 * Register (0x61) is a good way to pause on all machines.
 */
void slow( void )
{
    delayus();
}


/*
 * ReadEE Routine
 * Returns word from EEPROM from address EE_word_offset
 */
u16 readEE( u16 EE_word_offset )
{
    /* wait until SIBUSY is clear */
    while ( readPP( PP_SelfST ) & SI_BUSY );

    /* read EEPROM command */
    writePP( PP_EECMD, ( 0x0200 + EE_word_offset )  );

    /* wait until SIBUSY is clear */
    while ( readPP( PP_SelfST ) & SI_BUSY );
    slow( );

    return( readPP( PP_EEData ) );
}



/* WriteEE Routine
 * Writes outword to the EEPROM @ address EE_Word_offset.  Returns a
 * read back of the word just written.
 */
u16 writeEE( u16 EE_word_offset, u16 outword )
{
    u16 retval;

    while ( readPP( PP_SelfST ) & SI_BUSY );   /* wait until SIBUSY is clear */

    writePP( PP_EECMD, ( 0x00F0 )  );          /* enable-write command */
    while ( readPP( PP_SelfST ) & SI_BUSY );   /* wait until SIBUSY is clear */
    writePP( PP_EEData, outword );
    writePP( PP_EECMD, ( 0x0100 + EE_word_offset )  );     /* write command */
    while ( readPP( PP_SelfST ) & SI_BUSY );   /* wait until SIBUSY is clear */
    writePP( PP_EECMD, ( 0x0000 )  );          /* disable-write command */
    while ( readPP( PP_SelfST ) & SI_BUSY );   /* wait until SIBUSY is clear */
    writePP( PP_EECMD, ( 0x0200 + EE_word_offset )  );   /* write command */
    while ( readPP( PP_SelfST ) & SI_BUSY );   /* wait until SIBUSY is clear */
    slow( );
    retval = readPP( PP_EEData );              /* read back and return word */
    return( retval );                          /*just written */
}



static void burn_it(void)
{
    u16 i, j;

    i = 0;
    crnt_word = 0;
    while (i < blk_count) {
        for (j = 0; j < blocks[i].w_count; j++)
            writeEE(blocks[i].ee_addr + j, EE_data[crnt_word++]);
        i++;
    }
}


/* Scan Routine
 * Scans IO space looking for CS8900's signature.  Returns
 * the IO Base address found.  Returns 0 if not found.
 */
u32 scan_for_8900(void)
{
    u16 id = 0;

    io_base = (volatile u32 *)0x60000000;

    id = readPP(EISA_ID);
    if(id == 0x630E) {
        printf("Found the CS8900. IO Base address = %x\n", io_base);
        return (u32)io_base;
    }

    printf("\nCS8900 not found.\n");
    return 0;            /* CS8900 not found */
}

/*
 * Init Routine
 * Checks for working EEPROM attached to CS8900. Returns 1 (true) if working
 * EEPROM is attached, 0 otherwise.
 */
static char init(void)
{
    u16 SelfST;

    SelfST = readPP(PP_SelfST);
    /* strip bits 15-6, equals 0x16 if CS8900 here */
    if( (SelfST & 0x3F) != 0x16) {
        printf("SelfST incorrect, %x\n", SelfST);
        return 0;
    }
    else {
        if(SelfST & EEPROM_PRESENT ) {
            printf("SelfSt indicates EEPROM present\n");
            return 1;
        }
        else    {                              /* EEPROM not used */
            printf("SelfSt indicates NO EEPROM present\n");
            return 0;
        }
    }
}



/* Checksum Routine
 *
 * Returns a checksum "word" based on all "bytes" in a block.  Blk_lenght is
 * actual number of bytes to sum.  Checksum is returned in high byte of word.
 */
static u16 chksum (u16 base, u16 word_cnt)
{
    u16 i, sum = 0;

    for(i=0; i < word_cnt; i++) {
        sum += ((EE_data[base] & 0xFF) + (EE_data[base] >> 8));
        ++base;
    }
    sum = ~sum + 1;
    return sum << 8;
}


void PnP_chksum (u16 base, u16 word_cnt)
{
    u16 i, sum = 0;

    /* don't calc with word that has end tag */
    --word_cnt;

    for(i=0; i < word_cnt; i++) {
        sum += ((EE_data[base] & 0xFF) + (EE_data[base] >> 8));
        ++base;
    }

    /* add byte following the LFSR checksum and end tag */
    sum = sum + 0xA + 0x79;
    if( (EE_data[crnt_word - 1] & 0xFF) == 0x79) {   /* end tag in low byte */
        sum = ~sum + 1;
        /* sum79 */
        i = (sum << 8) ^ 0x79;
        /* put sum in high byte of prev word */
        EE_data[crnt_word - 1] =  i;
    }
    else { /* assume end tag in high byte of prev word */
        /* add the low byte */
        sum = sum + (EE_data[crnt_word - 1] & 0xFF);
        sum = ~sum + 1;
        /* put in low byte of crnt word -- pad with 00 in hb */
        EE_data[crnt_word] = sum & 0xFF;
        blocks[blk_count - 1].w_count += 1;
        ++crnt_word;
    }
}






/* Word_Chksum Routine
 * Returns a checksum word based on all 16-bit words in a block of data.
 */
static u16 word_chksum (u16 base, u16 word_cnt)
{
    u16 i, sum = 0;

    for(i=0; i < word_cnt; i++)
        sum += EE_data[base++];
    return (sum = ~sum + 1);
}




/* LFSR_Chksum Routine
 * Returns 8-bit Linear Feedback Shift Register checksum on all bytes in a block of 16-bit
 * words.  Words are assumed to be organized little-endian.
 */
static u8 LFSR_chksum(u16 base, u16 word_cnt)
{
    u8 LFSR, byte_ctr, bits, XORvalue, byte, i, j = 0;
    u8 bytes[MAX_VECTOR];

    for(i=0; i < word_cnt; i++) {
        /* convert words to byte stream */
        bytes[j++] = (u8)(EE_data[base]  & 0xFF);
        bytes[j++] = (u8)(EE_data[base++] >> 8);
    }
    LFSR = 0x6A;

    /* adjust word count to bytes */
    word_cnt = word_cnt << 1;
    for (byte_ctr = 0; byte_ctr < word_cnt; byte_ctr++) {
        byte = bytes[byte_ctr];
        for (bits = 0; bits < 8; bits++) {
            XORvalue = ( (LFSR & 3 ) == 1 || (LFSR & 3) == 2) ?  1 : 0;
            LFSR = LFSR >> 1;
            if (XORvalue ^ (byte & 1))
                LFSR |= 0x80;
            byte = byte >> 1;
        }
    }
    return(LFSR);
}


/* read_ia
 *
 * reads the individual address from the eeprom
 * and stores it in the global variable  ia_word
*/

void read_ia( void )
{
	ia_word[0] = byte_swap ( readEE(blocks[blk_count - 1].ee_addr + blocks[blk_count - 1].w_count) );
	ia_word[1] = byte_swap ( readEE(blocks[blk_count - 1].ee_addr + blocks[blk_count - 1].w_count + 1));
	ia_word[2] = byte_swap ( readEE(blocks[blk_count - 1].ee_addr + blocks[blk_count - 1].w_count + 2));
}

/*
 * read_sn
 *
 * reads the serial number from the eeprom and stores
 * it in the global variable sn_word
*/
void read_sn ( void )
{
    sn_word[1] = readEE(blocks[blk_count - 1].ee_addr +
                        blocks[blk_count - 1].w_count);

    sn_word[0] = readEE(blocks[blk_count - 1].ee_addr +
                        blocks[blk_count - 1].w_count + 1);
}


void display_blocks(void)
{
    u16 i, EE_word, l;

    printf("\nReset Block:\n");
    for(i = 0; i < 0x1C; i++) {
        EE_word = readEE(i);
        printf("%4x ", EE_word);
    }
    printf("\n\nDriver Configuration Block:\n");
    for(i = 0x1C; i < 0x30; i++) {
        EE_word = readEE(i);
        printf("%4x ", EE_word);
    }
    if ( crnt_word < 0x41 ) {
        printf("\n\nProduct Code and Serial No:\n");
        l = 0x40;
    }
    else {
        printf("\n\nPlug and Play Resource Data:\n");
        l = 0x80;
    }
    for(i = 0x30; i < l; i++) {
        EE_word = readEE(i);
        printf("%4x ", EE_word);
    }

    read_ia();
    read_sn();

    printf("\n\aThe EEPROM was programmed with the above data.\n\n");
    printf("Label the board with:\n");
    printf("IA = %4x%4x%4x, \n", ia_word[0], ia_word[1], ia_word[2]);
    printf("SN = %4x%4x\n", sn_word[0], sn_word[1]);
}

int cmd_eeprom(int argc, char *argv[])
{
    if (!scan_for_8900())
        return -1;

    if (!init())
        return -1;

    if (0) {
        burn_it();
    }

    display_blocks();

    return 0;
}


/*
 * Local Variables:
 * indent-tabs-mode:nil
 * c-basic-offset:4
 * End:
*/

