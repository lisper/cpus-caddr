// run_top_lx9_test.v
// fpga test bench

`timescale 1ns / 1ns

`ifdef __CVER__
`define debug
//`define waves
`define DBG_DLY #0
`define SIMULATION
`define debug_patch_rom
`define lx45_fake_sdram

`include "top_lx45.v"

//`include "top_tb.v"
//`include "cpu_test.v"
//`include "cpu_test_data.v"
//`include "cpu_test_mcr.v"
//`include "cpu_test_disk.v"

`include "caddr.v"
`include "../rtl/74181.v"
`include "../rtl/74182.v"

`include "../rtl/prom.v"
`include "../rtl/rom.v"

`include "lx45_ram_controller.v"
`include "vga_display.v"

`include "busint.v"
`include "xbus-ram.v"
`include "xbus-disk.v"
`include "xbus-tv.v"
`include "xbus-io.v"
`include "xbus-unibus.v"
`include "mmc_block_dev.v"
`include "mmc.v"
`include "ps2_support.v"
`include "ps2.v"
`include "ps2_send.v"
`include "keyboard.v"
`include "mouse.v"
`include "scancode_convert.v"
`include "scancode_rom.v"

`include "spy.v"

`include "../rtl/part_16kx49ram.v"
`include "../rtl/part_21kx32ram.v"
`include "../rtl/part_1kx32ram_a.v"
`include "../rtl/part_1kx32ram_p.v"
`include "../rtl/part_32x19ram.v"
`include "../rtl/part_1kx24ram.v"
`include "../rtl/part_2kx17ram.v"
`include "../rtl/part_32x32ram.v"
`include "../rtl/part_2kx5ram.v"

`include "support.v"
//`include "debug-support.v"

`include "fpga_clocks.v"

`include "xilinx.v"
`endif

//`include "mmc_disk.v"
   
module run_top;

   // Inputs
   reg rs232_rxd;
   reg 	     sysclk;
   reg 	     ps2_clk;
   reg 	     ps2_data;

   // Outputs
   wire      rs232_txd;
   wire [3:0] led;
   wire       vga_out;
   wire       vga_hsync;
   wire       vga_vsync;

   // Instantiate the Unit Under Test (UUT)
   top uut (
	    .rs232_txd(rs232_txd), 
	    .rs232_rxd(rs232_rxd), 
	    .led(led), 
	    .sysclk(sysclk), 
	    .ps2_clk(ps2_clk), 
	    .ps2_data(ps2_data), 
	    .ms_ps2_clk(),
	    .ms_ps2_data(),
	    .vga_out(vga_out), 
	    .vga_hsync(vga_hsync), 
	    .vga_vsync(vga_vsync),
	    .mmc_cs(mmc_cs),
	    .mmc_di(mmc_di),
	    .mmc_do(mmc_do),
	    .mmc_sclk(mmc_sclk)
	    );


//   mmc_disk mmc(
//		.mmc_cs(mmc_cs),
//		.mmc_di(mmc_di),
//		.mmc_do(mmc_do),
//		.mmc_sclk(mmc_sclk)
//		);

   initial begin
      // Initialize Inputs
      rs232_rxd = 0;
      sysclk = 0;
      ps2_clk = 0;
      ps2_data = 0;

      //uut.rc.debug = 1;
      //uut.rc.debug_mcr = 1;
      uut.cpu.busint.disk.debug = 1;

      // Wait 100 ns for global reset to finish
      #100;
   end
   
`ifdef waves
   initial
     begin
	$timeformat(-9, 0, "ns", 7);
	$dumpfile("run_top_lx45_test.vcd");
	$dumpvars(0, run_top);
     end
`endif
   
   initial
     begin
	#100000000; $finish;
     end
   
   // 50mhz clock
   always
     begin
	#10 sysclk = 0;
	#10 sysclk = 1;
     end

   always @(posedge sysclk)
     begin
	$pli_mmc(mmc_cs, mmc_sclk, mmc_di, mmc_do);
     end

   integer cycles, faults;

   initial
     begin
	cycles = 0;
	faults = 0;
     end
       
   always @(posedge uut.cpu.clk)
     begin
	if (uut.cpu.state == 6'b000001)
	  cycles = cycles + 1;
	
	if (uut.cpu.state == 6'b000001)
	  $display("%0o %o A=%x M=%x N%b MD=%x LC=%x",
		   uut.cpu.lpc, uut.cpu.ir, uut.cpu.a, uut.cpu.m, uut.cpu.n, uut.cpu.md, uut.cpu.lc);

	if (uut.cpu.lpc == 14'o26)
	  begin
	     faults = faults + 1;

	     if (faults > 5)
	       begin
		  $display("=== fault ===");
		  $finish;
	       end
	  end
     end
   
endmodule

