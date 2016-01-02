/*
 * touch.c
 *
 * $Id: touch.c,v 1.1 2005/03/10 14:07:05 brad Exp $
 */

#include "diag.h"
#include "lh7a400.h"

#include "eframe.h"

int
get_cpld_touch(void)
{
	volatile u32 *cr = (volatile u32 *)CPLD_READ_TOUCH;
	return *cr;
}

int cmd_touch(int argc, char *argv[])
{
	int v;

	v = get_cpld_touch();
	printf("touch %x\n", v);

	return 0;
}


