//
// mmc_block_dev.v
// $Id$
//

//`define  CHIPSCOPE_MMC_BD
   
`ifdef SIMULATION
 `define debug
`endif
  
module mmc_block_dev(clk, reset,
		     bd_cmd, bd_start, bd_bsy, bd_rdy, bd_err, bd_addr,
		     bd_data_in, bd_data_out, bd_rd, bd_wr, bd_iordy, bd_state,
		     mmc_cs, mmc_di, mmc_do, mmc_sclk
		     );

   input clk;
   input reset;

   input [1:0] bd_cmd;
   input       bd_start;
   output      bd_bsy;
   output      bd_rdy;
   output      bd_err;
   input [23:0] bd_addr;
   input [15:0] bd_data_in;
   output [15:0] bd_data_out;
   input 	 bd_rd;
   input 	 bd_wr;
   output 	 bd_iordy;
   output [11:0]  bd_state;
   
   output 	 mmc_cs;
   input 	 mmc_di;
   output 	 mmc_do;
   output 	 mmc_sclk;

   //
`ifdef debug
   integer debug/* verilator public_flat */;
   integer debug_state/* verilator public_flat */;

   initial
     begin
	debug = 0;
	debug_state = 0;
     end
`endif
   
   /* generic block device interface */

   parameter
     CMD01 = 48'h400000000095,
     CMD02 = 48'h410000000001/*ff*/,
     CMD16 = 48'h500000000001/*ff*/,
     CMD17 = 48'h510000000001/*ff*/;	// 01 010001 00000000000000000000000000000000 "0101010" 1 

   reg 	      mmc_wr;
   reg 	      mmc_rd;
   reg 	      mmc_init;
   reg 	      mmc_send;
   reg 	      mmc_stop;
   reg [47:0] mmc_cmd;
   reg 	      mmc_speed;
   reg 	      mmc_hispeed;
   reg 	      mmc_lospeed;
 	      
   reg [7:0]  mmc_in;
   wire [7:0] mmc_out;
   wire       mmc_done;
   wire [3:0] mmc_state;
   
   reg 	      set_inited;
   reg 	      inited;

   reg        clear_err;
   reg        set_err;

   reg        clear_wc;
   reg        inc_wc;
   reg        clear_bc;
   reg        inc_bc;
   reg        inc_lba;

   reg [31:0] lba32;

   // disk state
   parameter [5:0]
		s_idle = 0,
		s_busy = 1,

		s_init0 = 4,
		s_init1 = 5,
     		s_init2 = 6,
		s_init3 = 7,
		s_init4 = 8,
		s_init5 = 9,

		s_read0 = 10,
		s_read1 = 11,
     		s_read2 = 12,
     		s_read3 = 13,
     		s_read4 = 14,
          	s_read5 = 15,
          	s_read6 = 16,

		s_write0 = 20,
		s_write1 = 21,
      		s_write2 = 22,
		s_write2a = 19,
		s_write2b = 17,
      		s_write3 = 23,
      		s_write4 = 24,
      		s_write5 = 25,
      		s_write5a = 18,
           	s_write6 = 26,
               	s_write7 = 27,

      		s_done0 = 28,

		s_reset = 29,
		s_reset0 = 30,
		s_reset1 = 31,
		s_reset2 = 32,
		s_reset3 = 33,
		s_reset4 = 34,
		s_reset5 = 35,
		s_reset6 = 36,
		s_reset7 = 37,
		s_reset8 = 38,
		s_reset9 = 39,
		s_reset10 = 40,
		s_reset11 = 41;

   reg [5:0] state;
   reg [5:0] state_next;

   reg [1:0] bd_cmd_hold;
   reg 	     err;
   
   //
   mmc mmc(.clk(clk), .reset(reset), .speed(mmc_speed),
	   .wr(mmc_wr), .rd(mmc_rd), .init(mmc_init), .send(mmc_send), .stop(mmc_stop),
	   .cmd(mmc_cmd), .data_in(mmc_in), .data_out(mmc_out), .done(mmc_done),
	   .state_out(mmc_state),
	   .mmc_cs(mmc_cs), .mmc_di(mmc_di), .mmc_do(mmc_do), .mmc_sclk(mmc_sclk));

   //
   assign bd_iordy = (state == s_read2) ||
		     (state == s_write2a) ||
		     (state == s_write2b);

   assign bd_rdy =
		  (state == s_idle) ||
		  (state == s_read0) || (state == s_read1) || (state == s_read2) ||
		  (state == s_write0) || (state == s_write1) ||
		  (state == s_done0);

   //
   reg [15:0] data_hold;
   reg [15:0] mmc_hold;
   
   // grab the dma'd data, later used by mmc
   always @(posedge clk)
     if (reset)
       data_hold <= 0;
     else
     if (state == s_write0 && bd_wr)
       begin
	  data_hold <= bd_data_in;
`ifdef debug
	  if (debug != 0)
	    $display("mmc_block_dev: data_hold %x", bd_data_in);
