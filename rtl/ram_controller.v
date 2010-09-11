// ram_controller.v

/* 
 * Simple 4 port ram controller with sram backend
 * used on fpga boards (like the S3 board) which only have sram;
 * basically everything is jammed into the one sdram
 * 
 * ports:
 * 	microcode	r/w, 64 bits
 * 	sdram		r/w, 32 bits
 * 	vram vga	r/o, 32 bits
 * 	vram cpu	r/w, 32 bits
 *
 * CPU states:
 *  | decode | execute | write  | fetch  | decode | execute | write  | fetch  |
 *              s7/s8    s1/s2    s3/s4    s5/s6     s7/s8
 *                         ^        ^
 *                         |        + valid mcr data
 *                         |
 *                         + latch mcr data / mcr write
 *
 *
 *
 *
 *  cpu		controller			ram
 * 
 *  decode					s5/s6
 *  execute					s7/s8
 *  write	prefetch/latch-mcr-data		s1/s2
 *  fetch	fetch				s3/s4
 *
 * NOTE: we're using a 2x clock for the state machine
 * and the outputs are only valid on the even states (2, 4, 6, 8)
 * 
 * states
 * s1		->s2				
 * 		    if mcr-wr-req
 * 			wr mcr hi
 *  		    if ~mcr-wr-req
 * 			latch mcr data hi
 * s2		->s3
 * 		    if mcr-wr-req
 * 			wr mcr lo
 * 		    if ~mcr-wr-req
 * 			latch mcr data lo
 * s3		->s4
 * 		    if vram-vga-reg
 * 			vram-rd; latch vram-vga data
 * s4		->s5
 * 		    if vram-cpu-rd-reg
 * 			vram-rd; latch vram-cpu data
 * 		    if vram-cpu-wr-reg
 * 			vram-wr
 * s5		->s6
 * s6		->s7
 * 		    if sdram-rd-reg
 * 			sdram-rd; latch sdram data
 * 		    if sdram-wr-reg
 * 			sdram-wr
 * s7		->s8
 * s8		->s1
*/

module ram_controller(clk, vga_clk, cpu_clk,
		      reset, prefetch, fetch, machrun, state_out,

		      mcr_addr, mcr_data_out, mcr_data_in,
		      mcr_ready, mcr_write, mcr_done,

		      sdram_addr, sdram_data_in, sdram_data_out,
		      sdram_req, sdram_ready, sdram_write, sdram_done,

		      vram_cpu_addr, vram_cpu_data_in, vram_cpu_data_out,
		      vram_cpu_req, vram_cpu_ready,
		      vram_cpu_write, vram_cpu_done,

		      vram_vga_addr, vram_vga_data_out,
		      vram_vga_req, vram_vga_ready,

		      sram_a, sram_oe_n, sram_we_n,
		      sram1_in, sram1_out, sram1_ce_n, sram1_ub_n, sram1_lb_n,
		      sram2_in, sram2_out, sram2_ce_n, sram2_ub_n, sram2_lb_n);

   input clk;
   input vga_clk;
   input cpu_clk;
   input reset;
   input prefetch;
   input fetch;
   input machrun;
   output [3:0] state_out;
   
   input [13:0]  mcr_addr;
   output [48:0] mcr_data_out;
   input [48:0]  mcr_data_in;
   output 	 mcr_ready;
   input 	 mcr_write;
   output 	 mcr_done;

   input [21:0]  sdram_addr;
   output [31:0] sdram_data_out;
   input [31:0]  sdram_data_in;
   input 	 sdram_req;
   output 	 sdram_ready;
   input 	 sdram_write;
   output 	 sdram_done;

   input [14:0]  vram_cpu_addr;
   output [31:0] vram_cpu_data_out;
   input [31:0]  vram_cpu_data_in;
   input 	 vram_cpu_req;
   output 	 vram_cpu_ready;
   input 	 vram_cpu_write;
   output 	 vram_cpu_done;

   input [14:0]  vram_vga_addr;
   output [31:0] vram_vga_data_out;
   input 	 vram_vga_req;
   output 	 vram_vga_ready;

   output [17:0] sram_a;
   output 	 sram_oe_n;
   output 	 sram_we_n;
   input [15:0]  sram1_in;
   output [15:0] sram1_out;
   input [15:0]  sram2_in;
   output [15:0] sram2_out;
   output 	 sram1_ce_n, sram1_ub_n, sram1_lb_n;
   output 	 sram2_ce_n, sram2_ub_n, sram2_lb_n;

   reg [48:0] 	 mcr_data_out;
   reg [31:0] 	 sdram_data_out;
   reg [31:0] 	 vram_cpu_data_out;
   reg [31:0] 	 vram_vga_data_out;
   
   reg 		 vram_vga_ready;
   reg 		 vram_cpu_ready;
   reg 		 vram_cpu_done;
