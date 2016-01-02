/*
 * $Id$
 * 
 * height 896
 * width 768
 * 
 * 768 x 896 pixels
 * = 688128 pixels
 * = 21504 words (32 bit) = 52000 octal
 * 
 * xbus = 17000000 + 52000
 *
 * 
 * 1280w x 1024h timing
 * 60hz
 * 16.667ms / frame
 * 
 * pixelclock 108Mhz
 * 
 * h
 * pixels	1280 
 * front porch	48
 * sync		112
 * back portch	248
 * total = 1688
 * 
 * v
 * lines	1024
 * front porch	1 line
 * sync		3 lines
 * back porch	38 lines
 * total = 1066
 * 
 * 768 wide, inside 1280 visable
 * (1280 - 768) / 2 = 256 margin
 * 
 * 896 high, inside 1024 visable
 * (1024 - 896) / 2 = 64
 */

module xbus_tv(
	       clk, reset, addr,
	       datain, dataout,
	       req, ack, write, decode, interrupt,

	       vram_addr, vram_data_in, vram_data_out,
	       vram_req, vram_ready, vram_write, vram_done
	       );

   input clk;
   input reset;
   input [21:0] addr;		/* request address */
   input [31:0] datain;		/* request data */
   input 	req;		/* request */
   input 	write;		/* request read#/write */
   
   output [31:0] dataout;
   reg [31:0] 	 dataout;
   
   output 	 ack;		/* request done */
   output 	 decode;	/* request addr ok */
   output 	 interrupt;

   output [14:0] vram_addr;
   output [31:0] vram_data_out;
   input [31:0]  vram_data_in;
   output 	 vram_req;
   input 	 vram_ready;
   output 	 vram_write;
   input 	 vram_done;
   

   // ----------------------------------------------------------------------

   reg [2:0] 	 fb_state;
   wire [2:0] 	 fb_state_next;

   parameter 	 FB_IDLE = 3'd0,
		   FB_WRITE = 3'd1,
		   FB_READ  = 3'd2,
		   FB_DONE  = 3'd3;

   wire 	 in_fb;
   wire 	 in_reg;
   wire 	 in_color;
   wire [14:0] 	 offset;
   
   assign in_fb    = {addr[21:15], 15'b0} == 22'o17000000;
   assign in_color = {addr[21:15], 15'b0} == 22'o17200000;
   assign in_reg   = {addr[21:3],   3'b0} == 22'o17377760;

   assign offset = addr[14:0];

   // we need to respond to "color probe" even if we're b&w
   assign 	 decode = in_reg || in_fb /*|| in_color*/;

   //A-TV-REGS-BASE (77377760)       ;XBUS ADDRESS 17377760
   //;IN REGISTER 0, BIT 3 IS INTERRUPT ENABLE, BIT 4 IS INTERRUPT FLAG
   
   reg 		 clear_tv_int;
   reg 		 set_tv_int;
   
   reg		 tv_int;
   reg 		 tv_int_en;

   wire 	 fb_write_req;
   wire 	 fb_read_req;
   
   wire 	 start_fb_write;
   wire 	 start_fb_read;

   /* while cpu is requesting... */
   assign fb_write_req = req && decode && write;
   assign fb_read_req = req && decode && ~write;

   /* read/write pulse to memory controller */
   assign start_fb_write = fb_write_req && in_fb;
   assign start_fb_read = fb_read_req && in_fb;
   
`ifdef debug
   integer 	 h, v;
`endif
   
   always @(posedge clk)
     if (reset)
       begin
	  tv_int_en <= 1'b0;
	  dataout <= 0;
       end
     else
       begin
	  clear_tv_int = 0;

	  if (fb_write_req && in_reg)
	    begin
	       tv_int_en <= datain[3];
	       if (datain[4])
		 clear_tv_int = 1;
	    end
	  else

	    if (fb_read_req && in_reg)
	      dataout <= { 27'b0, tv_int, tv_int_en, 3'b0 };
	    else
	      if (in_color)
		dataout <= 32'h0;
	      else
		if (vram_ready)
		  begin
		     dataout <= vram_data_in;
`ifdef debug
		     if (fb_read_req)
		     $display("tv: read @%o out -> %o; %t",
			      addr, vram_data_in, $time);
`endif
		  end

`ifdef debug
	  if (fb_write_req && vram_done)
	    $display("tv: write @%o done <- %o; state %b %t",
		     addr, datain, fb_state, $time);
//	  if (vram_ready)
//	    $display("tv: read @%o done -> %o; state %b %t",
//		     addr, vram_data_in, fb_state, $time);
`endif
	  
       end
   

   assign vram_addr = offset;
   assign vram_data_out = datain;
   assign vram_write = fb_state == FB_WRITE;
   assign vram_req = fb_state == FB_READ;

   /* simple state machine to wait for memory controller */
   always @(posedge clk)
     if (reset)
       fb_state <= FB_IDLE;
     else
       begin
	  fb_state <= fb_state_next;

`ifdef debug
	  if (fb_state == FB_WRITE)
	    $display("tv: write @%o <- %o; %t", addr, datain, $time);

	  if (fb_state == FB_WRITE && fb_state_next == FB_DONE)
	    begin
	       h = { 17'b0, offset } / 768;
	       v = { 17'b0, offset } % 768;
	       $display("tv: write @%o <- %o; %t", addr, datain, $time);
	       $display("tv: (%0d, %0d) <- %o", h, v, datain);
	    end

//	  if (fb_state == FB_READ)
//	    $display("tv: read @%o -> %o (vram_ready %b); %t",
//	  	     addr, vram_data_in, vram_ready, $time);
//	  if (fb_state == FB_DONE)
//	    $display("tv: ack");
`endif
       end

   assign fb_state_next =
			 (fb_state == FB_IDLE && start_fb_write) ? FB_WRITE :
			 (fb_state == FB_IDLE && start_fb_read) ? FB_READ :
			 (fb_state == FB_WRITE && vram_done) ? FB_DONE :
// (fb_state == FB_WRITE) ? FB_DONE :
			 (fb_state == FB_READ && vram_ready) ? FB_DONE :
			 (fb_state == FB_DONE && ~req) ? FB_IDLE :
			 fb_state;

   assign ack = fb_state == FB_DONE;
   
   //----------------------------------------------------------------------
   
   parameter SYS_CLK = 26'd50000000,
	       HZ60_CLK_RATE = 26'd60,
	       HZ60_CLK_DIV = SYS_CLK / HZ60_CLK_RATE;
   
   wire [25:0] hz60_clk_div;
   reg [19:0]  hz60_counter;
   wire        hz60_clk_fired;

   assign hz60_clk_div = HZ60_CLK_DIV;

   assign hz60_clk_fired = hz60_counter == hz60_clk_div[19:0];

   assign interrupt = tv_int_en & tv_int;

   always @(posedge clk)
     if (reset)
       tv_int <= 1'b0;
     else
       if (set_tv_int)
	 tv_int <= 1'b1;
       else
	 if (clear_tv_int)
	   tv_int <= 1'b0;

   // 60hz clock
   always @(posedge clk)
     if (reset)
       hz60_counter <= 0;
     else
       begin
	  set_tv_int = 0;
	  if (hz60_counter == hz60_clk_div[19:0])
	    begin
	       hz60_counter <= 0;
	       set_tv_int = 1;
	    end
	  else
	    hz60_counter <= hz60_counter + 20'd1;
       end

   
endmodule // xbus_tv

