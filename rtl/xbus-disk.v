/*
 * $Id$
 */

module xbus_disk (
		  reset,
		  clk,
		  addrin,
		  addrout,
		  datain,
		  dataout,
		  reqin,
		  reqout,
		  grantin,
		  ackout,
		  writein,
		  writeout,
		  decodein,
		  decodeout,
		  interrupt
		);

   input reset;
   input clk;
   input [21:0] addrin;		/* request address */
   input [31:0] datain;		/* request data */
   input 	reqin;		/* request */
   input 	grantin;	/* grant from bus arbiter */
   input 	writein;	/* request read#/write */
   input 	decodein;	/* decode ok from bus arbiter */
   
   output [21:0] addrout;
   output [31:0] dataout;
   reg [31:0] 	 dataout;
   output 	 reqout;
   output 	 ackout;	/* request done */
   output 	 writeout;
   output 	 decodeout;	/* request addr ok */
   output 	 interrupt;
 	 
   //
   reg [31:0] 	 disk_ma, disk_da, disk_ecc;

   wire 	 addr_match;
   wire 	 decode;
   reg 		 ack_delayed;
   
   //
   assign 	 addr_match = { addrin[21:3], 3'b0 } == 22'o17377770 ?
			      1'b1 : 1'b0;
   
   assign 	 decode = (reqin && addr_match) ? 1'b1 : 1'b0;

   assign 	 decodeout = decode;
   assign 	 ackout = ack_delayed;

   always @(posedge clk)
     if (reset)
       ack_delayed <= 0;
     else
       ack_delayed <= decode;

   assign reqout = 0;
   assign writeout = 0;
   assign interrupt = 0;
   
   always @(posedge clk)
     if (reset)
       begin
          disk_ma <= 0;
          disk_da <= 0;
          disk_ecc <= 0;
	  dataout <= 0;
       end
     else
       if (decode)
       begin
	  if (~writein)
	    begin
	      case (addrin[2:0])
		3'o4:
		  begin
		     dataout <= 1;
		     $display("disk: read status");
		  end
		3'o5: dataout <= disk_ma;
		3'o6: dataout <= disk_da;
		3'o7: dataout <= disk_ecc;
	      endcase
	   end

	 if (writein)
	   begin
	      case (addrin[2:0])
		3'o4:
		  begin
		     $display("disk: write status");
		  end
		3'o5: disk_ma <= datain;
		3'o6: disk_da <= datain;
		3'o7: disk_ecc <= datain;
	      endcase
	   end
      end

endmodule

