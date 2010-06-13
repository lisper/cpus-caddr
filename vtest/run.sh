#!/bin/sh

iverilog test_top.v  -m ../../imageProcessingVPI/display && ./a.out

exit 0

../../pdp8/cver/gplcver-2.12a.src/bin/cver  \
    +loadvpi=../../imageProcessingVPI/display.vpi:vlog_startup_routines \
    test_top.v

exit 0
