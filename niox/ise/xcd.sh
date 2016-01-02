#!/bin/sh

#BASE=/opt/Xilinx/14.4/ISE_DS
BASE=/opt/Xilinx/14.5/ISE_DS

export PATH=$PATH:$BASE/ISE/bin/lin

. $BASE/settings32.sh

#/files/code/xvcd/xvcd &

xilinx_xvc host=127.0.0.1:2542 disableversioncheck=true

