// vga_display.v

module vga_display(clk,
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

//http://www.epanorama.net/faq/vga2rgb/calc.html

// 1280X1024
   parameter PIXEL_CLK   =   50000;

   parameter H_DISP   =   1280;
   parameter V_DISP   =   1024;

   parameter BOX_WIDTH = 768;
   parameter BOX_HEIGHT = 896;
   
   parameter H_FPORCH   =   48;
   parameter H_SYNC   =   112;
   parameter H_BPORCH   =   248;

   parameter V_FPORCH   =   1;
   parameter V_SYNC   =   3;
   parameter V_BPORCH   =   38;

   parameter H_BOX_OFFSET = (H_DISP - BOX_WIDTH)/8;	/* (1280-768)/2 */
   parameter V_BOX_OFFSET = (V_DISP - BOX_HEIGHT)/2;	/* (1024-896)/2 */
   
   wire   hsync;
   wire   vsync;
   wire   valid;

   wire   h_in_box;
   wire   v_in_box;
   wire   in_box;

   wire   vclk;
   
   reg [10:0] h_counter;
   reg [10:0] v_counter;
   
   reg [10:0] h_pos;
   reg [10:0] v_pos;

   parameter H_COUNTER_MAX = (H_DISP + H_FPORCH + H_SYNC + H_BPORCH);
   parameter V_COUNTER_MAX = (V_DISP + V_FPORCH + V_SYNC + V_BPORCH);

   assign hsync = h_counter >= (H_DISP+H_FPORCH) && h_counter < (H_DISP+H_FPORCH+H_SYNC);

   assign vsync = v_counter >= (V_DISP+V_FPORCH) && v_counter < (V_DISP+V_FPORCH+V_SYNC);

   assign valid = (h_counter <= H_DISP) &&
		  (v_counter <= V_DISP);
   
   assign h_in_box = h_counter >= H_BOX_OFFSET && h_counter < (H_BOX_OFFSET + BOX_WIDTH);
   assign v_in_box = v_counter >= V_BOX_OFFSET && v_counter < (V_BOX_OFFSET + BOX_HEIGHT);
   
   assign in_box = valid && h_in_box && v_in_box;
   
   //
   assign vclk = h_counter == H_COUNTER_MAX;
   
   always @(posedge clk or posedge reset)
     if (reset)
       h_counter <= 0;
     else
       if (h_counter >= H_COUNTER_MAX)
	 h_counter <= 0;
       else
	 h_counter <= h_counter + 1;
   
   always @(posedge vclk or posedge reset)
     if (reset)
       v_counter <= 0;
     else
       if (v_counter >= V_COUNTER_MAX)
	 v_counter <= 0;
       else
	 v_counter <= v_counter + 1;

   //
   always @(posedge clk)
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

   always @(posedge vclk or posedge reset)
     if (reset)
       v_pos <= 0;
     else
       if (v_in_box)
	 begin
	    if (v_pos >= BOX_HEIGHT)
	      v_pos <= 0;
	    else
	      v_pos <= v_pos + 1;
	 end

   //
   assign vga_vsync = ~vsync;
   assign vga_hsync = ~hsync;
   
//   assign vga_red = (valid && ~in_box);
//   assign vga_blu = in_box & ~h_pos[3];
//   assign vga_grn = in_box & h_pos[3];

//   assign vga_red = in_box & (h_pos[3] & v_pos[3]);
//   assign vga_blu = in_box & (h_pos[3] & v_pos[3]);
//   assign vga_grn = in_box & (h_pos[3] & v_pos[3]);

//   assign vga_red = in_box & (v_pos[3]);
//   assign vga_blu = in_box & (v_pos[3]);
//   assign vga_grn = in_box & (v_pos[3]);

//   assign vga_red = in_box & (h_pos[3] & v_counter[3]);
//   assign vga_blu = in_box & (h_pos[3] & v_counter[3]);
//   assign vga_grn = in_box & (h_pos[3] & v_counter[3]);

//   assign vga_red = in_box;
//   assign vga_blu = in_box;
//   assign vga_grn = in_box;

   // ------------------------------------------------------------------------------

   reg [31:0] ram_data_hold;
   reg [31:0] ram_shift;

   reg 	      ram_req;
   reg 	      ram_data_hold_empty;
   
   wire       ram_shift_load;
   wire       pixel;
       
   always @(posedge clk or posedge reset)
     if (reset)
       ram_data_hold <= 0;
     else
       if (vram_ready)
	 ram_data_hold <= vram_data;

   always @(posedge clk or posedge reset)
     if (reset)
       begin
	  ram_shift <= 0;
	  ram_data_hold_empty <= 0;
       end
     else
       if (ram_shift_load)
	 begin
	    ram_shift <= ram_data_hold;
	    ram_data_hold_empty <= 1;
	 end
       else
	 begin
	    ram_shift <= { 1'b0, ram_shift[31:1] };
	    if (vram_ready)
	      ram_data_hold_empty <= 0;
	 end

   always @(posedge clk or posedge reset)
     if (reset)
       ram_req <= 0;
     else
       ram_req <= ram_data_hold_empty;
   
   assign pixel = ram_shift[0];

   wire [4:0] h_pos_95_next;
   assign h_pos_95_next = h_pos[9:5] + 5'd1;
   
   assign ram_shift_load = h_pos[4:0] == 5'h1f;

   // 32 = 0x20
   // h_pos = 0..2ff / 32 = 0..0x18
   assign vram_addr = { v_pos[9:0] , h_pos_95_next };

   assign vram_req = ram_req;
   
   assign vga_red = in_box & pixel;
   assign vga_blu = in_box & pixel;
   assign vga_grn = in_box & pixel;
   
endmodule
