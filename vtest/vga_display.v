// vga_display.v

module vga_display(clk,
		   pixclk,
		   reset,
		   vram_addr,
		   vram_data,
		   vram_req,
		   vram_ready,
		   vga_red,
		   vga_blu,
		   vga_grn,
		   vga_hsync,
		   vga_vsync
		   );

   input clk;
   input pixclk;
   input reset;

   output [14:0] vram_addr;
   input [31:0]  vram_data;
   input 	 vram_ready;
   output 	 vram_req;
   
   output 	 vga_red;
   output 	 vga_blu;
   output 	 vga_grn;
   output 	 vga_hsync;
   output 	 vga_vsync;

// 1280x1024
// 768x896
`define disp_1280x1024
//`define disp_800x600

//http://www.epanorama.net/faq/vga2rgb/calc.html

`ifdef disp_800x600
   // 800x600 @ 50MHz
   parameter H_DISP   =   800;
   parameter V_DISP   =   600;

   parameter BOX_WIDTH  = 768;
   parameter BOX_HEIGHT = 600;
   
   parameter H_FPORCH   =   40;
   parameter H_SYNC     =   128;
   parameter H_BPORCH   =   88;

   parameter V_FPORCH   =   1;
   parameter V_SYNC     =   4;
   parameter V_BPORCH   =   23;
`endif

