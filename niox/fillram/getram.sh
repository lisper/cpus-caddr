#!/bin/sh

BASE=/opt/Xilinx/14.4/ISE_DS/ISE/bin/lin

NGC=../ise/top_niox.ngc
#NGC=./top_niox.ngc
OUT=./top_niox.edf

rm -f $OUT
$BASE/ngc2edif $NGC $OUT
