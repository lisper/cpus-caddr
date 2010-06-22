/*
 */

//`define debug_vcd
`define debug
`define DBG_DLY
  
`include "rtl.v"

`timescale 1ns / 1ns

module wrap_ide(clk, ide_data_in, ide_data_out,
		ide_dior, ide_diow, ide_cs, ide_da);

   input clk;
   input [15:0]  ide_data_in;
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

`ifdef debug_ide
	if (ide_dior == 0)
	  begin
	     $display("wrap_ide: read (%b %b) %x %x %x %x",
		      ide_dior, ide_diow, dbo, dboo, dboo[15:0], ide_data_out);
	  end
	if (ide_diow == 0)
	  begin
	     $display("wrap_ide: write (%b %b) %x %x %x",
		      ide_dior, ide_diow, dbo, dboo, ide_data_out);
	  end
`endif
     end

endmodule

module test;
   reg clk;
   reg reset;
   reg interrupt;

   // controlled by rc circuit at power up
   reg boot;

   reg [15:0]  spyin;
   wire [15:0] spyout;
   wire        dbread, dbwrite;
   wire [3:0]  eadr;

   wire [15:0] 	ide_data_in;
   wire [15:0] 	ide_data_out;
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
	      .spyin(spyin),
	      .spyout(spyout),
	      .dbread(dbread),
	      .dbwrite(dbwrite),
	      .eadr(eadr),
	      .ide_data_in(ide_data_in),
	      .ide_data_out(ide_data_out),
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
   assign      spyin = 0;

   wrap_ide wrap_ide(.clk(clk),
		     .ide_data_in(ide_data_out),
		     .ide_data_out(ide_data_in),
		     .ide_dior(ide_dior),
		     .ide_diow(ide_diow),
		     .ide_cs(ide_cs),
		     .ide_da(ide_da));
   
endmodule
