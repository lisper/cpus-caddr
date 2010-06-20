/*
 */

//`define debug_vcd

`include "rtl.v"

`timescale 1ns / 1ns

module wrap_ide(clk, ide_data_in, ide_data_out, ide_dior, ide_diow, ide_cs, ide_da);

   input clk;
   input [15:0] ide_data_in;
   output [15:0] ide_data_out;
   input 	 ide_dior;
   input 	 ide_diow;
   input [1:0] 	 ide_cs;
   input [2:0] 	 ide_da;
		
   import "DPI-C" function void dpi_ide(input integer data_in,
					output integer data_out,
				        input integer dior,
				        input integer diow,
				        input integer cs,
				        input integer da);

   integer dbi, dbo;
   wire [31:0] dboo;
      
   assign dbi = {16'b0, ide_data_in};
   assign dboo = dbo;

   assign ide_data_out = dboo[15:0];

   always @(posedge clk)
     begin
	dpi_ide(dbi,
		dbo,
		{31'b0, ide_dior}, 
		{31'b0, ide_diow},
		{30'b0, ide_cs},
		{29'b0, ide_da});

//	if (ide_dior == 0)
//	  $display("wrap_ide: read (%b %b) %x %x", ide_dior, ide_diow, dbo, ide_data_out);
     end

endmodule

module test;
   reg clk;
   reg reset;
   reg interrupt;

   // controlled by rc circuit at power up
   reg boot;

   wire [15:0] spy;
   wire        dbread, dbwrite;
   wire [3:0]  eadr;

   wire [15:0] 	ide_data_bus;
   wire 	ide_dior;
   wire 	ide_diow;
   wire [1:0] 	ide_cs;
   wire [2:0] 	ide_da;

   wire 	halt;
   
   caddr cpu (.clk(clk),
	      .ext_int(interrupt),
	      .ext_reset(reset),
	      .ext_boot(boot),
	      .ext_halt(halt),
	      .spy(spy),
	      .dbread(dbread),
	      .dbwrite(dbwrite),
	      .eadr(eadr),
	      .ide_data_bus(ide_data_bus),
	      .ide_dior(ide_dior),
	      .ide_diow(ide_diow),
	      .ide_cs(ide_cs),
	      .ide_da(ide_da));

   assign 	halt = 0;
   
   integer     addr;
   integer     debug_level;
   integer     dumping;
   integer     cycles;
   integer     max_cycles;
     
   assign      eadr = 4'b0;
   assign      dbread = 0;
   assign      dbwrite = 0;

   wire [15:0] ide_data_in;
   wire [15:0] ide_data_out;
   assign ide_data_bus = ~ide_dior ? ide_data_out : 16'bz;
   assign ide_data_in = ide_data_bus;

   wrap_ide wrap_ide(.clk(clk),
		     .ide_data_in(ide_data_in),
		     .ide_data_out(ide_data_out),
		     .ide_dior(ide_dior),
		     .ide_diow(ide_diow),
		     .ide_cs(ide_cs),
		     .ide_da(ide_da));
   
endmodule