`endif
       end

   // grab the mmc data, later used by dma
   always @(posedge clk)
     if (reset)
       mmc_hold <= 0;
     else
       if (mmc_done)
	 begin
	    if (state == s_read0)
	      mmc_hold[7:0] <= mmc_out;
	    else
	      if (state == s_read1)
		mmc_hold[15:8] <= mmc_out;
	      else
		// for debug
		if (state == s_reset2 || state == s_reset4 || state == s_reset6 ||
		    state == s_init2 || state == s_write5 || state == s_write5a)
		  mmc_hold[7:0] <= mmc_out;
	 end

   assign bd_data_out = mmc_hold;

   // word & block count
   reg [7:0]   wc;
   reg [1:0]   bc;
   
   always @(posedge clk)
     if (reset)
       begin
	  wc <= 8'b0;
       end
     else
       if (clear_wc)
	 wc <= 8'b0;
       else
	 if (inc_wc)
	   wc <= wc + 8'b00000001;

   always @(posedge clk)
     if (reset)
       begin
	  bc <= 2'b0;
       end
     else
       if (clear_bc)
	 bc <= 2'b0;
       else
	 if (inc_bc)
	   bc <= bc + 2'b01;

   //
   assign bd_bsy = state != s_idle ? 1'b1 : 1'b0;
   assign bd_err = err;

   //
   always @(posedge clk)
     if (reset)
       lba32 <= 0;
     else
       begin
	  if (inc_lba)
	    lba32 <= lba32 + 32'd512/*32'd1*/;
	  else
	    if (bd_start)
	      lba32 <= { /*8'b0, bd_addr*/ bd_addr[22:0], 9'b0 };
       end

   //
   reg [1:0] r_bd_cmd;
   reg 	     r_bd_start;
   
   always @(posedge clk)
     if (reset)
       begin
	  r_bd_cmd <= 0;
	  r_bd_start <= 0;
       end
     else
       begin
	  r_bd_cmd <= bd_cmd;
	  r_bd_start <= bd_start;
       end

   //   
   always @(posedge clk)
     if (reset)
       inited <= 0;
     else
       if (set_inited)
	 inited <= 1;

   always @(posedge clk)
     if (reset)
       bd_cmd_hold <= 0;
     else
       if (bd_start)
	 bd_cmd_hold <= r_bd_cmd;

   always @(posedge clk)
     if (reset)
       err <= 1'b0;
     else
       if (clear_err)
	 err <= 1'b0;
       else
	 if (set_err)
	   err <= 1'b1;

   // disk state machine
   always @(posedge clk)
     if (reset)
       state <= s_idle;
     else
       begin
	  state <= state_next;
`ifdef debug
	  if (state_next != 0 && state != state_next && debug != 0)
	    $display("mmc_block_dev: state %d", state_next);