`ifdef disp_1280x1024
   // 1280X1024 @ 135MHz
   parameter H_DISP   =   1280;
   parameter V_DISP   =   1024;

   parameter BOX_WIDTH  = 768;
   parameter BOX_HEIGHT = 896;
   
   parameter H_FPORCH   =   16;
   parameter H_SYNC     =   144;
   parameter H_BPORCH   =   120/*248*/;

   parameter V_FPORCH   =   1;
   parameter V_SYNC     =   3;
   parameter V_BPORCH   =   38;
`endif
   
   parameter H_BOX_OFFSET = (H_DISP - BOX_WIDTH)/2;	/* (1280-768)/2 */
   parameter V_BOX_OFFSET = (V_DISP - BOX_HEIGHT)/2;	/* (1024-896)/2 */
   
   wire   hsync;
   wire   vsync;
   wire   valid;

   wire   h_in_box;
   wire   v_in_box;
   wire   in_box;

   wire   h_in_border;
   wire   v_in_border;
   wire   in_border;

   wire   vclk;
   
   reg [10:0] h_counter;
   reg [10:0] v_counter;
   
   reg [10:0] h_pos;
   reg [10:0] v_pos;

   reg [14:0] v_addr;

   parameter H_COUNTER_MAX = (H_DISP + H_FPORCH + H_SYNC + H_BPORCH);
   parameter V_COUNTER_MAX = (V_DISP + V_FPORCH + V_SYNC + V_BPORCH);

   assign hsync = h_counter >= (H_DISP+H_FPORCH) &&
		  h_counter < (H_DISP+H_FPORCH+H_SYNC);

   assign vsync = v_counter >= (V_DISP+V_FPORCH) &&
		  v_counter < (V_DISP+V_FPORCH+V_SYNC);

   assign valid = (h_counter <= H_DISP) &&
		  (v_counter <= V_DISP);
   
   assign h_in_box = h_counter >= H_BOX_OFFSET &&
		     h_counter < (H_BOX_OFFSET + BOX_WIDTH);

   assign v_in_box = v_counter >= V_BOX_OFFSET &&
		     v_counter < (V_BOX_OFFSET + BOX_HEIGHT);
   
   assign in_box = valid && h_in_box && v_in_box;

   //
   assign h_in_border = (h_counter == H_BOX_OFFSET-1) ||
			(h_counter == (H_BOX_OFFSET + BOX_WIDTH));

   assign v_in_border = (v_counter == V_BOX_OFFSET-1) ||
			(v_counter == (V_BOX_OFFSET + BOX_HEIGHT));
   
   assign in_border = valid && (h_in_border || v_in_border);
   
   //
   assign vclk = h_counter == H_COUNTER_MAX;
   
   always @(posedge pixclk)
     if (reset)
       h_counter <= 0;
     else
       if (h_counter >= H_COUNTER_MAX)
	 h_counter <= 0;
       else
	 h_counter <= h_counter + 1;
   
   always @(posedge pixclk or posedge reset)
     if (reset)
       v_counter <= 0;
     else
       if (vclk)
	 begin
	    if (v_counter >= V_COUNTER_MAX)
	      v_counter <= 0;
	    else
	      v_counter <= v_counter + 1;
	 end

   //
   always @(posedge pixclk)
     if (reset)
       h_pos <= 0;
     else
       if (h_in_box)
	 begin
	    if (h_pos >= BOX_WIDTH)
	      h_pos <= 0;
	    else
	      h_pos <= h_pos + 1;
	 end
       else
	 h_pos <= 0;

   always @(posedge pixclk or posedge reset)
     if (reset)
       v_pos <= 0;
     else
       if (vclk)
	 begin
	    if (v_in_box)
	      begin
		 if (v_pos >= BOX_HEIGHT-1)
		   v_pos <= 0;
		 else
		   v_pos <= v_pos + 1;
	      end
	    else
	      v_pos <= 0;
	 end
   
   // negative sync
   assign vga_vsync = ~vsync;
   assign vga_hsync = ~hsync;
   
   // -----------------------------------------------------------------------
   //
   //  0..23
   //  0..23
   //
   //
   //        v ram_shift_load 
   // hold 10987654321098765432109876543210
   // shift   10987654321098765432109876543210
   // pixel                                   0
   // shift    x1098765432109876543210987654321
   // pixel                                    1
   // shift     xx109876543210987654321098765432
   // pixel                                     2
   // shift      xxx10987654321098765432109876543
   // pixel                                      3
   // pixclk            1111111111222222222233          1111111111222222222233
   // hpos    0123456789012345678901234567890101234567890123456789012345678901
   //
   // hpos 0..2ff
   //   98 7654 3210
   //         |0..31
   // ------------------------------------------------------------------------

   reg [31:0] ram_data_hold;
   reg [31:0] ram_shift;

   reg 	      ram_req;
   reg 	      ram_data_hold_empty;
   
   wire       ram_shift_load;
   wire       preload, preload1, preload2;
   wire       v_addr_inc;
   
   reg 	      pixel;

   // grab vram_data when ready
   always @(posedge clk)
     if (reset)
       ram_data_hold <= 0;
     else
       if (vram_ready)
	 ram_data_hold <= vram_data;

   // ask for new vram_data when hold empty
   always @(posedge clk)
     if (reset)
       ram_req <= 0;
     else
       ram_req <= ram_data_hold_empty;

   // pixel shift register   
   always @(posedge pixclk)
     if (reset)
       begin
	  ram_shift <= 32'b0;
	  ram_data_hold_empty <= 1'b0;
	  pixel <= 1'b0;
       end
     else
       if (ram_shift_load)
	 begin
	    ram_shift <= ram_data_hold;
	    ram_data_hold_empty <= 1'b1;
	    pixel <= ram_shift[0];
	 end
       else
	 begin
	    ram_shift <= { 1'b0, ram_shift[31:1] };
	    pixel <= ram_shift[0];

	    if (vram_ready)
	      ram_data_hold_empty <= 0;
	 end

   // vram address
   always @(posedge pixclk)
     if (reset)
       v_addr <= 0;
     else
       begin
	  if (~v_in_box)
	    v_addr <= 0;
	  else
	    if (v_addr_inc)
	      v_addr <= v_addr + 1;
       end

   // increment once before visable, don't incr after last load
   assign v_addr_inc = ram_shift_load &&
		       (in_box || preload2) &&
		       (h_pos != BOX_WIDTH-2);

   assign preload1 = h_counter == (H_BOX_OFFSET - 33);

   assign preload2 = h_counter == (H_BOX_OFFSET - 2);

   assign preload = preload1 || preload2;

   assign ram_shift_load = (h_pos[4:0] == 5'h1e) || preload;

   // 32 = 0x20
   // h_pos = 0..2ff / 32 = 0..017
   assign vram_addr = v_addr;

   assign vram_req = ram_req;
   
`ifdef debug_load
   assign vga_red = in_box & ram_shift_load;
   assign vga_blu = in_box && ram_data_hold_empty;
   assign vga_grn = in_box & vram_ready;
//   assign vga_red = in_box & (h_pos[3] & v_counter[3]);
//   assign vga_blu = in_box & (h_pos[3] & v_counter[3]);
//   assign vga_grn = in_box & (h_pos[3] & v_counter[3]);
`else
   assign vga_red = in_box ? pixel : in_border/*1'b0*/;
   assign vga_blu = in_box ? pixel : in_border/*1'b0*/;
   assign vga_grn = in_box ? pixel : in_border;
`endif
   
endmodule
