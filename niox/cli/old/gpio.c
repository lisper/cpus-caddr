/*
 * gpio.c
 */

#include "diag.h"
#include "lh7a400.h"
#include "eframe.h"
#include "cs8900.h"

int
cmd_gpio(int argc, char *argv[])
{
    gpioRegs_t *g = (gpioRegs_t *)0x80000e00;

    printf("gpios:\n");

    printf("pfdr %08x\n", g->pfdr);

    if (g->pfdr & (1 << GPIO_PF0_CF_CD1_BIT))
        printf("CF_CD1 ");
    if (g->pfdr & (1 << GPIO_PF1_CPLD_IRQ_BIT))
        printf("CPLD_IRQ ");

    if (g->padr & (1 << GPIO_PA6_FLASH_RDY_BIT))
        printf("FLASH_RDY ");
    if (g->padr & (1 << GPIO_PA5_CF_RESET_BIT))
        printf("CF_RESET ");

    printf("\n");
    return 0;
}



/*
 * Local Variables:
 * indent-tabs-mode:nil
 * c-basic-offset:4
 * End:
*/
