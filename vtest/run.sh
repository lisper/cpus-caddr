#!/bin/sh

#iverilog test_top.v && ./a.out
#exit 0

#../../pdp8/cver/gplcver-2.12a.src/bin/cver  \
#    +loadvpi=../pli/display/display.vpi:vpi_compat_bootstrap \
#    test_top.v
#exit 0

iverilog test_top.v  -m ../pli/display/display && ./a.out
exit 0

iverilog test_top.v  -m ../../imageProcessingVPI/display && ./a.out
exit 0

../../pdp8/cver/gplcver-2.12a.src/bin/cver  \
    +loadvpi=../../imageProcessingVPI/display.vpi:vlog_startup_routines \
    test_top.v

exit 0
