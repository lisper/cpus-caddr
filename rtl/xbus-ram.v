/*
 * $Id$
 */

module xbus_ram (
		reset,
		clk,
		addr,
		datain,
		dataout,
		req,
		write,
		ack,
		decode
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

   //
   reg 		 req_delayed;
   reg [6:0] 	 ack_delayed;
   
   assign 	 decode = addr < 22'o1000000 ? 1'b1: 1'b0;
   assign 	 ack = ack_delayed[6];
   
   always @(posedge clk)
     if (reset)
       begin
          req_delayed <= 0;
          ack_delayed <= 7'b0;
       end
    else
      begin
         req_delayed <= req & decode & ~|ack_delayed;
         ack_delayed[0] <= req_delayed;
         ack_delayed[1] <= ack_delayed[0];
         ack_delayed[2] <= ack_delayed[1];
         ack_delayed[3] <= ack_delayed[2];
         ack_delayed[4] <= ack_delayed[3];
         ack_delayed[5] <= ack_delayed[4];
         ack_delayed[6] <= ack_delayed[5];

`ifdef debug_detail
	 if (req & decode)
	   $display("ddr: decode %b; %b %b",
		    req & decode, req_delayed, ack_delayed);

	 if (req & decode & ~|ack_delayed)
	   $display("ddr: req_delayed %b", req & decode & ~|ack_delayed);

	 if (ack_delayed[6])
	     $display("ddr: ack %b", ack);
`endif
      end

   always @(posedge clk)
     begin
	if (req & decode)
	  if (write)
	    begin
               #1 $display("ddr: write @%o", addr);
	    end
	  else
	    begin
               #1 $display("ddr: read @%o", addr);
	    end
     end

endmodule