`endif
       end

   wire [5:0] mmc_active;
   //assign mmc_active = { mmc_speed, mmc_wr, mmc_rd, mmc_init, mmc_send, mmc_done };
   assign mmc_active = { mmc_speed, 1'b0, mmc_state };
   
   assign bd_state = { mmc_active, state };
   
   // combinatorial logic based on state
   always @(state or r_bd_cmd or bd_cmd_hold or r_bd_start or bd_rd or bd_wr or mmc_done or mmc_out or mmc_hold or bd_data_out)
//   always @(*)
     begin
	state_next = state;

	mmc_cmd = 0;
	mmc_rd = 0;
	mmc_wr = 0;
	mmc_init = 0;
	mmc_send = 0;
	mmc_stop = 0;
	
	mmc_in = 0;

	mmc_hispeed = 0;
	mmc_lospeed = 0;

	clear_err = 0;
	set_err = 0;
	
	clear_wc = 0;
	inc_wc = 0;

	clear_bc = 0;
	inc_bc = 0;

	inc_lba = 0;

	set_inited = 0;

	case (state)
	  s_idle:
	    begin
	       if (r_bd_start)
		 begin
		    case (r_bd_cmd)
		      2'b00: // reset
			begin
			   state_next = s_reset;
			end
		      2'b01: // read
			begin
			   state_next = s_init0;
			end
		      2'b10: // write
			begin
			   state_next = s_init0;
			end
		      2'b11:
			;
		    endcase
`ifdef debug
		    if (debug != 0) 
		      $display("mmc_block_dev: bd_start! bd_cmd %b", r_bd_cmd);
