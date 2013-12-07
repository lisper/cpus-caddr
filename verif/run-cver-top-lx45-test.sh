
PLI=+loadvpi=../pli/mmc/pli_mmc.so:vpi_compat_bootstrap

cver $PLI +incdir+../rtl run_top_lx45_test.v

