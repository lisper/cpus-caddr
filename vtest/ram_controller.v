// ram_controller.v

module ram_controller(clk, reset,
		      mcr_addr, mcr_data_out, mcr_data_in,
		      mcr_ready, mcr_write, mcr_done,
		      sdram_addr, sdram_data_in, sdram_data_out,
		      sdram_req, sdram_ready, sdram_write, sdram_done,
		      vram_addr, vram_data_in, vram_data_out,
		      vram_req, vram_ready, vram_write, vram_done,
		      sram_a, sram_oe_n, sram_we_n,
		      sram1_io, sram1_ce_n, sram1_ub_n, sram1_lb_n,
		      sram2_io, sram2_ce_n, sram2_ub_n, sram2_lb_n);

   input clk;
   input reset;
   
   input [11:0]  mcr_addr;
   output [51:0] mcr_data_out;
   input [51:0]  mcr_data_in;
   output 	 mcr_ready;
   input 	 mcr_write;
   output 	 mcr_done;

   input [17:0]  sdram_addr;
   output [31:0] sdram_data_out;
   input [31:0]  sdram_data_in;
   output 	 sdram_ready;
   input 	 sdram_req;
   input 	 sdram_write;
   output 	 sdram_done;

   input [14:0]  vram_addr;
   output [31:0] vram_data_out;
   input [31:0]  vram_data_in;
   output 	 vram_ready;
   input 	 vram_req;
   input 	 vram_write;
   output 	 vram_done;
   
   output [17:0] sram_a;
   output 	 sram_oe_n;
   output 	 sram_we_n;
   inout [15:0]  sram1_io;
   inout [15:0]  sram2_io;
   output 	 sram1_ce_n, sram1_ub_n, sram1_lb_n;
   output 	 sram2_ce_n, sram2_ub_n, sram2_lb_n;

   // ---------------------------

   parameter S_MCR_RD1 = 1,
	       S_MCR_RD2 = 2,
	       S_MCR_WR1 = 3,
	       S_MCR_WR2 = 4,
	       S_SDRAM_RD = 5,
	       S_SDRAM_WR = 6,
	       S_VRAM_RD = 7,
	       S_VRAM_WR = 8;
   
   reg [3:0] 	 state;
   wire [3:0] 	 next_state;

   always @(posedge clk)
     if (reset)
       state <= 0;
     else
       state <= next_state;

   assign next_state =
		      (state == 0) ? S_MCR_RD1 :
		      (state == S_MCR_RD1) ? S_MCR_RD2 :
		      (state == S_MCR_RD2 && mcr_write) ? S_MCR_WR1 :
		      (state == S_MCR_RD2 && sdram_req) ? S_SDRAM_RD :
		      (state == S_MCR_RD2 && sdram_write) ? S_SDRAM_WR :
		      (state == S_MCR_RD2 && vram_req) ? S_VRAM_RD :
		      (state == S_MCR_RD2 && vram_write) ? S_VRAM_WR :
		      (state == S_MCR_WR1) ? S_MCR_WR2 :
		      (state == S_MCR_WR2) ? 0 :
		      (state == S_SDRAM_RD) ? 0 :
		      (state == S_SDRAM_WR) ? 0 :
		      (state == S_VRAM_RD) ? 0 :
		      (state == S_VRAM_WR) ? 0 :
		      0;
   
   assign 	 mcr_ready = state == S_MCR_RD2;
   assign 	 mcr_done = state == S_MCR_WR1;
   
   assign 	 sdram_ready = state == S_SDRAM_RD;
   assign 	 sdram_done = state == S_SDRAM_WR;

   assign 	 vram_ready = state == S_VRAM_RD;
   assign 	 vram_done = state == S_VRAM_WR;
   
   // ---------------------------

   assign sram_a =
    (state == S_MCR_RD1 || state == S_MCR_WR1) ? { 5'b01000, mcr_addr, 1'b0 } :
    (state == S_MCR_RD2 || state == S_MCR_WR2) ? { 5'b01000, mcr_addr, 1'b1 } :
    (state == S_SDRAM_RD || state == S_SDRAM_WR) ? { 2'b00, sdram_addr[14:0] } :
    (state == S_VRAM_RD || state == S_VRAM_WR) ? { 2'b11, vram_addr } :
    0;

   assign sram_oe_n =
		     (state == S_MCR_RD1 || state == S_MCR_RD2 ||
		      state == S_SDRAM_RD || state == S_VRAM_RD) ? 1'b0 :
		     1'b1;

   assign sram_we_n =
		     (state == S_MCR_WR1 || state == S_MCR_WR2 ||
		      state == S_SDRAM_WR || state == S_VRAM_WR) ? 1'b0 :
		     1'b1;

   assign sram1_ce_n = state != 0 ? 1'b0 : 1'b1;
   assign sram2_ce_n = state != 0 ? 1'b0 : 1'b1;
   
   assign sram1_ub_n = state != 0 ? 1'b0 : 1'b1;
   assign sram1_lb_n = state != 0 ? 1'b0 : 1'b1;

   assign sram2_ub_n = state != 0 ? 1'b0 : 1'b1;
   assign sram2_lb_n = state != 0 ? 1'b0 : 1'b1;

   //
   // [51:0]
   //	{12'b0, [51:32]} [31:0]
   //	{12'b0[51:48]}, [47:32] [31:16] [15:0]
   //
   assign sram1_io =
		    (state == S_MCR_WR1) ? {12'b0, mcr_data_in[51:48]} :
		    (state == S_MCR_WR2) ? mcr_data_in[31:16] :
		    (state == S_SDRAM_WR) ? sdram_data_in[31:16] :
		    (state == S_VRAM_WR) ? vram_data_in[31:16] :
		     31'bz;
		    
   assign sram2_io =
		    (state == S_MCR_WR1) ? mcr_data_in[47:32] :
		    (state == S_MCR_WR2) ? mcr_data_in[15:0] :
		    (state == S_SDRAM_WR) ? sdram_data_in[15:0] :
		    (state == S_VRAM_WR) ? vram_data_in[15:0] :
		     31'bz;


   // ---------------------------

   reg [31:0] mcr_hold;

   always @(posedge clk/* or posedge reset*/)
     if (reset)
       mcr_hold <= 0;
     else
	  if (state == S_MCR_RD1)
	    mcr_hold <= { sram1_io, sram2_io };
   
   assign mcr_data_out = (state == S_MCR_RD2) ?
			 { mcr_hold, sram1_io, sram2_io } :
			 52'b0;
   
   assign sdram_data_out = (state == S_SDRAM_RD) ? { sram1_io, sram2_io } :
			   32'b0;

//`define debug   
`ifdef debug
   wire [4:0] voffset;
   assign     voffset = (vram_addr / 24) % 32;

   assign vram_data_out =
     ~vram_addr[0] ? (
	voffset == 5'h0 ?  32'b00111111100000000000000000111100 :
	voffset == 5'h1 ?  32'b01000000100000000000000001000010 :
	voffset == 5'h2 ?  32'b01000000100000000000000010000001 :
	voffset == 5'h3 ?  32'b00111111100000000000000011111111 :
	voffset == 5'h4 ?  32'b01000000100000000000000010000001 :
	voffset == 5'h5 ?  32'b01000000100000000000000010000001 :
	voffset == 5'h6 ?  32'b01000000100000000000000010000001 :
	voffset == 5'h7 ?  32'b00111111100000000000000010000001 :
	voffset == 5'he ?  32'b11111111111111111111111111111111 :
	voffset == 5'h10 ? 32'b00111111100000000000000000111110 :
	voffset == 5'h11 ? 32'b01000000100000000000000001000001 :
	voffset == 5'h12 ? 32'b01000000100000000000000000000001 :
	voffset == 5'h13 ? 32'b01000000100000000000000000000001 :
	voffset == 5'h14 ? 32'b01000000100000000000000000000001 :
	voffset == 5'h15 ? 32'b01000000100000000000000000000001 :
	voffset == 5'h16 ? 32'b01000000100000000000000001000001 :
	voffset == 5'h17 ? 32'b00111111100000000000000000111110 :
	voffset == 5'h1e ? 32'b11111111111111111111111111111111 :
	0
		    ) : (
	voffset == 5'h0 ?  32'b01111111100000000000000011111111 :
	voffset == 5'h1 ?  32'b01000000100000000000000000011000 :
	voffset == 5'h2 ?  32'b01000000100000000000000000011000 :
	voffset == 5'h3 ?  32'b01000000100000000000000000011000 :
	voffset == 5'h4 ?  32'b01000000100000000000000000011000 :
	voffset == 5'h5 ?  32'b01000000100000000000000000011000 :
	voffset == 5'h6 ?  32'b01000000100000000000000000011000 :
	voffset == 5'h7 ?  32'b01111111100000000000000011111111 :
	voffset == 5'he ?  32'b11111111111111111111111111111111 :

	voffset == 5'h10 ? 32'b00111111000000000000000000011100 :
	voffset == 5'h11 ? 32'b01000001100000000000000000011110 :
	voffset == 5'h12 ? 32'b01000010100000000000000000011011 :
	voffset == 5'h13 ? 32'b01000100100000000000000000011000 :
	voffset == 5'h14 ? 32'b01001000100000000000000000011000 :
	voffset == 5'h15 ? 32'b01010000100000000000000000011000 :
	voffset == 5'h16 ? 32'b01100000100000000000000000011000 :
	voffset == 5'h17 ? 32'b00111111000000000000000001111111 :

	voffset == 5'h1e ? 32'b11111111111111111111111111111111 :
	0
		    );
`else
   assign vram_data_out = (state == S_VRAM_RD) ? { sram1_io, sram2_io } :
			  32'b0;
`endif

endmodule
