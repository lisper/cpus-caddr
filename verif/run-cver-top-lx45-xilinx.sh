#!/bin/sh

PLI=+loadvpi=../pli/mmc/pli_mmc.so:vpi_compat_bootstrap
XV=/opt/Xilinx/14.4/ISE_DS/ISE/verilog/src
ISE=../ise-lx45
RTL=../rtl

#$ISE/ipcore_dir/mig_32bit/user_design/rtl/mcb_controller/iodrp_mcb_controller.v
#$ISE/ipcore_dir/mig_32bit/user_design/rtl/mcb_controller/iodrp_controller.v
#$ISE/ipcore_dir/mig_32bit/user_design/rtl/mcb_controller/mcb_soft_calibration.v \
#$ISE/ipcore_dir/mig_32bit/user_design/rtl/mcb_controller/mcb_soft_calibration_top.v \
#$ISE/ipcore_dir/mig_32bit/user_design/rtl/mcb_controller/mcb_raw_wrapper.v \
#$ISE/ipcore_dir/mig_32bit/user_design/rtl/mcb_controller/mcb_ui_top.v \
#

FILES="\
$RTL/scancode_rom.v \
$RTL/xbus-unibus.v \
$RTL/xbus-tv.v \
$RTL/xbus-ram.v \
$RTL/xbus-io.v \
$RTL/xbus-disk.v \
$RTL/scancode_convert.v \
$RTL/ps2_send.v \
$RTL/ps2.v \
$ISE/ipcore_dir/mig_32bit/user_design/rtl/memc_wrapper.v \
$ISE/ipcore_dir/mig_32bit/user_design/rtl/infrastructure.v \
$ISE/ipcore_dir/ise_32x32_dpram.v \
$ISE/ipcore_dir/ise_32x19_dpram.v \
$ISE/ipcore_dir/ise_2kx5_dpram.v \
$ISE/ipcore_dir/ise_2kx17_dpram.v \
$ISE/ipcore_dir/ise_21kx32_dpram.v \
$ISE/ipcore_dir/ise_1kx32_dpram.v \
$ISE/ipcore_dir/ise_1kx24_dpram.v \
$ISE/ipcore_dir/ise_16kx49ram.v \
$RTL/rom.v \
$RTL/prom.v \
$RTL/part_32x32ram.v \
$RTL/part_32x19ram.v \
$RTL/part_2kx5ram.v \
$RTL/part_2kx17ram.v \
$RTL/part_21kx32ram.v \
$RTL/part_1kx32ram_p.v \
$RTL/part_1kx32ram_a.v \
$RTL/part_1kx24ram.v \
$RTL/part_16kx49ram.v \
$RTL/mouse.v \
$RTL/mmc.v \
$RTL/lpddr.v \
$RTL/keyboard.v \
$RTL/busint.v \
$RTL/74182.v \
$RTL/74181.v \
$RTL/vga_display.v \
$RTL/support.v \
$RTL/spy.v \
$RTL/ps2_support.v \
$RTL/mmc_block_dev.v \
$RTL/lx45_ram_controller.v \
$RTL/lx45_clocks.v \
$RTL/caddr.v \
$RTL/top_lx45.v \
$ISE/ipcore_dir/mig_32bit/user_design/sim/lpddr_model_c3.v \
$XV/XilinxCoreLib/BLK_MEM_GEN_V7_3.v \
$XV/unisims/BUFPLL.v \
run_top_lx45_test.v \
o$XV/glbl.v"

#cver $PLI +incdir+../rtl run_top_lx45_test.v
cver $PLI +incdir+../rtl +incdir+$ISE/ipcore_dir/mig_32bit/user_design/sim $FILES

