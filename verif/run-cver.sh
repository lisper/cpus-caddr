
PLI=+loadvpi=../pli/ide/pli_ide.so:vpi_compat_bootstrap

#cver $PLI +cycles=40 +patch=patch-rw-vram.mem run.v
#cver $PLI +cycles=70 +patch=patch-rw-dram.mem run.v

#cver $PLI +cycles=70 +patch=patch.mem run.v

cver $PLI +cycles=6000 +incdir+../rtl run.v

