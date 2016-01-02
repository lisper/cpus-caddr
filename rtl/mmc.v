//
// mmc.v
//
// basic interface to mmc card
// handles SPI transactions & mmc/sd clock
// serialization of data
//

//`define CHIPSCOPE_MMC

module mmc(clk, reset, speed, rd, wr, init, send, stop, cmd,
	   data_in, data_out, done, state_out,
	   mmc_cs, mmc_di, mmc_do, mmc_sclk);

   parameter [31:0] FREQ    = 50000000;
   parameter [31:0] RATE_HI = 10000000;
//   parameter [31:0] RATE_LO =   100000;
   parameter [31:0] RATE_LO =   50000;

   input clk;
   input reset;

   input speed;
   input rd;
   input wr;
   input init;
   input send;
   input stop;
   input [47:0] cmd;
   input [7:0] 	data_in;
   output [7:0] data_out;
   output      done;
   output [3:0] state_out;
   
   output mmc_cs;
   output mmc_do;
   output mmc_sclk;
   input  mmc_di;

   reg [7:0] data_out;
   
   reg    mmc_cs;
   reg 	  mmc_do;
   reg 	  mmc_sclk;
   
   //
   // 
   parameter [3:0]
     s0      = 4'd0,
     s_cmd0  = 4'd4,
     s_cmd1  = 4'd5,
     s_wr0   = 4'd6,
     s_rd0   = 4'd7,
     s_init0 = 4'd8,
     s_init1 = 4'd9,
     s_stp0  = 4'd10,
     s_stp1  = 4'd11,
     s_done0 = 4'd12,
     s_done1 = 4'd13,
     s_done2 = 4'd14;

   //
   reg [15:0] bit_time;
   reg 	      mmc_clk_hi;
   wire       mmc_clk;

   reg [3:0]  state;
   wire [3:0] next_state;

   reg [47:0] s_cmd;
   reg [7:0]  s_data;
   reg 	      s_rd, s_wr, s_send;
   
   reg [7:0]  bitcount;
   wire       bit8;
   wire       bit48;
   wire       bit80;
   wire       bit100;
   wire       bit120;

   parameter BITWIDTH_HI = FREQ / RATE_HI;
   parameter BITWIDTH_LO = FREQ / RATE_LO;

`ifndef SIMULATION
   parameter BITWIDTH_LO_MIDCNT = BITWIDTH_LO/2;
   parameter BITWIDTH_LO_MAXCNT = BITWIDTH_LO-1;

   parameter BITWIDTH_LO_1QTR = BITWIDTH_LO/4;
   parameter BITWIDTH_LO_3QTR = BITWIDTH_LO - BITWIDTH_LO/4;
   
//   parameter BITWIDTH_HI_MIDCNT = 0/*BITWIDTH_HI/2*/;
//   parameter BITWIDTH_HI_MAXCNT = 1/*BITWIDTH_HI-1*/;
//   parameter BITWIDTH_HI_MIDCNT = 3/*BITWIDTH_HI/2*/;
//   parameter BITWIDTH_HI_MAXCNT = 5/*BITWIDTH_HI-1*/;
   parameter BITWIDTH_HI_MIDCNT = 10/*BITWIDTH_HI/2*/;
   parameter BITWIDTH_HI_MAXCNT = 19/*BITWIDTH_HI-1*/;
`else
   parameter BITWIDTH_LO_MIDCNT = BITWIDTH_LO/2;
   parameter BITWIDTH_LO_MAXCNT = BITWIDTH_LO-1;
   parameter BITWIDTH_LO_1QTR = BITWIDTH_LO/4;
   parameter BITWIDTH_LO_3QTR = BITWIDTH_LO - BITWIDTH_LO/4;
   
//   parameter BITWIDTH_HI_MIDCNT = 0;
//   parameter BITWIDTH_HI_MAXCNT = 1;
//   parameter BITWIDTH_HI_MIDCNT = 3;
//   parameter BITWIDTH_HI_MAXCNT = 5;
//   parameter BITWIDTH_HI_MIDCNT = 6;
//   parameter BITWIDTH_HI_MAXCNT = 10;
   parameter BITWIDTH_HI_MIDCNT = 10;
   parameter BITWIDTH_HI_MAXCNT = 19;
`endif

   wire [31:0] bitmiddle;
   wire [31:0] bitwidth;
   wire [31:0] bit1quarter;
   wire [31:0] bit3quarter;
   
   //
`ifdef debug
   integer debug/* verilator public_flat */;
   initial
     debug = 0;
