/*
 * $Id$
 */

module xbus_io(
	       reset, clk,
	       addr, datain, dataout,
	       req, ack, write, decode,
	       interrupt, vector
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
   output [7:0]  vector;
   
   // -------------------------------------------------------------

   parameter SYS_CLK = 26'd50000000,
	       HZ60_CLK_RATE = 26'd60,
	       HZ60_CLK_DIV = SYS_CLK / HZ60_CLK_RATE,
	       US_CLK_RATE = 26'd1000000,
	       US_CLK_DIV = SYS_CLK / US_CLK_RATE;
   
   reg [1:0] ack_delayed;

   wire [25:0] 	hz60_clk_div;
   wire [25:0] 	us_clk_div;

   reg [19:0] 	hz60_counter;
   reg [7:0] 	us_counter;
   
   assign hz60_clk_div = HZ60_CLK_DIV;
   assign us_clk_div = US_CLK_DIV;

   // i/o board
   assign 	 decode = req & ({addr[21:6], 6'b0} == 22'o17772000);
   
   assign 	 ack = ack_delayed[1];

   reg [3:0] 	 iob_csr;
   reg [3:0] 	 iob_rdy;

   reg [31:0] 	 iob_key_scan;

   reg 		 mouse_tail, mouse_middle, mouse_head;
   reg [11:0] 	 mouse_x;
   reg [11:0] 	 mouse_y;
   reg [1:0] 	 mouse_rawx;
   reg [1:0] 	 mouse_rawy;
   reg [31:0] 	 us_clock;
   reg [31:0] 	 hz60_clock;

   reg 		 hz60_enabled;

   wire 	 hz60_clk_fired;

   reg 		 set_clk_rdy;
   

   //
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
	  iob_rdy <= 0;

	  hz60_enabled <= 0/*1'b1*/;	//DEBUG
       end
     else
       begin
	  dataout = 0;
	  
	  if (req & decode)
	    begin
	    if (write)
	      begin
`ifdef debug
		 `DBG_DLY $display("io: write @%o <- %o", addr, datain);
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
`ifdef debug
               `DBG_DLY $display("io: read @%o", addr);
`endif
	       case (addr)
		 22'o17772040: /* KBD LOW */
		   begin
		      dataout = { 16'b0, iob_key_scan[15:0]};
		      iob_rdy[1] <= 0;
		   end

		 22'o17772041: /* KBD HI */
		   begin
		      dataout = { 16'b0, iob_key_scan[31:16]};
		      iob_rdy[1] <= 0;
		   end

		 22'o17772042: /* MOUSE Y */
		   begin
		      dataout = { 17'b0,
				  mouse_head, mouse_middle, mouse_tail,
				  mouse_y };
		      iob_rdy[0] <= 0;
		   end

		 22'o17772043: /* MOUSE X */
		   begin
		      dataout = { 16'b0,
				  mouse_rawy, mouse_rawx,
				  mouse_x };
		   end

		 22'o17772044: /* BEEP */
		   begin
		   end

		 22'o17772045: /* KBD CSR */
		   dataout = { 28'b0, iob_csr };

		 22'o17772050: /* USEC CLK */
		   begin
//		      dataout = { 16'b0, us_clock[15:0] };
dataout = 0;

`ifdef debug
		      $display("io: usec lo %o", { 16'b0, us_clock[15:0] });
`endif
		   end

		 22'o17772051: /* USEC CLK */
		   begin
//		      dataout = { 16'b0, us_clock[31:16] };
dataout = 0;
		      
`ifdef debug
		      $display("io: usec hi %o", { 16'b0, us_clock[31:16] });
`endif
		   end

		 22'o17772052: /* start 60hz clock */
		   begin
		      dataout = hz60_clock;
		      iob_rdy[2] <= 0;
		      hz60_enabled <= 1;
`ifdef debug
		      $display("io: 60hz clk %o", hz60_clock);
`endif
		   end
	       endcase
	      end
	    end // if (req & decode)
	  else
	    begin
	       if (set_clk_rdy)
		 iob_rdy[2] <= 1;
	    end
     end

//   assign interrupt = hz60_clk_int_enable && clk_done;
   assign 	 interrupt = 0;

   assign hz60_clk_fired = hz60_counter == hz60_clk_div[19:0];

   always @(posedge clk)
     if (reset)
       begin
	  iob_key_scan <= 0;
	  mouse_rawx <= 0;
	  mouse_rawy <= 0;
	  mouse_x <= 0;
	  mouse_y <= 0;
	  mouse_tail <= 0;
	  mouse_middle <= 0;
	  mouse_head <= 0;
       end

   // 60hz clock
   always @(posedge clk)
     if (reset)
       begin
	  hz60_counter <= 0;
	  hz60_clock <= 0;
       end
     else
       if (hz60_enabled)
	 begin
	    set_clk_rdy = 0;
	    if (hz60_counter == hz60_clk_div[19:0])
	      begin
		 hz60_counter <= 0;
		 hz60_clock <= hz60_clock + 1;
		 set_clk_rdy = 1;
	      end
	    else
	      hz60_counter <= hz60_counter + 20'd1;
	 end


   // microsecond counter
   always @(posedge clk)
     if (reset)
       begin
	  us_counter <= 0;
	  us_clock <= 0;
       end
     else
       if (us_counter == us_clk_div[7:0])
	 begin
	    us_counter <= 0;
	    us_clock <= us_clock + 1;
	 end
       else
	 us_counter <= us_counter + 8'd1;


   assign vector = 8'b0;
   
endmodule // xbus_io

