/*
 * $Id$
 */

module xbus_spy(
	       clk, reset,
	       addr, datain, dataout,
	       req, write, ack, decode,
	       spyin, spyout, spyreg, spywr, spyrd
	       );

   input clk;
   input reset;
   input [21:0] addr;		/* request address */
   input [31:0] datain;		/* request data */
   input 	req;		/* request */
   input 	write;		/* request read#/write */

   output [31:0] dataout;
   reg [31:0] 	 dataout;

   output 	ack;		/* request done */
   output 	decode;		/* request addr ok */

   input [15:0] spyin;
   output [15:0] spyout;
   reg [15:0] 	 spyout;
   output [3:0]  spyreg;
   output 	 spywr;
   output 	 spyrd;

   // -------------------------------------------------------------

   reg [2:0] ack_delayed;
   reg [2:0] ack_state;
   wire      spyrd_d;
   
   // spy board
   assign decode = req & ({addr[21:6], 6'b0} == 22'o17766000);

   assign ack = ack_delayed[2];
   assign spyreg = addr[3:0];

   //
   always @(posedge clk)
     if (reset)
       begin
	  ack_delayed <= 0;
	  ack_state <= 0;
       end
     else
       begin
	  ack_delayed <= { ack_delayed[1:0],  decode};
	  ack_state <= { ack_state[1:0], ~ack_delayed[0] && decode };
       end

   assign spyrd = ack_state[0] && ~write;
   assign spywr = ack_state[0] && write;

   assign spyrd_d = ack_state[1] && ~write;

`ifdef debug
   always @(posedge clk)
     begin
	if (spyrd)
	  $display("spy: assert spyrd");
	if (spyrd_d)
	  $display("spy: grab data");
        if (spywr)
	  $display("spy: assert spywr");
     end
`endif
   
   always @(posedge clk)
     if (reset)
       begin
	  dataout <= 0;
       end
     else
       begin
	  if (spyrd_d)
	    begin
	       dataout <= spyin;
`ifdef debug
	       $display("spy: read, spyin %x %t", spyin, $time);
`endif
	    end

	  if (req & decode)
	    begin
	    if (write)
	      begin
`ifdef debug
		 $display("spy: write @%o <- %o %t", addr, datain, $time);
`endif
		 spyout <= datain[15:0];
	      end
	    else
	      begin
`ifdef debug
		 $display("spy: read @%o", addr);
`endif
	      end
	    end
     end

endmodule // xbus_io

