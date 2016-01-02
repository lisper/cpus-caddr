#!/bin/sh

export PATH=$PATH:/opt/Xilinx/14.4/ISE_DS/ISE/bin/lin

UCF=/files/code/cpus/caddr/pipistrello/pipistrello_v2.01.ucf

#cd ise
xst -intstyle ise -ifn "/files/code/cpus/caddr/niox/ise/top_niox.xst" -ofn "/files/code/cpus/caddr/niox/ise/top_niox.syr" && \
ngdbuild -intstyle ise -dd _ngo -sd ../../ise-lx45/ipcore_dir -nt timestamp -uc $UCF -p xc6slx45-csg324-3 top_niox.ngc top_niox.ngd   && \
map -intstyle ise -p xc6slx45-csg324-3 -w -logic_opt off -ol high -t 1 -xt 0 -register_duplication off -r 4 -global_opt off -mt off -ir off -pr off -lc off -power off -o top_niox_map.ncd top_niox.ngd top_niox.pcf  && \
par -w -intstyle ise -ol high -mt off top_niox_map.ncd top_niox.ncd top_niox.pcf  && \
trce -intstyle ise -v 3 -s 3 -n 3 -fastpaths -xml top_niox.twx top_niox.ncd -o top_niox.twr top_niox.pcf  && \
bitgen -intstyle ise -f top_niox.ut top_niox.ncd 
