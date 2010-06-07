/*
 * $Id$
 * 
 * height 896
 * width 768
 * 
 * 768 x 896 pixels
 * = 688128 pixels
 * = 21504 words (32 bit)
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
	       pixclk,
	       reset,
	       clk,
	       addr,
	       datain,
	       dataout,
	       req,
	       ack,
	       write,
	       decode,
	       interrupt
	       );

   input pixclk
   input clk;
   input reset;
   input [21:0] addr;		/* request address */
   input [31:0] datain;		/* request data */
   input 	req;		/* request */
   input 	write;		/* request read#/write */
   
   output [31:0] dataout;
   output 	 ack;		/* request done */
   output 	 decode;	/* request addr ok */
   output 	 interrupt;

   //
   reg [10:0]	 hcount;
   reg [10:0] 	 vcount;
   
   reg [31:0] 	 video_ram[21503:0];

   reg [13:0] 	 pixel_addr;
   wire [9:0] 	 video_addr;
   wire [4:0] 	 pixcount;

   assign 	 video_addr = pixel[13:5];
   assign 	 pixcount = pixel_addr[4:0];
   
   // 077000000, size = 210560(8)
   assign 	 decode = req & (addr == 22'o1737776x);
   reg [1:0]	 busy;
   
   assign 	 ack = busy[1];
   assign 	 interrupt = 0;

   always @(posedge clk)
     if (reset)
       busy <= 2'b00;
     else
       begin
	  if (decode)
	    busy[0] <= 1'b1;

	  if (~shifter_load)
	    busy[1] <= busy[0];
	  
	if (decode)
	  if (write)
	    begin
               #1 $display("tv: write @%o", addr);
	    end
	  else
	    begin
               #1 $display("tv: read @%o", addr);
	    end
     end

   write_en = busy[1] & write;
   read_en = busy[1] & ~write;

   video_ram_sync video_ram (
			     .clk(clk),
			     .a(video_addr),
			     .do(video_ram_out),
			     .di(video_ram_in),
			     .we_n(write_en),
			     .ce_n(1'b0)
			     );

xxx clocked ram   
   posted reads
posted writes
   

   parameter H_PIXELS = 1280;
   parameter H_FP = 48;
   parameter H_SYNC = 112;
   parameter H_BP = 248;
   parameter H_BLANK = H_FP + H_SYNC + H_BP;
   parameter HCOUNT_MAX = H_PIXELS + H_BLANK;
			  
   parameter V_LINES = 1024;
   parameter V_FP = 1;
   parameter V_SYNC = 3;
   parameter V_BP = 38;
   parameter V_BLANK = V_FP + V_SYNC + V_BP;
   parameter VCOUNT_MAX = V_LINES + V_BLANK;

   parameter H_MARGIN = 256;
   parameter V_MARGIN = 64;
   
   assign    h_sync = hcount >= H_FP && hcount <= H_SYNC;
   assign    h_blank = hcount < H_BLANK;

   assign    v_sync = vcount >= V_FP && hcount <= V_SYNC;
   assign    v_blank = vcount < V_BLANK;
   
   always @(postedge pixclk)
     if (reset)
       begin
	  hcount <= 0;
	  vcount <= 0;
       end
     else
       if (hcount < HCOUNT_MAX)
	 hcount <= hcount + 1;
       else
	 begin
	    hcount <= 0;
	    if (vcount < VCOUNT_MAX)
	      vcount <= vcount + 1;
	    else
	      vcount <= 0;
	 end

   always @(postedge pixclk)
     if (reset)
       pixel_addr <= 0;
     else
       if (~vblank && ~hblank)
	 pixel_addr <= pixel_addr + 1;
       else
	 if (vblank)
	   pixel_addr <= 0;
   
   assign    shifter_load = pixcount == 0;

   /*
    *         31  30  29  28  27
    *     +++ +++ +++ +++ +++ +++ 
    *     | | | | | | | | | | | |
    *   +++ +++ +++ +++ +++ +++ +++
    *         ^   ^   ^shift
    *         |   shift
    *         load
    */

   reg [31:0] video_shift;
   
   assign pixel_out = video_shift[31];

   always @(posedge pixclk)
     if (reset)
       video_shift <= 0;
     else
       if (shifter_load)
	 video_shift <= video_ram[video_addr];
       else
	 video_shift <= { video_shift[31:1], 1'b0 };

endmodule // xbus_tv