//   reg 		 sdram_ready;
   reg 		 sdram_done;

wire clk2x;
assign clk2x = vga_clk;
   
   // ---------------------------

   parameter S0 = 0,
	       S1 = 1,
	       S2 = 2,
	       S3 = 3,
	       S4 = 4,
	       S5 = 5,
	       S6 = 6,
	       S7 = 7,
	       S8 = 8;
   
   reg [3:0] 	 state;
   wire [3:0] 	 next_state;

   always @(posedge clk2x)
     if (reset)
       state <= 0;
     else
       state <= next_state;

   assign next_state =
//		      (state == S0 && ~prefetch) ? S0 :
//		      (state == S0 && prefetch) ? S2 :
		      (state == S1 && (machrun && ~prefetch)) ? S1 :
		      (state == S1 && (~machrun || prefetch)) ? S2 :
		      (state == S2) ? S3 :
		      (state == S3) ? S4 :
		      (state == S4) ? S5 :
		      (state == S5) ? S6 :
		      (state == S6) ? S7 :
		      (state == S7) ? S8 :
   		      S1;

   assign state_out = state;
   
   assign 	 mcr_ready = state == S2;
   assign 	 mcr_done = mcr_write && state == S2;
   
//   assign 	 vram_vga_ready = vram_vga_req && state == S3;
   
//   assign 	 vram_cpu_ready = vram_cpu_req && state == S4;
//   assign 	 vram_cpu_done = vram_cpu_write && state == S4;
   
//   assign 	 sdram_ready = sdram_req && state == S5;
//   assign 	 sdram_done = sdram_write && state == S5;

   // ---------------------------

