#!/bin/sh

PLI=+loadvpi=../../pli/mmc/pli_mmc.so:vpi_compat_bootstrap
#cver $PLI +incdir+../rtl run-top-spy.v

echo -n >run.vc
echo "+define+SIMULATION" >>run.vc
echo "+define+debug" >>run.vc
echo "+incdir+." >>run.vc
echo "+incdir+../rtl" >>run.vc
echo "top_niox_tb.v" >>run.vc
echo "../rtl/top_niox.v" >>run.vc
echo "../rtl/niox_cpu.v" >>run.vc
echo "../rtl/niox_ram.v" >>run.vc
echo "../rtl/niox_rom.v" >>run.vc
echo "../rtl/niox_spy.v" >>run.vc
echo "../../rtl/lx45_ram_controller.v" >>run.vc
echo "../../rtl/vga_display.v" >>run.vc
echo "../../rtl/support.v" >>run.vc
echo "../../rtl/mmc_block_dev.v" >>run.vc
echo "../../rtl/mmc.v" >>run.vc
echo "../../rtl/ps2_support.v" >>run.vc
echo "../../rtl/ps2.v" >>run.vc
echo "../../rtl/ps2_send.v" >>run.vc
echo "../../rtl/scancode_convert.v" >>run.vc
echo "../../rtl/scancode_rom.v" >>run.vc
echo "../../rtl/keyboard.v" >>run.vc
echo "../../rtl/mouse.v" >>run.vc
echo "../../rtl/busint.v" >>run.vc
echo "../../rtl/xbus-ram.v" >>run.vc
echo "../../rtl/xbus-disk.v" >>run.vc
echo "../../rtl/xbus-tv.v" >>run.vc
echo "../../rtl/xbus-io.v" >>run.vc
echo "../../rtl/xbus-unibus.v" >>run.vc
echo "../../rtl/xbus-spy.v" >>run.vc
echo "xilinx.v" >>run.vc
echo "../../rtl/part_21kx32ram.v" >>run.vc
echo "+incdir+../../../niox/core" >>run.vc
echo "../../../niox/core/niox_alu.v" >>run.vc
echo "../../../niox/core/niox_barrel.v" >>run.vc
echo "../../../niox/core/niox_ctrl_reg.v" >>run.vc
echo "../../../niox/core/niox_defines.v" >>run.vc
echo "../../../niox/core/niox_reg32.v" >>run.vc
echo "../../../niox/core/niox_regs.v" >>run.vc
echo "../../../niox/core/niox.v" >>run.vc

#cver -f run.vc
cver $PLI -f run.vc


