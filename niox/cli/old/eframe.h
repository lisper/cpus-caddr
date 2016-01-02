/*
 * eframe.h
 */

#define CF_ADDR		0x20000000
#define CPLD_ADDR	0x30000000

/* CPLD */
#define CPLD_RESET_CTRL_BITS	(CPLD_ADDR + 0x00)
#define CPLD_SET_CTRL_BITS	(CPLD_ADDR + 0x04)
#define CPLD_RESET_INT_BITS	(CPLD_ADDR + 0x08)
#define CPLD_SET_INT_BITS	(CPLD_ADDR + 0x0c)
#define CPLD_RESET_ACK_BITS	(CPLD_ADDR + 0x10)
#define CPLD_SET_ACK_BITS	(CPLD_ADDR + 0x14)
#define CPLD_READ_TOUCH		(CPLD_ADDR + 0x18)

/* high byte of cpld reg read */
#define CPLD_CTRL_FLASH_READY	0x8000
#define CPLD_CTRL_CF_CD		0x4000
#define CPLD_CTRL_CF_WAIT	0x2000
#define CPLD_CTRL_MMC_CD	0x1000
#define CPLD_CTRL_MMC_WP	0x0800
#define CPLD_CTRL_EXP_INT_1	0x0400
#define CPLD_CTRL_EXP_INT_2	0x0200
#define CPLD_CTRL_EXP_INT_3	0x0100

/* low byte bits of cpld reg read */
#define CPLD_CTRL_LCDPWR_BIT	  0
#define CPLD_CTRL_BACKLIGHT_BIT	  1
#define CPLD_CTRL_LCD_OE_BIT	  2
#define CPLD_CTRL_PCMCIA_PWR1_BIT 3
#define CPLD_CTRL_PCMCIA_PWR2_BIT 4
#define CPLD_CTRL_CF_RESET_BIT	  5

#define CPLD_CTRL_LCDPWR	(1 << CPLD_CTRL_LCDPWR_BIT)
#define CPLD_CTRL_BACKLIGHT	(1 << CPLD_CTRL_BACKLIGHT_BIT)
#define CPLD_CTRL_LCD_OE	(1 << CPLD_CTRL_LCD_OE_BIT)
#define CPLD_CTRL_PCMCIA_PWR1	(1 << CPLD_CTRL_PCMCIA_PWR1_BIT)
#define CPLD_CTRL_PCMCIA_PWR2	(1 << CPLD_CTRL_PCMCIA_PWR2_BIT)
#define CPLD_CTRL_CF_RESET	(1 << CPLD_CTRL_CF_RESET_BIT)

/* low byte of cpld int reg read */
#define CPLD_INT_EXP_3_IRQ	0x0040
#define CPLD_INT_EXP_2_IRQ	0x0020
#define CPLD_INT_EXP_1_IRQ	0x0010
#define CPLD_INT_CF_IRQ		0x0008
#define CPLD_INT_MMC_CD_IRQ	0x0004
#define CPLD_INT_PCMCIA_CD_IRQ	0x0002
#define CPLD_INT_CF_CD_IRQ	0x0001

/* expansion board (expbrd) config register */
#define EXPBRD_REG_ADDR 0x70000000 

#define EXB_REG_AC96_PWR_EN	0x2000
#define EXB_REG_USB_PULLUP	0x1000
#define EXB_REG_RTS3		0x0800
#define EXB_REG_DTR3		0x0400
#define EXB_REG_RTS2		0x0200
#define EXB_REG_DTR2		0x0100

/* pcmcia status */
#define PCMCIA_STAT_PC1_BVD1	0x0001
#define PCMCIA_STAT_PC1_BVD2	0x0002
#define PCMCIA_STAT_NPC_VS1	0x0004
#define PCMCIA_STAT_NPC_VS2	0x0008
#define PCMCIA_STAT_PC1_CD	0x0010
#define PCMCIA_STAT_CONF_SW2	0x0020
#define PCMCIA_STAT_CONF_SW3	0x0040
#define PCMCIA_STAT_CONF_SW4	0x0080

/* GPIO's */
/*
  pa0 exp conn
  pa1 exp conn
  pa2 exp conn

  pa3 ri2
  pa4 ri3
  pa5 cf_reset
  pa6 flash_rdy

  pa7 exp conn

  pb6 exp conn
  pb7 exp conn

  pf0 cf_cd1
  pf1 cpld_irq
 */
#define GPIO_PA5_CF_RESET_BIT	5
#define GPIO_PA6_FLASH_RDY_BIT	6
#define GPIO_PF0_CF_CD1_BIT	0
#define GPIO_PF1_CPLD_IRQ_BIT	1

/*
CPLD Interrupt register bits, reset/set
 0 cf cd
 1 pcmcia cd
 2 mmc cd
 3 cf int
 4 exp int #1
 5 exp int #2
 6 exp int #3
*/
#define CPLD_INT_CF_CD		0x01
#define CPLD_INT_PCMCIA_CD	0x02
#define CPLD_INT_MMC_CD		0x04
#define CPLD_INT_CF_INT		0x08
#define CPLD_INT_EXT_INT_1	0x10
#define CPLD_INT_EXT_INT_2	0x20
#define CPLD_INT_EXT_INT_3	0x40
