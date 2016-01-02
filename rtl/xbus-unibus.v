/*
 * xbus-unibus.v
 * $Id$
 */

`ifndef DBG_DLY
`define DBG_DLY
`endif

module xbus_unibus(
		   reset, clk,
		   addr, datain, dataout,
		   req, ack, write, decode,
		   interrupt, promdisable, timeout
		   );

   input reset;
   input clk;
   input [21:0] addr;		/* request address */
   input [31:0] datain;		/* request data */
   input 	req;		/* request */
   input 	write;		/* request read#/write */
   input 	timeout;
   
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

   reg 		 clear_bus_status;
   reg 		 clear_bus_ints;
   reg 		 set_unibus_int_en;
   reg 		 clear_unibus_int_en;

   wire [31:0] 	 bus_status;
   wire [31:0]	 bus_ints;

   reg 		 unibus_nxm;	/* unibus timeout */
   reg 		 xbus_nxm;	/* xbus timeout */
   
   reg 		 xbus_int;
   reg 		 unibus_int;
   reg 		 unibus_int_en;
   reg [7:0] 	 unibus_vector;
   

   // address decodes
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

   // bus interrupts & status
   assign 	 bus_status = {  28'b0, unibus_nxm, 2'b0, xbus_nxm };

   assign  	 bus_ints = { 14'b0,
			      2'b0, unibus_int,
			      xbus_int, 2'b0,
			      1'b0, unibus_int_en, unibus_vector, 2'b0 };

   
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
	clear_bus_status = 0;
	clear_bus_ints = 0;
	set_unibus_int_en = 0;
	clear_unibus_int_en = 0;
	dataout = 0;
	
	if (decode_unibus)
	  if (write)
	    begin
`ifdef debug
               `DBG_DLY $display("unibus: write @%o <- %o; %t", addr, datain, $time);
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
		      if (datain[10])
			set_unibus_int_en = 1;
		      else
			clear_unibus_int_en = 1;
		 
		      clear_bus_ints = 1;
		   end
		 
		 6'o22:
		   clear_bus_status = 1;

	       endcase
	       /* verilator lint_on CASEINCOMPLETE */
	    end
	  else
	    begin
`ifdef debug
               `DBG_DLY $display("unibus: read @%o", addr);
`endif

	       /* verilator lint_off CASEINCOMPLETE */
	       case (offset)
		 6'o20:
		   begin
		      dataout = bus_ints;
`ifdef debug
		      $display("unibus: read ints %o", bus_ints);
`endif
		   end
		 6'o22:
		   begin
		      dataout = bus_status;
`ifdef debug
		      $display("unibus: read status %o", bus_status);
`endif
		   end
	       endcase
	       /* verilator lint_on CASEINCOMPLETE */
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


   always @(posedge clk)
     if (reset)
       begin
	  xbus_int <= 1'b0;
	  unibus_int <= 1'b0;
	  unibus_vector <= 8'b0;

	  unibus_int_en <= 1'b0;
       end
     else
       begin
	  if (clear_bus_ints)
	    begin
	       unibus_int <= 1'b0;
	       unibus_vector <= 8'b0;
	    end
	  if (set_unibus_int_en)
	    unibus_int_en <= 1'b1;
	  if (clear_unibus_int_en)
	    unibus_int_en <= 1'b1;
       end

   always @(posedge clk)
     if (reset)
       begin
	  unibus_nxm <= 1'b0;
	  xbus_nxm <= 1'b0;
       end
     else
       if (timeout)
	 begin
	    if (addr > 22'o17400000)
	      begin
`ifdef debug
		 $display("unibus: timeout %o", addr);
`endif
		 unibus_nxm <= 1'b1;
	      end
	    else
	      if (addr > 22'o17000000)
		begin
`ifdef debug
		 $display("xbus: timeout %o", addr);
`endif
		   xbus_nxm <= 1'b1;
		end
	 end
       else
	 if (clear_bus_status)
	   begin
`ifdef debug
		 $display("unibus: clear timeouts; %t", $time);
`endif
	       unibus_nxm <= 1'b0;
	       xbus_nxm <= 1'b0;
	    end

endmodule

