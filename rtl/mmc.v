//
// mmc.v
//
// basic interface to mmc card
// handles SPI transactions & mmc/sd clock
// serialization of data
//

module mmc(clk, reset, speed, rd, wr, init, send, cmd, data_in, data_out, done, mmc_cs, mmc_di, mmc_do, mmc_sclk);

   input clk;
   input reset;

   input speed;
   input rd;
   input wr;
   input init;
   input send;
   input [47:0] cmd;
   input [7:0] 	data_in;
   output [7:0] data_out;
   output      done;
   
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
     s0 = 4'd0,
     s1 = 4'd1,
     s2 = 4'd2,
     s3 = 4'd3,
     s4 = 4'd4,
     s5 = 4'd5,
     s6 = 4'd6,
     s8 = 4'd8,
     s9 = 4'd9,
     s10 = 4'd10,
     s11 = 4'd11;

   //
   reg [7:0]  mmc_clk_div;
   reg 	      mmc_clk_hi;
   wire       mmc_clk;

   reg [3:0] state;
   wire [3:0] next_state;

   reg [6:0]  bitcount;
   wire       bit8;
   wire       bit48;
   wire       bit80;

   // clock
   initial
     mmc_clk_div = 0;

   always @(posedge clk)
       mmc_clk_div = mmc_clk_div + 8'b00000001;
   
   assign mmc_clk = mmc_clk_hi ? mmc_clk_div[1] : mmc_clk_div[6];

   always @(posedge /*mmc_*/clk)
     if (reset)
       mmc_clk_hi <= 0;
     else
       if (s_speed)
	 mmc_clk_hi <= 1;
       else
	 mmc_clk_hi <= 0;

   // extend reset to compensate for slow mmc clock
   reg [6:0] reset_cnt;
   wire      mmc_reset;
   
   always @(posedge clk)
     if (reset)
       reset_cnt <= 0;
     else
       if (reset_cnt[6] == 1'b0)
	 reset_cnt <= reset_cnt + 7'b0000001;

   assign mmc_reset = ~reset_cnt[6];
   
   // domain crossing
   reg [47:0] s_cmd;
   reg [7:0]  s_data;
   reg 	      s_rd, s_wr, s_init, s_send, s_speed;
 	      
   always @(posedge mmc_clk)
     if (mmc_reset)
       begin
	  s_init <= 0;
	  s_send <= 0;
	  s_rd <= 0;
	  s_wr <= 0;
	  s_speed <= 0;
       end
     else
       begin
	  s_init <= init;
	  s_send <= send;
	  s_rd <= rd;
	  s_wr <= wr;
	  s_speed <= speed;
       end
	  
   always @(posedge mmc_clk)
     if (mmc_reset)
       state <= s0;
     else
       state <= next_state;

   assign next_state =
		      (state == s0 && s_init) ? s8 :
		      (state == s0 && s_send) ? s1 :
		      (state == s0 && s_wr) ? s3 :
		      (state == s0 && s_rd) ? s5 :

		      (state == s1 && bit48) ? s10 :
		      (state == s1) ? s2 :
		      (state == s2) ? s1 :

		      (state == s3 && bit8) ? s10 :
		      (state == s3) ? s4 :
		      (state == s4) ? s3 :

		      (state == s5) ? s6 :
		      (state == s6 && bit8) ? s10 :
		      (state == s6) ? s5 :

		      (state == s8 && bit80) ? s10 :
		      (state == s8) ? s9 :
		      (state == s9) ? s8 :
		      
//		      (state == s10 && (s_init == 0 && s_send == 0 && s_rd == 0 && s_wr == 0)) ? s0 :
		      (state == s10) ? s11 :
		      (state == s11) ? s0 :
		      state;


   // all output is referenced to clk
   reg [1:0] done_hist;
   wire      mc_done;
   
   always @(posedge clk)
     if (reset)
       done_hist <= 0;
     else
       done_hist <= { done_hist[0], mc_done };

   assign done = done_hist == 2'b01;

   assign mc_done = state == s11;
   
   assign bit8 = bitcount == 8;
   assign bit48 = bitcount == 48;
   assign bit80 = bitcount == 80;
   
   always @(posedge mmc_clk)
     if (mmc_reset)
       bitcount <= 0;
     else
       if (state == s1 || state == s3 || state == s5 || state == s8)
	 bitcount <= bitcount + 7'b00001;
       else
	 if (state == s0)
	   bitcount <= 0;

   always @(posedge mmc_clk)
     if (mmc_reset)
       mmc_sclk <= 1'b0;
     else
       if (((state == s1 || state == s2) && next_state != s10) ||
	   ((state == s3 || state == s4) && next_state != s10) ||
	   ((state == s5 || state == s6) && next_state != s10) ||
	   (state == s8))
	 mmc_sclk <= ~mmc_sclk;
       else
	 mmc_sclk <= 0;

   //
   wire assert_cs;
   assign assert_cs = (state == s1 || state == s2) ||
		      (state == s3 || state == s4) ||
		      (state == s5 || state == s6);

   // input side
   always @(posedge mmc_clk)
     if (reset)
       data_out <= 0;
     else
       begin
	  if (state == s0 && s_rd)
	    data_out <= 0;
	  else
	    if (state == s5)
	      data_out <= { data_out[6:0], mmc_di };
       end

   // output side
   always @(negedge mmc_clk)
     if (reset)
       begin
	  mmc_cs <= 1'b0;
	  mmc_do <= 1'b0;
	  s_cmd <= 0;
       end
     else
       begin
	  mmc_cs <= ~assert_cs;
	  
	  case (state)
	    s0:
	      begin
		 if (s_send)
		   s_cmd <= cmd;
		 if (s_wr)
		   s_data <= data_in;
	      end
	    s1:
	      mmc_do <= s_cmd[47];
	    s2:
	      s_cmd <= { s_cmd[46:0], 1'b0 };
	    s3:
	      mmc_do <= s_data[7];
	    s4:
	      s_data <= { s_data[6:0], 1'b0 };
	    s8:
	      mmc_do <= 1'b1;
	    s10:
	      mmc_do <= 1'b0;
	    default:
	      ;
	    
	  endcase
       end
   
endmodule // mmc
