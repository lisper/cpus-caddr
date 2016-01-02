#!/bin/sh -e

BASE=/opt/Xilinx/14.4/ISE_DS
#BASE=/opt/Xilinx/14.5/ISE_DS

export PATH=$PATH:$BASE/ISE/bin/lin

. $BASE/settings32.sh

cd /files/code/cpus/caddr/niox/ise/

#T="-timescale 1ns/1ns -override_timeunit -override_timeprecision"
#D="-d SIMULATION=1 -d FAKE_SDRAM=1"

T="-timescale 1ps/1ps -override_timeunit -override_timeprecision"
D="-d SIMULATION=1"

#I="-incremental"


fuse $D $T $I -i "/files/code/cpus/caddr/niox/verif" -lib "unisims_ver" -lib "unimacro_ver" -lib "xilinxcorelib_ver" -lib "secureip" -o "/files/code/cpus/caddr/niox/ise/top_niox_tb_isim_beh.exe" -prj "/files/code/cpus/caddr/niox/ise/top_niox_tb_beh.prj" "work.top_niox_tb" "work.glbl" && \
LD_PRELOAD=./preload.so ./top_niox_tb_isim_beh.exe -intstyle ise -gui -tclbatch isim.cmd -wdb ./top_niox_tb_isim_beh.wdb  -view ../verif/isim.wcfg

exit 0

#LD_PRELOAD=./preload.so ./top_niox_tb_isim_beh.exe -intstyle ise -gui -tclbatch isim.cmd -wdb ./top_niox_tb_isim_beh.wdb  -view ../verif/isim.wcfg

