/*
 * test disk controller
 */

`define debug
`define debug_state
`define debug_detail
`define debug_detail_delay
`define DBG_DLY #1
  
`include "../rtl/busint.v"
`include "../rtl/xbus-sram.v"
`include "../rtl/xbus-disk.v"
`include "../rtl/xbus-tv.v"
`include "../rtl/xbus-io.v"
`include "../rtl/xbus-unibus.v"
`include "../rtl/ide.v"

`timescale 1ns / 1ns

module test_busint;
   reg clk;
   reg reset;

   reg [21:0] addr;
   reg [31:0] busin;
   wire [31:0] busout;
   wire [15:0]  spyin;
   wire [15:0]  spyout;
   reg 	       req;
   wire        ack;
   reg 	       write;
   wire        load;
   wire        interrupt;

   wire [15:0] 	ide_data_bus;
   wire [15:0] 	ide_data_in;
   wire [15:0] 	ide_data_out;
   wire 	ide_dior;
   wire 	ide_diow;
   wire [1:0] 	ide_cs;
   wire [2:0] 	ide_da;

   busint busint(.mclk(clk),
		 .reset(reset),
		 .addr(addr),
		 .busin(busin),
		 .busout(busout),
		 .spyin(spyin),
		 .spyout(spyout), 
		 .req(req),
		 .ack(ack),
		 .write(write), 
		 .load(load),
		 .interrupt(interrupt),

		 .ide_data_in(ide_data_in),
		 .ide_data_out(ide_data_out),
		 .ide_dior(ide_dior),
		 .ide_diow(ide_diow),
		 .ide_cs(ide_cs),
		 .ide_da(ide_da)
		 );


   task wait_for_bi_done;
      begin
	 while (ack == 1'b0) @(posedge clk);
	 @(posedge clk);
      end

   endtask

   task bus_read;
      input [21:0] a;

      begin
	 @(posedge clk);
	 write = 0;
 	 req = 1;
	 addr = a;
	 wait_for_bi_done;
	 $display("read: addr %o in %x out %x, %t",
		  addr, busin, busout, $time);
	 req = 0;
	 @(posedge clk);
      end
   endtask

   task bus_write;
      input [21:0] a;
      input [31:0] data;

      begin
	 @(posedge clk);
	 write = 1;
	 addr = a;
	 busin = data;
 	 req = 1;
	 $display("write: addr %o in %x out %x, %t",
		  addr, busin, busout, $time);
	 wait_for_bi_done;
	 req = 0;
	 @(posedge clk);
      end
   endtask

   initial
     begin
	$timeformat(-9, 0, "ns", 7);
	$dumpfile("run-disk.vcd");
	$dumpvars(0, test_busint);
     end

   initial
     begin
	test_busint.busint.disk.debug = 1;
	test_busint.busint.dram.debug = 1;
	
	clk = 0;
	reset = 0;
	req = 0;
	write = 0;

	#1 reset = 1;
	#500 reset = 0;

	bus_write(22'o22, 32'o1001);
	#100 bus_write(22'o23, 32'o4000);

	bus_read(22'o17377774);
	bus_read(22'o17377774);
	bus_read(22'o17377774);
	bus_write(22'o17377775, 32'o22);
	bus_write(22'o17377777, 32'o0);

	#1000000 $finish;
     end

   always
     begin
	#20 clk = 0;
	#20 clk = 1;
     end

   // ide
   assign ide_data_bus = ~ide_diow ? ide_data_out : 16'bz;

   assign ide_data_in = ide_data_bus;
     
   always @(posedge clk)
     begin
	$pli_ide(ide_data_bus, ide_dior, ide_diow, ide_cs, ide_da);
     end

endmodule // test
