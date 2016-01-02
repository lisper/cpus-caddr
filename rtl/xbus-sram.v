/*
 * $Id$
 */

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

//   parameter 	 DRAM_SIZE = 2097152;
//   parameter 	 DRAM_BITS = 21;

//   parameter 	 DRAM_SIZE = 1048576;
//   parameter 	 DRAM_BITS = 20;

//   parameter 	 DRAM_SIZE = 524288;
//   parameter 	 DRAM_BITS = 19;

//   parameter 	 DRAM_SIZE = 262144;
//   parameter 	 DRAM_BITS = 18;

   parameter 	 DRAM_SIZE = 131072;
   parameter 	 DRAM_BITS = 17;
   
   //
   reg [31:0] 	 ram[DRAM_SIZE-1:0];

   integer i, debug, debug_decode, debug_detail_delay;

   initial
     begin
	debug = 0;
	debug_decode = 0;
	debug_detail_delay = 0;
	for (i = 0; i < DRAM_SIZE; i = i + 1)
	  ram[i] = 0;
     end
   
//   parameter 	 DELAY = 15;
//   parameter 	 DELAY = 10;
   parameter 	 DELAY = 3;
//   parameter 	 DELAY = 2;
//   parameter 	 DELAY = 1;

   reg [21:0] 	 reg_addr;
   reg 		 req_delayed;
   reg [DELAY:0] ack_delayed;
   wire 	 local_ack;
   
   // need some dram address space at the end 
   // which is decoded but does not read/write...
   assign 	 decode = addr < 22'o11000000 ? 1'b1: 1'b0;


//
assign sdram_write = req & decode & write;
assign sdram_req = req & decode & ~write;
//assign ack = sdram_done || sdram_ready;
//assign ack = local_ack;
assign ack = req_delayed;
//
   
   assign local_ack = ack_delayed[DELAY];
   
   always @(posedge clk)
     if (reset)
       reg_addr <= 0;
     else
       if (req & decode & ~|ack_delayed)
	 reg_addr <= addr;
   
   wire [DRAM_BITS-1:0] reg_addr20;
   assign reg_addr20 = reg_addr[DRAM_BITS-1:0];
   
   always @(posedge clk)
     if (reset)
       begin
          req_delayed <= 0;
          ack_delayed <= 0;
       end
     else
       begin
	  req_delayed <= (sdram_write || sdram_req) & ~|ack_delayed;
	  ack_delayed <= { ack_delayed[DELAY-1:0], req_delayed };

`ifdef debug
	  if (req & decode && debug_detail_delay != 0)
	    $display("ddr: decode %b; %b %b",
		     req & decode, req_delayed, ack_delayed);

	  if (req & decode & ~|ack_delayed  && debug_detail_delay != 0)
	    $display("ddr: req_delayed %b", req & decode & ~|ack_delayed);
	  
	  if (local_ack && debug_detail_delay != 0)
	    $display("ddr: ack %b", ack);
`endif
       end

   always @(posedge clk)
     begin
	if (req & decode & req_delayed & ~|ack_delayed)
	  if (write)
	    begin
`ifdef debug
	       if (debug != 0)
               $display("sdram: write @%o <- %o (0x%x); %t", reg_addr20, datain, datain, $time);
`endif
	       if (reg_addr < DRAM_SIZE)
		 ram[reg_addr20] <= datain;
	    end
	  else
	    begin
`ifdef debug
	       if (debug != 0)
               $display("sdram: read @%o -> %o (0x%x) (addr=%o); %t",
			reg_addr20, ram[reg_addr20], ram[reg_addr20], reg_addr, $time);
`endif
	    end
     end

   assign dataout = reg_addr < DRAM_SIZE ? ram[reg_addr20] : 32'hffffffff;

//
//`define monitor_ack
`ifdef monitor_ack
   integer count;
   always @(posedge clk)
       if (req)
	 begin
	    if (decode & ~|ack_delayed)
	      count <= 0;
	    else
	      count <= count + 1;

	    if (ack)
	      $display("ack = %d; addr=%o write=%b", count, reg_addr, write);
	 end
`endif   
//

endmodule