//xxx vram cpu r/w occur in s6; same time as sdram r/w

   wire 	 vram_access;
   wire 	 sdram_access;
   
   assign 	 vram_access = vram_cpu_write || vram_cpu_req;
   assign 	 sdram_access = sdram_write || sdram_req;

   // ram partitions
   //  111
   //  765
   //  00x sdram
   //  01x sdram
   //  10x mcr
   //  11x vram
   
   assign sram_a =
		  (state == S1) ? { 3'b100, mcr_addr, 1'b0 } :
		  (state == S2) ? { 3'b100, mcr_addr, 1'b1 } :
		  (state == S3) ? { 3'b110, vram_vga_addr } :
		  (state == S6 && vram_access) ? { 3'b110, vram_cpu_addr } :
		  (state == S6 && sdram_access) ? { 1'b0, sdram_addr[16:0] } :
		  0;

   assign sram_oe_n =
		     ((state == S1) ||
		      (state == S2) ||
		      (state == S3) ||
		      (state == S6 && vram_cpu_req) ||
		      (state == S6 && sdram_req)) ? 1'b0 :
		     1'b1;

   assign sram_we_n =
		     ((state == S1 && mcr_write) ||
		      (state == S2 && mcr_write) ||
		      (state == S6 && vram_cpu_write) ||
		      (state == S6 && sdram_write)) ? 1'b0 :
		     1'b1;

   assign sram1_ce_n = state != S0 ? 1'b0 : 1'b1;
   assign sram2_ce_n = state != S0 ? 1'b0 : 1'b1;
   
   assign sram1_ub_n = state != S0 ? 1'b0 : 1'b1;
   assign sram1_lb_n = state != S0 ? 1'b0 : 1'b1;

   assign sram2_ub_n = state != S0 ? 1'b0 : 1'b1;
   assign sram2_lb_n = state != S0 ? 1'b0 : 1'b1;

   //
   // [48:0]
   //	{15'b0, [48:32]} [31:0]
   //	{15'b0[48]}, [47:32] [31:16] [15:0]
   //

//`ifdef debug
   wire [48:0] mcr_data_in_x;

   // patch out disk-copy (which takes hours to sim)
   assign mcr_data_in_x = mcr_addr == 14'o24045 ? 49'h000000001000 :mcr_data_in;
// assign mcr_data_in_x = mcr_data_in;
//`endif
   
   assign sram1_out =
		    (state == S1 && mcr_write) ? {15'b0, mcr_data_in_x[48]} :
		    (state == S2 && mcr_write) ? mcr_data_in_x[31:16] :
		    (state == S6 && vram_cpu_write) ? vram_cpu_data_in[31:16] :
		    (state == S6 && sdram_write) ? sdram_data_in[31:16] :
		    16'b0;
		    
   assign sram2_out =
		    (state == S1 && mcr_write) ? mcr_data_in_x[47:32] :
		    (state == S2 && mcr_write) ? mcr_data_in_x[15:0] :
		    (state == S6 && vram_cpu_write) ? vram_cpu_data_in[15:0] :
		    (state == S6 && sdram_write) ? sdram_data_in[15:0] :
		    16'b0;

   // ---------------------------

   always @(posedge clk2x)
     if (reset)
       mcr_data_out <= 0;
     else
       begin
	  if (state == S1)
	    mcr_data_out[48:32] <= { sram1_in[0], sram2_in };

	  if (state == S2)
	    mcr_data_out[31:0] <= { sram1_in, sram2_in };
       end

   // mcr
`ifdef debug_mcr
   always @(posedge clk2x)
     begin
	if (mcr_write)
	  $display("rc: mcr_write state %d", state);
				
	if (state == S1 && mcr_write)
	  $display("rc: mcr_write1 %o -> %o", mcr_addr, mcr_data_in);
	if (state == S2 && mcr_write)
	  $display("rc: mcr_write2 %o -> %o", mcr_addr, mcr_data_in);

	if (state == S1)
	  $display("rc: mcr_read1 %o -> %o", mcr_addr, { sram1_in, sram2_in });
	if (state == S2)
	  $display("rc: mcr_read2 %o -> %o; %t",
		   mcr_addr, { mcr_data_out[48:32], { sram1_in, sram2_in } },
		   $time);
     end
`endif
   
   // vram_vga
   always @(posedge clk2x)
     if (reset)
       begin
	  vram_vga_data_out <= 0;
	  vram_vga_ready <= 0;
       end
     else
       begin
	  if (state == S3 && vram_vga_req)
	    begin
	       vram_vga_data_out <= { sram1_in, sram2_in };
	       vram_vga_ready <= 1;
	    end

	  if (~vram_vga_req && ~state[0])
	    vram_vga_ready <= 0;
       end

   // vram_cpu
   always @(posedge cpu_clk)
     if (reset)
       begin
	  vram_cpu_data_out <= 0;
	  vram_cpu_ready <= 0;
	  vram_cpu_done <= 0;
       end
     else
       begin
	  if (state == S6)
	    begin
	       if (vram_cpu_req)
		 begin
		    vram_cpu_data_out <= { sram1_in, sram2_in };
		    vram_cpu_ready <= 1;
		 end
	       else
		 if (vram_cpu_write)
		   vram_cpu_done <= 1;
	    end
	  
	  if (~vram_cpu_req)
	    vram_cpu_ready <= 0;
	  if (~vram_cpu_write)
	    vram_cpu_done <= 0;
       end

`ifdef debug
   always @(posedge cpu_clk)
     if (state == S6 && vram_cpu_write)
       $display("vram: W addr %o <- %o; %t",
		vram_cpu_addr, vram_cpu_data_in, $time);

   always @(posedge cpu_clk)
     if (vram_cpu_write)
       $display("vram: W addr %o <- %o; state %d %t",
		vram_cpu_addr, vram_cpu_data_in, state, $time);
`endif
   
`ifdef old_way
   // sdram
   always @(posedge cpu_clk)
     if (reset)
       begin
	  sdram_data_out <= 0;
	  sdram_rdy <= 0;
	  sdram_done <= 0;
       end
     else
       begin
	  if (state == S6)
	    begin
	       if (sdram_req)
		 begin
`ifdef debug
		    $display("rc: sdram_req %o -> %o",
			     sdram_addr, { sram1_in, sram2_in });
`endif
		    sdram_data_out <= { sram1_in, sram2_in };
		    sdram_rdy <= 1;
		 end
	       else
		 if (sdram_write)
		   begin
`ifdef debug
		      $display("rc: sdram_write %o", sdram_addr);
`endif
		      sdram_done <= 1;
		   end
	    end
	  
	  if (~sdram_req)
	    sdram_rdy <= 0;
	  if (~sdram_write)
	    sdram_done <= 0;
       end

`else

   reg sdram_rdy;
   
   // sdram
   always @(posedge cpu_clk)
     if (reset)
       begin
	  sdram_data_out <= 0;
	  sdram_rdy <= 0;
	  sdram_done <= 0;
       end
     else
       begin
	  if (state == S6)
	    begin
	       if (sdram_req && ~sdram_rdy)
		 begin
`ifdef debug
		    $display("rc: sdram_req %o -> %o",
			     sdram_addr, { sram1_in, sram2_in });
`endif
//		    sdram_data_out <= { sram1_in, sram2_in };
sdram_data_out <= sdram_addr[21:17] == 0 ? {sram1_in, sram2_in} : 32'hffffffff;
		    sdram_rdy <= 1;
		 end
	       else
		 if (sdram_write)
		   begin
`ifdef debug
		      $display("rc: sdram_write %o", sdram_addr);
`endif
		      sdram_done <= 1;
		   end
	    end
	  
	  if (~sdram_req)
	    sdram_rdy <= 0;
	  if (~sdram_write)
	    sdram_done <= 0;
       end

   //
   reg [10:0] sdram_rdy_delay;

   assign     sdram_ready = sdram_rdy_delay[1];
   
   always @(posedge cpu_clk)
     if (reset)
       sdram_rdy_delay <= 0;
     else
       begin
	  sdram_rdy_delay[0] <= sdram_rdy & ~|sdram_rdy_delay;
	  sdram_rdy_delay[1] <= sdram_rdy_delay[0];
	  sdram_rdy_delay[2] <= sdram_rdy_delay[1];
	  sdram_rdy_delay[3] <= sdram_rdy_delay[2];
	  sdram_rdy_delay[4] <= sdram_rdy_delay[3];
	  sdram_rdy_delay[5] <= sdram_rdy_delay[4];
//  	  sdram_rdy_delay[6] <= sdram_rdy_delay[5];
//	  sdram_rdy_delay[7] <= sdram_rdy_delay[6];
//	  sdram_rdy_delay[8] <= sdram_rdy_delay[7];
//	  sdram_rdy_delay[9] <= sdram_rdy_delay[8];
//	  sdram_rdy_delay[10] <= sdram_rdy_delay[9];
       end
`endif
       
endmodule
  
