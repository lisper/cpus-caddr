`timescale 1ns / 1ns

//`define QUARTUS
//`define ISE
`define SIMULATION

`ifdef ISE
 `define ISE_OR_SIMULATION
`endif

`ifdef SIMULATION
 `define ISE_OR_SIMULATION
`endif

//`define build_fpga
//`define build_debug
`define build_test

//
// build_fpga
//
`ifdef build_fpga
`define use_ram_controller   
`define use_s3board_ram
`define use_vga_controller

`include "../rtl2/caddr.v"
`include "../rtl2/74181.v"
`include "../rtl2/74182.v"
`include "../rtl2/prom.v"
`include "../rtl2/rom.v"
`include "../rtl2/fast_ram_controller.v"
`include "../rtl2/vga_display.v"
`include "../rtl2/busint.v"
`include "../rtl2/xbus-ram.v"
`include "../rtl2/xbus-disk.v"
`include "../rtl2/xbus-tv.v"
`include "../rtl2/xbus-io.v"
`include "../rtl2/xbus-unibus.v"
`include "../rtl2/ide.v"

`include "../rtl2/part_1kx32ram_a.v"
`include "../rtl2/part_1kx32ram_p.v"
`include "../rtl2/part_32x19ram.v"
`include "../rtl2/part_1kx24ram.v"
`include "../rtl2/part_2kx17ram.v"
`include "../rtl2/part_32x32ram.v"
`include "../rtl2/part_2kx5ram.v"
`endif // build_fpga

//
// build_debug
//
// fpga+debug; for sim
// ram controller
// vga controller
//
`ifdef build_debug
`define debug
`define use_ram_controller   
`define use_s3board_ram
`define use_vga_controller

`include "../rtl2/caddr.v"
`include "../rtl2/74181.v"
`include "../rtl2/74182.v"
`include "../rtl2/prom.v"
`include "../rtl2/rom.v"
`include "../rtl2/fast_ram_controller.v"
`include "../rtl2/vga_display.v"

`include "../rtl2/busint.v"
`include "../rtl2/xbus-ram.v"
`include "../rtl2/xbus-disk.v"
`include "../rtl2/xbus-tv.v"
`include "../rtl2/xbus-io.v"
`include "../rtl2/xbus-unibus.v"
`include "../rtl2/ide.v"

`include "../rtl2/part_1kx32ram_a.v"
`include "../rtl2/part_1kx32ram_p.v"
`include "../rtl2/part_32x19ram.v"
`include "../rtl2/part_1kx24ram.v"
`include "../rtl2/part_2kx17ram.v"
`include "../rtl2/part_32x32ram.v"
`include "../rtl2/part_2kx5ram.v"
`endif // build_debug

//
// build_test
//
// no ram controller
// local ram for everything
// 1x clock
//
`ifdef build_test
`define use_ucode_ram
//`define debug_with_usim_delay
//`define debug_with_usim
`define patch_rom
`define patch_iram_copy
//`define use_iologger

`include "../rtl/caddr.v"

`include "../rtl/74181.v"
`include "../rtl/74182.v"

`include "../rtl/prom.v"
`include "../rtl/rom.v"
//`include "debug_rom.v"

`include "../rtl/busint.v"
`include "../rtl/xbus-sram.v"
`include "../rtl/xbus-disk.v"
//`include "debug-xbus-disk.v"
`include "debug-xbus-tv.v"

`include "../rtl/xbus-io.v"
`include "../rtl/xbus-unibus.v"
`include "../rtl/ide.v"

`include "../rtl/part_1kx32ram_a.v"
`include "../rtl/part_1kx32ram_p.v"
`include "../rtl/part_32x19ram.v"
`include "../rtl/part_1kx24ram.v"
`include "../rtl/part_2kx17ram.v"
`include "../rtl/part_32x32ram.v"
`include "../rtl/part_2kx5ram.v"
`include "../rtl/part_16kx49ram.v"
`endif // build_test
