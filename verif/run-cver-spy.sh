
PLI=+loadvpi=../pli/ide/pli_ide.so:vpi_compat_bootstrap

cver $PLI +incdir+../rtl run-top-spy.v

