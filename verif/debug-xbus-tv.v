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
reg [31:0] dataout;
   
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

`ifdef debug
   reg [31:0] 	 fb[0:21503];
   integer 	 i;

   initial
     for (i = 0; i < 21504; i = i + 1)
       fb[i] = 0;
`endif
   
   reg [1:0]	 ack_delayed;
   
   wire 	 in_fb;
   wire 	 in_reg;
   wire 	 in_color;
   wire [14:0] 	 offset;
   
   assign in_fb    =  {addr[21:15], 15'b0} == 22'o17000000;
   assign in_reg   = {addr[21:3],   3'b0} == 22'o17377760;
   assign in_color = {addr[21:15], 15'b0} == 22'o17200000;

   assign offset = addr[14:0];

   // we need to respond to "color probe" even if we're b&w
   assign 	 decode = req & (in_reg || in_fb /*|| in_color*/);

   //A-TV-REGS-BASE (77377760)       ;XBUS ADDRESS 17377760
   //;IN REGISTER 0, BIT 3 IS INTERRUPT ENABLE, BIT 4 IS INTERRUPT FLAG
   
   reg [1:0]	 busy;
   
   assign 	 ack = busy[1];

   reg 		 clear_tv_int;
   reg 		 set_tv_int;
   
   reg		 tv_int;
   reg 		 tv_int_en;
   
`ifdef debug
   integer 	 h, v;
`endif
   
   always @(posedge clk)
     if (reset)
       begin
	  busy <= 2'b00;
	  tv_int_en <= 1'b0;
       end
     else
       begin
	  busy[0] <= decode;
	  busy[1] <= busy[0];

	  clear_tv_int = 0;
	  
	  if (decode)
	    if (write)
	      begin
`ifdef debug
		 `DBG_DLY $display("tv: write @%o <- %o", addr, datain);
`endif
		 if (in_fb)
		   begin
`ifdef debug
		      h = { 17'b0, offset } / 768;
		      v = { 17'b0, offset } % 768;
		      $display("tv: (%0d, %0d) <- %o", h, v, datain);

		      fb[offset] <= datain;
`endif
		   end

		 if (in_reg)
		   begin
		      tv_int_en <= datain[3];
		      if (datain[4])
			clear_tv_int = 1;
		   end
	      end
	    else
	      begin
`ifdef debug
		 `DBG_DLY $display("tv: read @%o -> %o", addr, fb[offset]);
`endif
		 if (in_fb)
		   begin
`ifdef debug
		      dataout <= fb[offset];
`endif
		   end
		 else
		   if (in_reg)
		     dataout <= { 27'b0, tv_int, tv_int_en, 3'b0 };
		   else
		     if (in_color)
		       dataout <= 32'h0;
	      end
       end
   

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
//	       set_tv_int = 1;
	    end
	  else
	    hz60_counter <= hz60_counter + 20'd1;
       end

   assign vram_addr = 0;
   assign vram_data_out = 0;
   assign vram_req = 0;
   assign vram_write = 0;
   
endmodule // xbus_tv

