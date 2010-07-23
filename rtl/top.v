/*
 */

module top(rs232_txd, rs232_rxd,
	   button, led, sysclk,
	   sevenseg, sevenseg_an,
	   slideswitch,
	   sram_a, sram_oe_n, sram_we_n,
	   sram1_io, sram1_ce_n, sram1_ub_n, sram1_lb_n,
	   sram2_io, sram2_ce_n, sram2_ub_n, sram2_lb_n,
	   ide_data_bus, ide_dior, ide_diow, ide_cs, ide_da);

   input	rs232_rxd;
   output	rs232_txd;

   input [3:0] 	button;

   output [7:0] led;
   input 	sysclk;

   output [7:0] sevenseg;
   output [3:0] sevenseg_an;

   input [7:0] 	slideswitch;

   output [17:0] sram_a;
   output 	 sram_oe_n;
   output 	 sram_we_n;

   inout [15:0]	 sram1_io;
   output 	 sram1_ce_n;
   output 	 sram1_ub_n;
   output 	 sram1_lb_n;

   inout [15:0]	 sram2_io;
   output 	 sram2_ce_n;
   output 	 sram2_ub_n;
   output 	 sram2_lb_n;
   
   inout [15:0]  ide_data_bus;
   wire [15:0] 	 ide_data_in;
   wire [15:0] 	 ide_data_out;
   output 	 ide_dior;
   output 	 ide_diow;
   output [1:0]  ide_cs;
   output [2:0]  ide_da;

   // -----------------------------------------------------------------

   wire 	 clk;
   wire 	 reset;
   wire 	 interrupt;
   wire		 boot;

   wire [15:0] 	 spy_in;
   wire [15:0] 	 spy_out;
   wire 	 dbread, dbwrite;
   wire [3:0] 	 eadr;
   wire 	 halt;
   
   support support(.sysclk(sysclk),
		   .clk(clk),
		   .reset(reset),
		   .interrupt(interrupt),
		   .boot(boot),
		   .halt(halt));
   
   caddr cpu (.clk(clk),
	      .ext_int(interrupt),
	      .ext_reset(reset),
	      .ext_boot(boot),
	      .ext_halt(halt),
	      .spy_in(spy_in),
	      .spy_out(spy_out),
	      .dbread(dbread),
	      .dbwrite(dbwrite),
	      .eadr(eadr),
	      .ide_data_in(ide_data_in),
	      .ide_data_out(ide_data_out),
	      .ide_dior(ide_dior),
	      .ide_diow(ide_diow),
	      .ide_cs(ide_cs),
	      .ide_da(ide_da));

   assign ide_data_bus = ide_diow ? ide_data_out : 16'bz;
   assign ide_data_in = ide_data_bus;
   
   assign      eadr = 4'b0;
   assign      dbread = 0;
   assign      dbwrite = 0;

endmodule
