`timescale 1ns / 1ns

//`define debug
`define NEW_BUSINT

//`define QUARTUS
//`define ISE
`define SIMULATION

`ifdef ISE
 `define ISE_OR_SIMULATION
`endif

`ifdef SIMULATION
 `define ISE_OR_SIMULATION
`endif

`define use_new
//`define use_mid

`ifdef use_new
`include "../rtl/caddr.v"
`include "../rtl/74181.v"
`include "../rtl/74182.v"
//`include "../rtl/memory.v"
`include "../rtl/prom.v"
`include "../rtl/rom.v"
//`include "debug_rom.v"

`include "../rtl/ram_controller.v"
`include "../rtl/fast_ram_controller.v"
`include "../verif/debug_ram_controller.v"
`include "../rtl/vga_display.v"

`include "../rtl/busint.v"
`include "../rtl/xbus-ram.v"
//`include "debug-xbus-ram.v"
`include "../rtl/xbus-disk.v"
`include "../rtl/xbus-tv.v"
//`include "debug-xbus-tv.v"
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
`endif // unmatched `else or `endif

`ifdef use_mid
`include "../rtl.mid/caddr.v"
`include "../rtl.mid/74181.v"
`include "../rtl.mid/74182.v"
//`include "../rtl/memory.v"
`include "../rtl.mid/rom.v"

`include "../rtl.mid/busint.v"
`include "../rtl.mid/xbus-ram.v"
`include "../rtl.mid/xbus-disk.v"
`include "../rtl.mid/xbus-tv.v"
`include "../rtl.mid/xbus-io.v"
`include "../rtl.mid/xbus-unibus.v"

`include "../rtl.mid/ide.v"
  
`include "../rtl/part_1kx32ram_a.v"
`include "../rtl/part_1kx32ram.v"
`include "../rtl/part_32x19ram.v"
`include "../rtl/part_1kx24ram.v"
`include "../rtl/part_2kx17ram.v"
`include "../rtl/part_32x32ram.v"
`include "../rtl/part_2kx5ram.v"
`include "../rtl/part_16kx49ram.v"
`endif
