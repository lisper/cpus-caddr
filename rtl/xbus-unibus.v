/*
 * xbus-unibus.v
 * $Id$
 */

module xbus_unibus(
		   reset, clk,
		   addr, datain, dataout,
		   req, ack, write, decode,
		   interrupt, promdisable
		   );

   input reset;
   input clk;
   input [21:0] addr;		/* request address */
   input [31:0] datain;		/* request data */
   input 	req;		/* request */
   input 	write;		/* request read#/write */
   
   output [31:0] dataout;
reg [31:0] 	 dataout;
   
   output 	 ack;		/* request done */
   output 	 decode;	/* request addr ok */
   output 	 interrupt;

   output 	 promdisable;
   reg 		 promdisable;
   
   // --------------------------------------------------------------
   
   reg [1:0]	 ack_delayed;
   wire [5:0] 	 offset;

   wire 	 in_unibus;
   wire 	 in_other;

   wire 	 decode_unibus;
   wire 	 decode_other;
   
   assign 	 in_unibus = ({addr[21:6], 6'b0} == 22'o17773000);
   assign 	 in_other  =
			    ({addr[21:6],   6'b0} == 22'o17777700) |
   			    ({addr[21:12], 12'b0} == 22'o17740000);
   
   // 766000-766777 spy, mode, unibus, two machine lashup
   assign 	 decode_unibus = req & in_unibus;
   assign 	 decode_other = req & in_other;

   assign 	 decode = decode_unibus || decode_other;

   assign 	 ack = ack_delayed[1];

   assign 	 interrupt = 0;

   assign 	 offset = addr[5:0];

   
   always @(posedge clk)
     if (reset)
       ack_delayed <= 0;
     else
       begin
	  ack_delayed[0] <= decode;
	  ack_delayed[1] <= ack_delayed[0];
       end

   always @(posedge clk)
     if (reset)
       begin
	  promdisable = 0;
       end
     else
     begin
	promdisable = 0;
	
	if (decode_unibus)
	  if (write)
	    begin
`ifdef debug
               `DBG_DLY $display("unibus: write @%o <- %o", addr, datain);
`endif
	       /* verilator lint_off CASEINCOMPLETE */
	       case (offset)
		 6'o05:
		   begin
		      if (datain[5] && datain[2] && ~datain[0])
			promdisable = 1;
		   end
		 6'o20:
		   begin
		      if (datain[5] && datain[2] && ~datain[0])
			promdisable = 1;
		   end
	       endcase
	       /* verilator lint_on CASEINCOMPLETE */
	    end
	  else
	    begin
`ifdef debug
               `DBG_DLY $display("unibus: read @%o", addr);
`endif
	       dataout = 0;
	    end

	if (decode_other)
	  if (write)
	    begin
`ifdef debug
               `DBG_DLY $display("unibus: other write @%o <- %o", addr, datain);
`endif
	    end
	  else
	    begin
`ifdef debug
               `DBG_DLY $display("unibus: other read @%o", addr);
`endif
	       dataout = 0;
	    end

     end


endmodule

