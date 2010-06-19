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
	       clk,
	       reset,
	       addr,
	       datain,
	       dataout,
	       req,
	       ack,
	       write,
	       decode,
	       interrupt
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

   // ----------------------------------------------------------------------
   
   reg [1:0]	 ack_delayed;
   
   wire 	 in_fb;
   wire 	 in_reg;
   wire [14:0] 	 offset;
   
   assign in_fb =  {addr[21:15], 15'b0} == 22'o17000000;
   assign in_reg = {addr[21:3],   3'b0} == 22'o17377760;

   assign offset = addr[14:0];
   
   assign 	 decode = req & (in_reg || in_fb);
   
   reg [1:0]	 busy;
   
   assign 	 ack = busy[1];
   assign 	 interrupt = 0;

`ifdef debug
   integer 	 h, v;
`endif
   
   always @(posedge clk)
     if (reset)
       busy <= 2'b00;
     else
       begin
	  busy[0] <= decode;
	  busy[1] <= busy[0];
	  
	if (decode)
	  if (write)
	    begin
`ifdef debug
               #1 $display("tv: write @%o", addr);
`endif
	       if (in_fb)
		 begin
`ifdef debug
		    h = { 17'b0, offset } / 768;
		    v = { 17'b0, offset } % 768;
		    $display("tv: (%0d, %0d) <- %o", h, v, datain);
`endif
		 end
	    end
	  else
	    begin
`ifdef debug
               #1 $display("tv: read @%o", addr);
`endif
	       if (in_fb)
		 begin
		    dataout = 0;
		 end
	       if (in_reg)
		 dataout = 0;
	    end
     end


endmodule // xbus_tv