`endif
		 end
	    end

	  s_busy:
	    begin
	       state_next = s_idle;
	    end
	  
	  s_reset:
	    begin
	       mmc_lospeed = 1;
	       mmc_init = 1;
	       if (mmc_done)
		 state_next = s_reset0;
	    end

	  s_reset0:
	    begin
	       state_next = s_reset1;
	    end

	  s_reset1:
	    begin
	       mmc_send = 1;
	       mmc_cmd = CMD01;
	       if (mmc_done)
		 state_next = s_reset2;
	    end
	  
	  s_reset2:
	    begin
	       mmc_rd = 1;
	       if (mmc_done)
		 begin
		    if (mmc_out == 8'h01)
		      state_next = s_reset3;
		    else
//		      if (mmc_out != 8'hff)
		      if (mmc_out[7] == 1'b0)
			state_next = s_reset;
		 end
	    end

	  s_reset3:
	    begin
	       mmc_stop = 1;
	       if (mmc_done)
		 state_next = s_reset4;
	    end
	  
	  s_reset4:
	    begin
	       mmc_send = 1;
	       mmc_cmd = CMD02;
	       if (mmc_done)
		 state_next = s_reset5;
	    end
	  
	  s_reset5:
	    begin
	       mmc_rd = 1;
	       if (mmc_done)
		 begin
		    if(mmc_out == 8'h00)
		      state_next = s_reset7;
		    else
		      if (mmc_out != 8'hff)
			state_next = s_reset6;
		 end
	    end

	  s_reset6:
	    begin
	       mmc_stop = 1;
	       if (mmc_done)
		 state_next = s_reset4;
	    end
	    
	  s_reset7:
	    begin
	       mmc_stop = 1;
	       if (mmc_done)
		 state_next = s_reset8;
	    end
	  
	  s_reset8:
	    begin
//	       mmc_hispeed = 1;
	       mmc_send = 1;
	       mmc_cmd = { 8'h50, 32'd512, 8'h01 };
	       if (mmc_done)
		 state_next = s_reset9;
	    end
	  
	  s_reset9:
	    begin
	       mmc_rd = 1;
	       if (mmc_done && mmc_out == 8'h00)
		 state_next = s_reset10;
	    end

	  s_reset10:
	    begin
	       mmc_stop = 1;
	       if (mmc_done)
		 state_next = s_reset11;
	    end

	  s_reset11:
	    begin
	       set_inited = 1;

	       // if we're resetting automagically, advance to real command
	       if (~inited && bd_cmd_hold != 2'b00)
		 state_next = s_init0;
	       else
		 state_next = s_busy;
	    end
	  
	  s_init0:
	    begin
	       // if we have not inited yet, do init steps
	       if (~inited)
		 state_next = s_reset;
	       else
		 begin
		    mmc_send = 1;
		    mmc_cmd = { 8'hff, 8'hff, 8'hff, 8'hff, 8'hff, 8'hff };
		    if (mmc_done)
		      state_next = s_init1;
		 end
	    end

	  s_init1:
	    begin
	       mmc_send = 1;
	       mmc_cmd = bd_cmd_hold == 2'b10 ? { 8'h58, lba32, 8'h01 } :
			 bd_cmd_hold == 2'b01 ? { 8'h51, lba32, 8'h01 } :
			48'b0;
	       if (mmc_done)
		 state_next = s_init2;
	    end

	  s_init2:
	    begin
	       mmc_rd = 1;
	       if (mmc_done && mmc_out[7] == 0)
		 begin
		    if (mmc_out == 8'h00)
		      state_next = s_init3;
		    else
		      begin
			 set_err = 1;
			 state_next = s_done0;
		      end
		 end
	    end
	  
	  s_init3:
	    begin
	       clear_wc = 1;
		    
	       if (bd_cmd_hold == 2'b10)
		 state_next = s_init5; // write
	       else
		 if (bd_cmd_hold == 2'b01)
		   state_next = s_init4; // read
	    end

	  s_init4:
	    begin
	       // wait for data token
	       mmc_rd = 1;
	       if (mmc_done && mmc_out == 8'hfe)
		 state_next = s_read0;
	    end

	  s_init5:
	    begin
	       // send data token
	       mmc_wr = 1;
	       mmc_in = 8'hfe;
	       if (mmc_done)
		 state_next = s_write0;
	    end

	  s_read0:
	    begin
	       mmc_rd = 1;
	       if (mmc_done)
		 state_next = s_read1;
	    end
	  
	  s_read1:
	    begin
	       mmc_rd = 1;
	       if (mmc_done)
		 state_next = s_read2;
	    end
	  
	  s_read2:
	    begin
	       
	       if (bd_rd)
		 begin
		    inc_wc = 1;
		    if (wc == 8'hff)
		      state_next = s_read3;
		    else
		      state_next = s_read0;
		 end
	    end

	  s_read3:
	    begin
	       // read 2 bytes of crc
	       mmc_rd = 1;
	       if (mmc_done)
		 state_next = s_read4;
	    end
	  
	  s_read4:
	    begin
	       mmc_rd = 1;
	       if (mmc_done)
		 state_next = s_read5;
	    end

	  s_read5:
	    begin
	       mmc_stop = 1;
	       if (mmc_done)
		 state_next = s_read6;
	    end
	  
	  s_read6:
	    begin
	       // read 2nd block
	       inc_bc = 1;
	       inc_lba = 1;
	       if (bc == 2'h01)
		 state_next = s_done0;
	       else
		 state_next = s_init0;
	    end
	  
	  s_write0:
	    begin
	       if (bd_wr)
		 state_next = s_write1;
	    end

	  s_write1:
	    begin
	       mmc_wr = 1;
	       mmc_in = data_hold[7:0];
	       if (mmc_done)
		 state_next = s_write2;
	    end

	  s_write2:
	    begin
	       mmc_wr = 1;
	       mmc_in = data_hold[15:8];

	       if (mmc_done)
		 begin
		    inc_wc = 1;
		    if (wc == 8'hff)
		      state_next = s_write2b/*s_write3*/;
		    else
		      state_next = s_write2a/*s_write0*/;
		 end
	    end

	  s_write2a:
	    begin
	       if (~bd_wr)
		 state_next = s_write0;
	    end
	  
	  s_write2b:
	    begin
	       if (~bd_wr)
		 state_next = s_write3;
	    end
	  
	  s_write3:
	    begin
	       // write 2 bytes of crc
	       mmc_wr = 1;
	       mmc_in = 8'h0;
	       if (mmc_done)
		 state_next = s_write4;
	    end

	  s_write4:
	    begin
	       mmc_wr = 1;
	       mmc_in = 8'h0;
	       if (mmc_done)
		 state_next = s_write5;
	    end
	  
	  s_write5:
	    begin
	       // data response
	       mmc_rd = 1;
	       if (mmc_done)
		 begin
		    if (mmc_out[4] == 1'b0 && mmc_out[0] == 1'b1)
		      begin		      
			 if (mmc_out[3:1] != 3'b010)
			   set_err = 1;
		      end

		    state_next = s_write5a;
		 end
	    end

	  s_write5a:
	    begin
	       // wait for busy signal to clear
	       mmc_rd = 1;
	       if (mmc_done && mmc_out != 8'h00)
		 state_next = s_write6;
	    end

	  s_write6:
	    begin
	       mmc_stop = 1;
	       if (mmc_done)
		 state_next = s_write7;
	    end

	  s_write7:
	    begin
	       inc_bc = 1;
	       inc_lba = 1;
	       if (bc == 2'h01)
		 state_next = s_done0;
	       else
		 state_next = s_init0;
	    end

	  s_done0:
	    begin
	       state_next = s_idle;
	       clear_err = 1;
	       clear_bc = 1;
	    end
	
	  default:
	    begin
	    end
	  
	endcase
     end

   // change speed of spi clock
   always @(posedge clk)
     if (reset)
       mmc_speed <= 0;
     else
       if (mmc_hispeed)
	 mmc_speed <= 1;
       else
       if (mmc_lospeed)
	 mmc_speed <= 0;


   // monitor
`ifdef debug
   always @(state or state_next or r_bd_cmd or bd_cmd_hold or r_bd_start or bd_rd or bd_wr or mmc_done or mmc_out or mmc_hold or bd_data_out or clk)
     begin
	if (debug_state != 0)
	  if (state != state_next && clk)
	  case (state_next)
	    s_reset0: $display("mmc_block_dev: reset");
	    s_reset1: $display("mmc_block_dev: reset1");
	    s_reset2:
	      if (mmc_done) $display("mmc_block_dev: reset2 (mmc_done=%b,mmc_out=%x)",
				     mmc_done, mmc_out);

	    s_reset3: $display("mmc_block_dev: reset3");
	    s_reset4: $display("mmc_block_dev: reset4");

	    s_reset5:
	      if (mmc_done) $display("mmc_block_dev: reset5 (mmc_out=%x)", mmc_out);
	    
	    s_reset6: $display("mmc_block_dev: reset6");
	    s_reset7: $display("mmc_block_dev: reset7");

	    s_reset8:
	      if (mmc_done) $display("mmc_block_dev: reset8 (mmc_done=%b,mmc_out=%x); %t",
				     mmc_done, mmc_out, $time);
	    s_reset9: 
	      if (mmc_done) $display("mmc_block_dev: reset9 (mmc_done=%b,mmc_out=%x,clk=%b); %t",
				     mmc_done, mmc_out, clk, $time);

	    s_reset10: 
	      if (mmc_done) $display("mmc_block_dev: reset10 (mmc_done=%b,clk=%b); %t",
				     mmc_done, clk, $time);
	    s_reset11: $display("mmc_block_dev: reset11; %t", $time);

	    s_init0: $display("mmc_block_dev: init0; %t", $time);
	    s_init1: $display("mmc_block_dev: init1");
	    s_init2: if (mmc_done) $display("mmc_block_dev: init2; mmc_out %x",
							  mmc_out);
	    s_init3: $display("mmc_block_dev: init3");

	    s_read0: if (mmc_done) $display("mmc_block_dev: read0");
	    s_read1: if (mmc_done) $display("mmc_block_dev: read1");
	    s_read2: if (bd_rd) $display("mmc_block_dev: read2 data %o (%x) out %o wc %d",
					 mmc_hold, mmc_hold, bd_data_out, wc);
	    s_read3: $display("mmc_block_dev: s_read3");
	    s_read6: $display("mmc_block_dev: s_read6 bc=%d", bc);

	    s_write2: $display("mmc_block_dev: s_write2 wc=%x", wc);
	    s_write3: $display("mmc_block_dev: s_write3");
	    s_write7: $display("mmc_block_dev: s_write7 bc=%d", bc);

	    s_done0: $display("mmc_block_dev: s_done0");
	   
	  endcase
     end
`endif

`ifdef __CVER__
 `ifdef CHIPSCOPE_MMC_BD
  `undef CHIPSCOPE_MMC_BD
 `endif
`endif
   
`ifdef CHIPSCOPE_MMC_BD
   // chipscope
   wire [35:0] control0;
   wire [39:0] trig0;
   wire        mclk_en;
   wire        mclk;
	
   assign trig0 = {
		   mmc_hold, //16
		   mclk_en,  //1
		   2'b0,     //2
		   mmc_state,//4
		   bd_rdy,   //1
		   bd_iordy, //1
		   mmc_out,  //8
		   mmc_done, //1
		   state     //6
		   };

   assign mclk_en = state != state_next ? 1'b1 : 1'b0;
   assign mclk = clk;
   
   chipscope_icon_mmc_bd icon1 (.CONTROL0(control0));
   chipscope_ila_mmc_bd ila1 (.CONTROL(control0), .CLK(mclk), .TRIG0(trig0));
`endif
   
   
endmodule // mmc_block_dev
