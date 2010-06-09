/*
 */

`include "../rtl/busint.v"
`include "../rtl/xbus-ram.v"
`include "../rtl/xbus-disk.v"
`include "../rtl/xbus-tv.v"
`include "../rtl/xbus-io.v"
`include "../rtl/xbus-unibus.v"

`timescale 1ns / 1ns

module test_busint;
   reg clk;
   reg reset;

   reg [21:0] addr;
   reg [31:0] busin;
   wire [31:0] busout;
   wire [15:0]  spy;
   reg 	       req;
   wire        ack;
   reg 	       write;
   wire        load;
   wire        interrupt;
   
   busint bi(.mclk(clk),
	     .reset(reset),
	     .addr(addr),
	     .busin(busin),
	     .busout(busout),
	     .spy(spy), 
	     .req(req),
	     .ack(ack),
	     .write(write), 
	     .load(load),
	     .interrupt(interrupt));


   task wait_for_bi_done;
      begin
	 while (ack == 1'b0) #10;
	 #10;
      end

   endtask

   task bus_read;
      input [21:0] addr;

      begin
	 write = 0;
 	 req = 1;
	 wait_for_bi_done;
	 req = 0;
	 $display("read: addr %o in %x out %x", addr, busin, busout);
      end
   endtask

   task bus_write;
      input [21:0] addr;
      input [31:0] data;

      begin
	 write = 1;
	 busin = data;
 	 req = 1;
	 wait_for_bi_done;
	 req = 0;
	 $display("write: addr %o in %x out %x", addr, busin, busout);
      end
   endtask

   initial
     begin
	$timeformat(-9, 0, "ns", 7);
	$dumpfile("test_busint.vcd");
	$dumpvars(0, test_busint);
     end

   initial
     begin
	clk = 0;
	reset = 0;
	req = 0;
	write = 0;

	bus_read(22'o17377774);
	bus_write(22'o17377775, 0);
	$finish;
     end

   always
     begin
	#10 clk = 0;
	#10 clk = 1;
     end

endmodule // test