`endif

   //
   wire      mmc_reset;
   assign mmc_reset = reset;
   
   // clock
   always @(posedge clk)
     if (reset)
       bit_time <= 0;
     else
       if (bit_end || state == s0 || state == s_cmd0)
	 bit_time <= 0;
       else
	 bit_time <= bit_time + 16'd1;

   assign bitmiddle = mmc_clk_hi ? (BITWIDTH_HI_MIDCNT) : (BITWIDTH_LO_MIDCNT);
   assign bitwidth = mmc_clk_hi ? (BITWIDTH_HI_MAXCNT) : (BITWIDTH_LO_MAXCNT);
   assign bit1quarter = BITWIDTH_LO_1QTR;
   assign bit3quarter = BITWIDTH_LO_3QTR;
   
   always @(posedge clk)
     if (reset)
       mmc_clk_hi <= 0;
     else
       if (speed)
	 mmc_clk_hi <= 1;
       else
	 mmc_clk_hi <= 0;

   //
   reg bit_middle, bit_end, bit_1_3_quarter;

   always @(posedge clk)
     if (reset)
       begin
	  bit_middle <= 0;
	  bit_end <= 0;
	  bit_1_3_quarter <= 0;
       end
     else
       begin
	  bit_middle <= (bit_time == bitmiddle) ? 1'b1 : 1'b0;
	  bit_end <= (bit_time == bitwidth) ? 1'b1 : 1'b0;
	  bit_1_3_quarter <= (bit_time >= bit1quarter && bit_time <= bit3quarter) ? 1'b1 : 1'b0;
       end

   //
   wire neg_edge, pos_edge;

   assign neg_edge = (bit_middle | bit_end) & mmc_sclk;
   assign pos_edge = (bit_middle | bit_end) & ~mmc_sclk;

   //
   wire bit_shift;

   assign bit_shift = bit_end && counting_bits;

   
   //
   always @(posedge clk)
     if (mmc_reset)
       state <= s0;
     else
       begin
	  state <= next_state;
`ifdef debug
	  if (state != next_state && debug != 0)
	    $display("mmc: state %d", next_state);
`endif
       end

`ifdef debug
   always @(posedge clk)
     if (debug != 0)
     begin
	if (state == s_rd0 && next_state == s_done0)
	  $display("mmc: s_rd0; data_out %x", data_out);
	if (state == s0 && next_state == s_wr0)
	  $display("mmc: s_wr0; data_in %x", data_in);
     end
