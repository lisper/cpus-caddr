/*
 * $Id$
 */

module xbus_io(
	       reset, clk,
	       addr, datain, dataout,
	       req, ack, write, decode,
	       interrupt
	       );

   input reset;
   input clk;
   input [21:0] addr;		/* request address */
   input [31:0] datain;		/* request data */
   input 	req;		/* request */
   input 	write;		/* request read#/write */
   
   output [31:0] dataout;
   reg [31:0] dataout;

   output 	 ack;		/* request done */
   output 	 decode;	/* request addr ok */
   output 	 interrupt;

   // -------------------------------------------------------------

   reg [1:0]	 ack_delayed;

   // i/o board
   assign 	 decode = req & ({addr[21:6], 6'b0} == 22'o17772000);
   
   assign 	 ack = ack_delayed[1];

   assign 	 interrupt = 0;

   reg [5:0] 	 iob_csr;

   reg [31:0] 	 iob_key_scan;

   reg 		 mouse_tail, mouse_middle, mouse_head;
   reg [11:0] 	 mouse_x;
   reg [11:0] 	 mouse_y;
   reg [1:0] 	 mouse_rawx;
   reg [1:0] 	 mouse_rawy;
   reg [31:0] 	 us_clock;
   reg [31:0] 	 hz60_clock;
   
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
	  iob_csr <= 0;
       end
     else
       begin
	  dataout = 0;
	  
	  if (req & decode)
	    if (write)
	      begin
`ifdef debug
		 #1 $display("io: write @%o <- %o", addr, datain);
`endif
	       case (addr)
		 22'o17772045: /* KBD CSR */
		   begin
		      iob_csr <= datain[3:0];
		   end
	       endcase
	       
	    end
	  else
	    begin
               #1 $display("io: read @%o", addr);

	       case (addr)
		 22'o17772040: /* KBD LOW */
		   begin
		      dataout = { 16'b0, iob_key_scan[15:0]};
		      iob_csr[5] <= 0;
		   end

		 22'o17772041: /* KBD HI */
		   begin
		      dataout = { 16'b0, iob_key_scan[31:16]};
		      iob_csr[5] <= 0;
		   end

		 22'o17772042: /* MOUSE Y */
		   begin
		      dataout = { 18'b0,
				  mouse_head, mouse_middle, mouse_tail,
				  mouse_y };
		      iob_csr[4] <= 0;
		   end

		 22'o17772043: /* MOUSE X */
		   begin
		      dataout = { 18'b0,
				  mouse_rawy, mouse_rawx,
				  mouse_x };
		   end

		 22'o17772044: /* BEEP */
		   begin
		   end

		 22'o17772045: /* KBD CSR */
		   begin
		      dataout = iob_csr;
		   end

		 22'o17772050: /* USEC CLK */
		   begin
		      dataout = us_clock[15:0];
		   end

		 22'o17772051: /* USEC CLK */
		   begin
		      dataout = us_clock[31:16];
		   end

		 22'o17772052: /* start 60hz clock */
		   begin
		      dataout = hz60_clock;
		   end
	       endcase
	    end
     end


endmodule // xbus_io

