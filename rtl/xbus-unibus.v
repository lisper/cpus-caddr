/*
 * xbus-unibus.v
 * $Id$
 */

module xbus_unibus(
		   reset,
		   clk,
		   addr,
		   datain,
		   dataout,
		   req,
		   ack,
		   write,
		   decode,
		   interrupt
		   );

   input reset;
   input clk;
   input [21:0] addr;		/* request address */
   input [31:0] datain;		/* request data */
   input 	req;		/* request */
   input 	write;		/* request read#/write */
   
   output [31:0] dataout;
   output 	 ack;		/* request done */
   output 	 decode;	/* request addr ok */
   output 	 interrupt;

   // 764000-7641777 i/o board
   assign 	 decode = req & (addr == 22'o17766xxx);
   assign 	 ack = decode;

   assign 	 interrupt = 0;
   
   always @(posedge clk)
     begin
	if (req & decode)
	  if (write)
	    begin
               #1 $display("unibus: write @%o", addr);
	    end
	  else
	    begin
               #1 $display("unibus: read @%o", addr);
	    end
     end


endmodule