`endif

   assign next_state =
		      (state == s0 && init) ? s_init0 :
		      (state == s0 && send) ? s_cmd0 :
		      (state == s0 && wr) ? s_wr0 :
		      (state == s0 && rd) ? s_rd0 :
		      (state == s0 && stop) ? s_stp0 :

		      (state == s_cmd0) ? s_cmd1 :
		      (state == s_cmd1 && bit48) ? s_done0 :

		      (state == s_wr0 && bit8) ? s_done0 :
		      (state == s_rd0 && bit8) ? s_done0 :
		      (state == s_init0 && bit80) ? s_init1 :
		      (state == s_init1 && bit100) ? s_done0 :
		      (state == s_stp0 && bit_middle) ? s_stp1 :
		      (state == s_stp1 && bit8) ? s_done0 :
		      
		      (state == s_done0 && bit_end) ? s_done1 :
		      (state == s_done1) ? s_done2 :
		      (state == s_done2) ? s0 :
		      state;

   assign state_out = state;

   // all output is referenced to clk
   wire      mc_done;

   assign mc_done = state == s_done2;
   assign done = mc_done;
   
   assign bit8 = bitcount == 8;
   assign bit48 = bitcount == 48;
   assign bit80 = bitcount == 80;
   assign bit100 = bitcount == 100;

   wire counting_bits;
   assign counting_bits = (state >= s_cmd0 && state <= s_stp1);

   always @(posedge clk)
     if (mmc_reset)
       bitcount <= 0;
     else
       if (bit_end && counting_bits)
	 bitcount <= bitcount + 8'b00000001;
       else
	 if (state == s0 || state == s_done0)
	   bitcount <= 0;

//   always @(posedge clk)
//     if (mmc_reset)
//       mmc_sclk <= 1'b0;
//     else
//       if (counting_bits)
//	 begin
//	    // pause clock after init bits
//	    if (state == s_init1 || state == s_cmd0)
//	      mmc_sclk <= 0;
//	    else
//	      if (bit_middle || bit_end)
//		mmc_sclk <= ~mmc_sclk;
//	 end
//       else
//	 if (state == s0 || state == s_done0)
//	   mmc_sclk <= 1'b0;

   reg [1:0]  sclk_state;
   wire [1:0] sclk_state_next;
   
   wire sclk_toggle;
   wire sclk_assert;

   always @(posedge clk)
     if (mmc_reset)
       sclk_state <= 0;
     else
       sclk_state <= sclk_state_next;

   assign sclk_toggle = counting_bits && ~(state == s_init1 || state == s_cmd0);

   wire sclk_assert_lo, sclk_assert_hi;

   assign sclk_assert_lo = sclk_toggle && bit_1_3_quarter;
   assign sclk_assert_hi = sclk_toggle && bit_middle;

   assign sclk_assert = mmc_clk_hi ? sclk_assert_hi : sclk_assert_lo;

   assign sclk_state_next =
			  (sclk_state == 0 && sclk_toggle) ? 1 :
			  (sclk_state == 1 && ~sclk_toggle) ? 0 :
			  (sclk_state == 1 && bit_middle) ? 2 :
			  (sclk_state == 2 && ~sclk_toggle) ? 0 :
			  (sclk_state == 2 && bit_end) ? 1 :
			  sclk_state;

   wire bit_sample;
//   assign bit_sample = mmc_clk_hi ? bit_end : bit_middle;
//   assign bit_sample = (mmc_clk_hi ? bit_end : bit_middle) && counting_bits;
   assign bit_sample = (mmc_clk_hi ? mmc_sclk : bit_middle) && counting_bits;
   
   always @(posedge clk)
     if (mmc_reset)
       mmc_sclk <= 1'b0;
     else
       if (sclk_assert)
	 mmc_sclk <= 1;
       else
	 mmc_sclk <= 0;
	 
   // input side
   always @(posedge clk)
     if (reset)
       data_out <= 0;
     else
       begin
	  if (state == s0 && rd)
	    data_out <= 0;
	  else
	    if (state == s_rd0 && bit_sample)
	      data_out <= { data_out[6:0], mmc_di };
       end

   // output side
   always @(posedge clk)
     if (reset)
       begin
	  mmc_cs <= 1'b0;
	  mmc_do <= 1'b0;
	  s_cmd <= 0;
	  s_rd <= 0;
	  s_wr <= 0;
	  s_send <= 0;
       end
     else
       begin
	  case (state)
	    s0:
	      begin
		 if (send)
		   begin
		      s_send <= 1;
		      s_cmd <= cmd;
		   end
		 if (wr)
		   begin
		      s_wr <= 1;
		      s_data <= data_in;
		   end
		 if (rd)
		   s_rd <= 1;
	      end

	    s_cmd0:
	      begin
		 mmc_cs <= 1'b0;
		 mmc_do <= s_cmd[47];
		 if (bit_shift)
		   s_cmd <= { s_cmd[46:0], 1'b0 };
	      end
	    
	    s_cmd1:
	      begin
		 if (next_state != s_done0)
		   mmc_do <= s_cmd[47];
		 if (bit_shift)
		   s_cmd <= { s_cmd[46:0], 1'b0 };
	      end

	    s_wr0:
	      begin
		 if (next_state != s_done0)
		   mmc_do <= s_data[7];
		 if (bit_shift)
		   s_data <= { s_data[6:0], 1'b0 };
	      end

	    s_init0:
	      begin
		 mmc_do <= 1'b1;
		 mmc_cs <= 1'b1;
	      end
	    s_init1:
		 mmc_do <= 1'b1;
	      
	    s_stp0:
	      begin
		 mmc_cs <= 1'b1;
		 mmc_do <= 1'b1;
	      end

	    s_done0:
	      begin
		 mmc_do <= 1'b1;

		 s_rd <= 0;
		 s_wr <= 0;
		 s_send <= 0;
	      end

	    default:
	      ;
	    
	  endcase
       end

`ifdef __CVER__
 `ifdef CHIPSCOPE_MMC
  `undef CHIPSCOPE_MMC
 `endif
`endif
   
`ifdef CHIPSCOPE_MMC
   // chipscope
   wire [35:0] control0;
   wire [7:0]  trig0;
   reg 	       mclk;
   reg [6:0]   mcnt;
   
	
   assign trig0 = { speed, rd, wr, send, mmc_sclk, mmc_di, mmc_do, mmc_cs };

   always @(posedge clk)
     if (reset)
       begin
	  mcnt <= 0;
	  mclk <= 0;
       end
     else
       begin
	  if (mcnt != 50)
	    mcnt <= mcnt + 1;
	  else
	    begin
	       mcnt <= 0;
	       mclk <= ~mclk;
	    end
       end

   chipscope_icon icon1 (.CONTROL0(control0));
   chipscope_ila ila1 (.CONTROL(control0), .CLK(mclk), .TRIG0(trig0));
`endif
   
endmodule // mmc
