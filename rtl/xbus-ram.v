/*
 * $Id$
 */

`ifdef SIMULATON
 `define debug
`endif

module xbus_ram (
		 clk, reset,
		 addr, datain, dataout,
		 req, write, ack, decode,

		 sdram_addr, sdram_data_in, sdram_data_out,
		 sdram_req, sdram_ready, sdram_write, sdram_done
		);

   input reset;
   input clk;
   input [21:0] addr;
   input [31:0] datain;
   input 	req;
   input 	write;
   
   output [31:0] dataout;
   output 	 ack;
   output 	 decode;

   output [21:0]  sdram_addr;
   output [31:0] sdram_data_out;
   input [31:0]  sdram_data_in;
   output 	 sdram_req;
   input 	 sdram_ready;
   output 	 sdram_write;
   input 	 sdram_done;

`ifdef debug
   integer debug;
   integer debug_decode;

   initial
     begin
	debug = 0;
	debug_decode = 0;
     end
`endif
   
   // need some dram address space at the end 
   // which is decoded but does not read/write...
   assign 	 decode = addr < 22'o11000000 ? 1'b1: 1'b0;

`ifdef debug
   always @(posedge clk)
     if (decode && debug_decode != 0)
       $display("xbus-ram: decode addr=%o; %t", addr, $time);
`endif
   
   /* connect to top level ram controller */
   assign sdram_write = req & decode & write;
   assign sdram_req = req & decode & ~write;
   
   assign ack = (sdram_write && sdram_done) || (sdram_req && sdram_ready);

   assign sdram_addr = addr;
   assign sdram_data_out = datain;
   assign dataout = sdram_data_in;

`ifdef debug
   always @(posedge clk)
     if ((sdram_req || sdram_write) && debug_decode != 0)
       begin
	  $display("xbus-ram: sdram decode req %b%b addr=%o; datain=%o dataout=%o %t",
		   sdram_req, sdram_write, addr, datain, dataout, $time);
       end
`endif

`ifdef debug
   always @(posedge clk)
     begin
	if (sdram_req && debug != 0)
	     $display("xbus-ram: sdram read addr=0x%x data=0x%x; %t",
		      addr, dataout, $time);

	if (sdram_write && debug != 0)
	     $display("xbus-ram: sdram write addr=0x%x data=0x%x; %t",
		      addr, datain, $time);
     end
`endif

endmodule

