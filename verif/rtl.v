//
// define rtl for simulation runs
//

// // // `timescale 1ns / 1ns

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
//`define build_test

//
// build_fpga
//
`ifdef build_fpga
 `define use_ram_controller   
 `define slow_rc
 `define use_s3board_ram
 `define use_vga_controller
 `define build_debug_or_fpga
`endif

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
// `define slow_rc
 `define pipe_rc
// `define debug_rc
// `define debug_md
// `define debug_vma
// `define debug_dispatch
 `define debug_patch_rom
// `define debug_patch_disk_copy
 `define use_s3board_ram
 `define use_vga_controller
 `define build_debug_or_fpga
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
// `define debug_with_usim_delay
// `define debug_with_usim
 `define debug_patch_rom
 `define debug_patch_disk_copy
// `define use_iologger
`endif // build_test

//
// rtl
//
`include "../rtl/caddr.v"
`include "../rtl/74181.v"
`include "../rtl/74182.v"

`include "../rtl/prom.v"
`include "../rtl/rom.v"
//`include "debug_rom.v"

`ifdef fast_rc
 `include "../rtl/fast_ram_controller.v"
`endif

`ifdef slow_rc
 `include "../rtl/slow_ram_controller.v"
`endif

`ifdef debug_rc
 `include "debug_ram_controller.v"
`endif

`ifdef min_rc
 `include "min_ram_controller.v"
`endif

`ifdef pipe_rc
 `include "../rtl/pipe_ram_controller.v"
`endif

`ifdef build_debug_or_fpga
 `include "../rtl/vga_display.v"
`endif

`include "../rtl/busint.v"

`ifdef build_debug_or_fpga
 `include "../rtl/xbus-ram.v"
`else
 `include "../rtl/xbus-sram.v"
`endif
  
`include "../rtl/xbus-disk.v"
//`include "debug-xbus-disk.v"


`ifdef build_test
 `include "debug-xbus-tv.v"
`else
 `include "../rtl/xbus-tv.v"
`endif

`include "../rtl/xbus-io.v"
`include "../rtl/xbus-unibus.v"
`include "../rtl/ide.v"
`include "../rtl/ps2_support.v"
`include "../rtl/ps2.v"
`include "../rtl/ps2_send.v"
`include "../rtl/keyboard.v"
`include "../rtl/mouse.v"
`include "../rtl/scancode_convert.v"
`include "../rtl/scancode_rom.v"

`include "../rtl/part_1kx32ram_a.v"
`include "../rtl/part_1kx32ram_p.v"
`include "../rtl/part_32x19ram.v"
`include "../rtl/part_1kx24ram.v"
`include "../rtl/part_2kx17ram.v"
`include "../rtl/part_32x32ram.v"
`include "../rtl/part_2kx5ram.v"

`ifdef use_ucode_ram
 `include "../rtl/part_16kx49ram.v"
`endif
