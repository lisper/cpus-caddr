#include "svdpi.h"
#include "Vtest_top__Dpi.h"

#include <stdio.h>

#ifdef __cplusplus
extern "C" {
#endif

unsigned char ram_h[262144];
unsigned char ram_l[262144];

static int last_r;
static int last_w;

void dpi_ram (int a, int r, int w, int u, int l, int in, int* out)
{
	int o;
	int assert_r, assert_w;

	assert_r = r && !last_r;
	assert_w = w && !last_w;

	last_r = r;
	last_w = w;

	o = 0;
	if (r) {
		if (u) o |= ram_h[a] << 8;
		if (l) o |= ram_l[a];
		if (assert_r) printf("dpi_ram: read  [%o] -> %o\n", a, o);
	}
	*out = o;

	if (w) {
		if (u) ram_h[a] = in >> 8;
		if (l) ram_l[a] = in;
		if (assert_w) printf("dpi_ram: write  [%o] -> %o\n", a, in);
	}
}


#ifdef __cplusplus
}
#endif
