#!/bin/sh

cver +loadvpi=../pli/mmc/pli_mmc.so:vpi_compat_bootstrap +incdir+../rtl run-mmc.v
