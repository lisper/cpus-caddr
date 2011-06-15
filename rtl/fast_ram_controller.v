// fast_ram_controller.v

/* 
 * Basic 4 port ram controller with sram backend
 * used on fpga boards (like the S3 board) which only have sram;
 * basically everything is jammed into the one sdram
 * 
 * This version runs at 8x the main clock and hides all it's activity, using
 * two different state machines.  The 8x machine does the real work and samples
 * signals from the 1x machine.  The 1x machine services the cpu requests and
 * samples signals from the 8x machine.
 * 
 * ports:
 * 	microcode	r/w, 64 bits
 * 	sdram		r/w, 32 bits
 * 	vram vga	r/o, 32 bits
 * 	vram cpu	r/w, 32 bits
 *
 * CPU states:
 *  | decode | execute | write  | fetch  | decode | execute | write  | fetch  |
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
 *  decode					
 *  execute					
 *  write	prefetch/latch-mcr-data		
 *  fetch	fetch				
 *
 * states
 * S_MCR_WR1 -> S_MCR_WR2
 * 		assert address & data
 * S_MCR_WR2 -> S_MCR_WR3
 * 		we, wr mcr hi
 * S_MCR_WR3 -> S_MCR_WR3
 * 		assert address & data
 * S_MCR_WR4
 * 		we, wr mcr lo
 * S_VGA_RD
 * 		vram-rd; latch vram-vga data
 * S_MCR_RD1 -> S_MCR_RD2
 * 		latch mcr data hi
 * S_MCR_RD2
 * 		latch mcr data lo
 * S_VRAM_WR1 -> S_VRAM_WR2
 * 		assert address & data
 * S_VRAM_WR2
 * 		we, vram-wr
 * S_VRAM_RD
 * 		vram-rd; latch vram-cpu data
 * S_SDRAM_RD
 * 		sdram-rd; latch sdram data
 * S_SDRAM_WR1 -> S_SDRAM_WR2
 * 		assert address & data
 * S_SDRAM_WR2
 * 		we, sdram-wr
*/

module fast_ram_controller(
			   clk, vga_clk, cpu_clk,
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

			   sram1_in, sram1_out, sram1_ce_n,
			   sram1_ub_n, sram1_lb_n,

			   sram2_in, sram2_out, sram2_ce_n,
			   sram2_ub_n, sram2_lb_n);

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
   input [15:0]  sram2_in;
   output [15:0]  sram1_out;
   output [15:0]  sram2_out;
   output 	 sram1_ce_n, sram1_ub_n, sram1_lb_n;
   output 	 sram2_ce_n, sram2_ub_n, sram2_lb_n;

   reg 		 vram_vga_ready;
//   reg 		 vram_cpu_ready;
   reg 		 vram_cpu_done;
   reg 		 sdram_done;
   reg 		 sdram_rdy;

   reg 		 mcr_ready;
   reg 		 mcr_done;
   
   wire 	 mcr_req;

   reg 		 int_mcr_ready;
   reg 		 int_mcr_done;
   reg 		 int_vram_cpu_ready;
   reg 		 int_vram_cpu_done;
   reg 		 int_sdram_done;
   reg 		 int_sdram_rdy;
   
   reg [14:0] 	 vram_cpu_addr_d;
   reg [31:0] 	 vram_cpu_data_in_d;
   
   // ---------------------------

//   parameter S_IDLE        = 0,
//	       S_VGA_RD    = 1,
//	       S_MCR_RD1   = 2,
//	       S_MCR_RD2   = 3,
//	       S_MCR_WR1   = 4,
//	       S_MCR_WR2   = 5,
//	       S_MCR_WR3   = 6,
//	       S_MCR_WR4   = 7,
//	       S_SDRAM_RD  = 8,
//	       S_SDRAM_WR1 = 9,
//	       S_SDRAM_WR2 = 10,
//	       S_VRAM_RD   = 11,
//	       S_VRAM_WR1  = 12,
//	       S_VRAM_WR2  = 13;
   parameter S_IDLE        = 14'b0,
	       S_VGA_RD    = 14'b00000000000001,
	       S_MCR_RD1   = 14'b00000000000010,
	       S_MCR_RD2   = 14'b00000000000100,
	       S_MCR_WR1   = 14'b00000000001000,
	       S_MCR_WR2   = 14'b00000000010000,
	       S_MCR_WR3   = 14'b00000000100000,
	       S_MCR_WR4   = 14'b00000001000000,
	       S_SDRAM_RD  = 14'b00000010000000,
	       S_SDRAM_WR1 = 14'b00000100000000,
	       S_SDRAM_WR2 = 14'b00001000000000,
	       S_VRAM_RD   = 14'b00010000000000,
	       S_VRAM_WR1  = 14'b00100000000000,
	       S_VRAM_WR2  = 14'b01000000000000;
   
   reg [13:0] 	 state; // synthesis attribute fsm_encoding of state is one-hot
   wire [13:0] 	 next_state;

   always @(posedge clk)
     if (reset)
       state <= S_IDLE;
     else
       state <= next_state;

   wire vram_vga_req_sync;

   assign next_state =
      (state == S_IDLE && mcr_req && ~mcr_write && ~int_mcr_ready) ? S_MCR_RD1 :
      (state == S_MCR_RD1) ? S_MCR_RD2 :
      (state == S_MCR_RD2) ? S_IDLE :
      (state == S_IDLE && mcr_write) ? S_MCR_WR1 :
      (state == S_MCR_WR1) ? S_MCR_WR2 :
      (state == S_MCR_WR2) ? S_MCR_WR3 :
      (state == S_MCR_WR3) ? S_MCR_WR4 :
      (state == S_MCR_WR4) ? S_IDLE :
      (state == S_IDLE && vram_vga_req_sync && ~vram_vga_ready) ? S_VGA_RD :
      (state == S_VGA_RD) ? S_IDLE :
      (state == S_IDLE && sdram_req && ~int_sdram_rdy) ? S_SDRAM_RD :
      (state == S_SDRAM_RD) ? S_IDLE :
      (state == S_IDLE && sdram_write && ~int_sdram_done) ? S_SDRAM_WR1 :
      (state == S_SDRAM_WR1) ? S_SDRAM_WR2 :
      (state == S_SDRAM_WR2) ? S_IDLE :
      (state == S_IDLE && vram_cpu_req && ~int_vram_cpu_ready) ? S_VRAM_RD :
      (state == S_VRAM_RD) ? S_IDLE :
      (state == S_IDLE && vram_cpu_write && ~int_vram_cpu_done) ? S_VRAM_WR1 :
      (state == S_VRAM_WR1) ? S_VRAM_WR2 :
      (state == S_VRAM_WR2) ? S_IDLE :
      S_IDLE;
   
   assign state_out = state;
   
   // ---------------------------

   wire 	 vram_access;
   wire 	 sdram_access;
   
   assign 	 vram_access = vram_cpu_write || vram_cpu_req;
   assign 	 sdram_access = sdram_write || sdram_req;

   // sram partition map:
   //  111
   //  765
   //  00x sdram
   //  01x sdram
   //  10x mcr
   //  11x vram

   wire sram_a_sdram;
   wire sram_a_mcr_h;
   wire sram_a_mcr_l;
   wire sram_a_vga;
   wire sram_a_vram;

   assign sram_a_sdram =
	state == S_SDRAM_RD || state == S_SDRAM_WR1 || state == S_SDRAM_WR2;

   assign sram_a_mcr_h =
	state == S_MCR_RD1 || state == S_MCR_WR1 || state == S_MCR_WR2;

   assign sram_a_mcr_l =
	state == S_MCR_RD2 || state == S_MCR_WR3 || state == S_MCR_WR4;

   assign sram_a_vga =
	state == S_VGA_RD;

   assign sram_a_vram = 
	state == S_VRAM_RD || state == S_VRAM_WR1 || state == S_VRAM_WR2;
   
   assign sram_a =
		  sram_a_sdram ? { 1'b0, sdram_addr[16:0] } :
		  sram_a_mcr_h ? { 3'b100, mcr_addr, 1'b0 } :
		  sram_a_mcr_l ? { 3'b100, mcr_addr, 1'b1 } :
		  sram_a_vga   ? { 3'b110, vram_vga_addr } :
		  sram_a_vram  ? { 3'b110, vram_cpu_addr_d } :
		  0;

   assign sram_oe_n =
		     ((state == S_VGA_RD) ||
		      (state == S_MCR_RD1 || state == S_MCR_RD2) ||
		      (state == S_VRAM_RD) ||
		      (state == S_SDRAM_RD)) ? 1'b0 :
		     1'b1;

   assign sram_we_n =
		     ((state == S_MCR_WR2 || state == S_MCR_WR4) ||
		      (state == S_SDRAM_WR2) ||
		      (state == S_VRAM_WR2)) ? 1'b0 :
		     1'b1;

   assign sram1_ce_n = state != S_IDLE ? 1'b0 : 1'b1;
   assign sram2_ce_n = state != S_IDLE ? 1'b0 : 1'b1;
   
   assign sram1_ub_n = state != S_IDLE ? 1'b0 : 1'b1;
   assign sram1_lb_n = state != S_IDLE ? 1'b0 : 1'b1;

   assign sram2_ub_n = state != S_IDLE ? 1'b0 : 1'b1;
   assign sram2_lb_n = state != S_IDLE ? 1'b0 : 1'b1;

   //
   // [48:0]
   //	{15'b0, [48:32]} [31:0]
   //	{15'b0[48]}, [47:32] [31:16] [15:0]
   //

//`ifdef debug
   wire [48:0] mcr_data_in_x;

   // patch out disk-copy (which takes hours to sim)
//   assign mcr_data_in_x = mcr_addr == 14'o24045 ? 49'h000000001000 :mcr_data_in;
 assign mcr_data_in_x = mcr_data_in;
//`endif
   
   assign sram1_out =
    (state == S_MCR_WR1 || state == S_MCR_WR2) ? {15'b0, mcr_data_in_x[48]} :
    (state == S_MCR_WR3 || state == S_MCR_WR4) ? mcr_data_in_x[31:16] :
    (state == S_VRAM_WR1 || state == S_VRAM_WR2)   ? vram_cpu_data_in_d[31:16] :
    (state == S_SDRAM_WR1 || state == S_SDRAM_WR2) ? sdram_data_in[31:16] :
    16'b0;
		    
   assign sram2_out =
    (state == S_MCR_WR1 || state == S_MCR_WR2) ? mcr_data_in_x[47:32] :
    (state == S_MCR_WR3 || state == S_MCR_WR4) ? mcr_data_in_x[15:0] :
    (state == S_VRAM_WR1 || state == S_VRAM_WR2) ? vram_cpu_data_in_d[15:0] :
    (state == S_SDRAM_WR1 || state == S_SDRAM_WR2) ? sdram_data_in[15:0] :
    16'b0;

   // ---------------------------

`define original_mcr
`ifdef original_mcr
   reg [48:0] 	 mcr_out;

   // mcr read - internal
   always @(posedge clk)
     if (reset)
       begin
	  mcr_out <= 0;
	  int_mcr_ready <= 0;
	  int_mcr_done <= 0;
       end
     else
       begin
	  if (state == S_MCR_RD1 && ~int_mcr_ready)
	    begin
	       mcr_out[48:32] <= { sram1_in[0], sram2_in };
	    end
	  else
	    if (state == S_MCR_RD2 && ~int_mcr_ready)
	      begin
		 mcr_out[31:0] <= { sram1_in, sram2_in };
		 int_mcr_ready <= 1;
	      end
	    else
	      if (state == S_MCR_WR2 && ~int_mcr_done)
		int_mcr_done <= 1;

	  if (~mcr_req)
	    int_mcr_ready <= 0;
	  if (~mcr_write)
	    int_mcr_done <= 0;
       end

   // mcr read - cpu interface
   assign mcr_req = prefetch;

   assign mcr_data_out = mcr_out;

   always @(posedge cpu_clk)
     if (reset)
       begin
	  mcr_ready <= 0;
	  mcr_done <= 0;
       end
     else
       begin
	  if (int_mcr_ready)
	    begin
`ifdef debug_mcr
	       if (~mcr_ready)
		   $display("rc: mcr %o", mcr_data_out);
`endif
	       mcr_ready <= 1;
	    end
	  else
	    if (int_mcr_done)
	      begin
		 mcr_done <= 1;
	      end

	  if (~mcr_req)
	    mcr_ready <= 0;
	  if (~mcr_write)
	    mcr_done <= 0;
       end
   
`ifdef debug_mcr
   always @(posedge clk)
     begin
	if (mcr_write)
	  $display("rc: mcr_write state %d", state);
				
	if (state == S_MCR_WR1)
	  $display("rc: mcr_write1 %o -> %o", mcr_addr, mcr_data_in);
	if (state == S_MCR_WR2)
	  $display("rc: mcr_write2 %o -> %o", mcr_addr, mcr_data_in);

	if (state == S_MCR_RD1)
	  $display("rc: mcr_read1 %o -> %o", mcr_addr, { sram1_in, sram2_in });
	if (state == S_MCR_RD2)
	  $display("rc: mcr_read2 %o -> %o; %t",
		   mcr_addr, { mcr_data_out[48:32], { sram1_in, sram2_in } },
		   $time);
     end
`endif

`endif

   // vram_vga read - vga controller only
   reg [1:0] vram_vga_req_syncro;
   
   always @(posedge clk)
     if (reset)
       vram_vga_req_syncro <= 0;
     else
       begin
	  vram_vga_req_syncro[0] <= vram_vga_req;
	  vram_vga_req_syncro[1] <= vram_vga_req_syncro[0];
       end

   assign vram_vga_req_sync = vram_vga_req_syncro[1];
   
   //   
   reg [31:0] 	 vram_cpu_data;
   reg [31:0] 	 vram_vga_data;

   always @(posedge clk)
     if (reset)
       begin
	  vram_vga_data <= 0;
	  vram_vga_ready <= 0;
       end
     else
       begin
	  if (state == S_VGA_RD)
	    begin
	       vram_vga_data <= { sram1_in, sram2_in };
	       vram_vga_ready <= 1;
`ifdef debug
	       $display("rc: vram vga read %o -> %o",
			vram_vga_addr, { sram1_in, sram2_in });
`endif
	    end

	  if (~vram_vga_req_sync)
	    vram_vga_ready <= 0;
       end

   assign vram_vga_data_out = vram_vga_data;
   
`define original_vga   
`ifdef original_vga
   // vram_cpu read/write

   // vram_cpu - internal
   always @(posedge clk)
     if (reset)
       begin
	  vram_cpu_data <= 0;
	  int_vram_cpu_ready <= 0;
	  int_vram_cpu_done <= 0;
       end
     else
       begin
	  if (state == S_VRAM_RD && ~int_vram_cpu_ready)
	    begin
	       vram_cpu_data <= { sram1_in, sram2_in };
	       int_vram_cpu_ready <= 1;
	    end
	  else
	    if (state == S_VRAM_WR2 && ~int_vram_cpu_done)
	      int_vram_cpu_done <= 1;

	  if (~vram_cpu_req)
	    int_vram_cpu_ready <= 0;

	  if (~vram_cpu_write)
	    int_vram_cpu_done <= 0;
       end

   assign vram_cpu_data_out = vram_cpu_data;

   // vram_cpu - register addr & data
   always @(posedge clk)
     if (reset)
       begin
	  vram_cpu_addr_d <= 0;
	  vram_cpu_data_in_d <= 0;
       end
     else
       begin
	  if (next_state == S_VRAM_RD || next_state == S_VRAM_WR1)
	    vram_cpu_addr_d <= vram_cpu_addr;
	  if (next_state == S_VRAM_WR1)
	    vram_cpu_data_in_d <= vram_cpu_data_in;
       end

   // vram_cpu - cpu interface
   always @(posedge cpu_clk)
     if (reset)
       begin
//	  vram_cpu_ready <= 0;
	  vram_cpu_done <= 0;
       end
     else
       begin
//	  if (int_vram_cpu_ready)
//	    vram_cpu_ready <= 1;
//	  else
	    if (int_vram_cpu_done)
	      vram_cpu_done <= 1;
	  
//	  if (~vram_cpu_req)
//	    vram_cpu_ready <= 0;
	  if (~vram_cpu_write)
	    vram_cpu_done <= 0;
       end

   reg [10:0] vram_ack_delayed;

   always @(posedge cpu_clk)
     if (reset)
       vram_ack_delayed <= 0;
     else
       begin
          vram_ack_delayed[0] <= vram_cpu_req;
          vram_ack_delayed[1] <= vram_ack_delayed[0];
          vram_ack_delayed[2] <= vram_ack_delayed[1];
//          vram_ack_delayed[3] <= vram_ack_delayed[2];
//          vram_ack_delayed[4] <= vram_ack_delayed[3];
//          vram_ack_delayed[5] <= vram_ack_delayed[4];
//	  vram_ack_delayed[6] <= vram_ack_delayed[5];
       end

//   assign vram_cpu_ready = vram_ack_delayed[6];
   assign vram_cpu_ready = vram_ack_delayed[2];
   
`ifdef debug
   always @(posedge cpu_clk)
     if (int_vram_cpu_done && vram_cpu_write)
       $display("vram: W addr %o <- %o; %t",
		vram_cpu_addr_d, vram_cpu_data_in_d, $time);

   always @(posedge cpu_clk)
     if (vram_cpu_write)
       $display("vram: W addr %o <- %o; state %d %t",
		vram_cpu_addr_d, vram_cpu_data_in_d, state, $time);
`endif
`endif //  `ifdef original_vga
   
`define original_dram
`ifdef original_dram
   reg [31:0] sdram_out; // synthesis attribute keep sdram_out true;

   // sdram - internal
   always @(posedge clk)
     if (reset)
       begin
	  int_sdram_rdy <= 0;
	  int_sdram_done <= 0;
       end
     else
       begin
	  if (state == S_SDRAM_RD && ~int_sdram_rdy)
	    begin
//	       sdram_out <= { sram1_in, sram2_in };
	       sdram_out <= sdram_addr[21:17] == 0 ?
			    {sram1_in, sram2_in} : 32'hffffffff;
	       int_sdram_rdy <= 1;
	    end
	  else
	    if (state == S_SDRAM_WR2 && ~int_sdram_done)
	      int_sdram_done <= 1;

	  if (~sdram_req)
	    int_sdram_rdy <= 0;
	  if (~sdram_write)
	    int_sdram_done <= 0;
	  
       end
   
   // sdram - cpu interface
   always @(posedge cpu_clk)
     if (reset)
       begin
	  sdram_rdy <= 0;
	  sdram_done <= 0;
       end
     else
       begin
	  if (int_sdram_rdy)
	    begin
 `ifdef debug
	       if (~sdram_rdy)
		 $display("rc: sdram_req %o -> %o", sdram_addr, sdram_out);
`endif
	       sdram_rdy <= 1;
	    end
	  else
	    if (int_sdram_done)
	      begin
		 sdram_done <= 1;
	      end

`ifdef debug
	  if (sdram_done)
	    $display("rc: sdram_write %o <- %o", sdram_addr, sdram_data_in);
`endif
	  
	  if (~sdram_req)
	    sdram_rdy <= 0;
	  if (~sdram_write || ~sdram_ready)
	    begin
`ifdef debug_xxx
	       if (sdram_done)
		 $display("rc: clear sdram_write");
`endif
	       sdram_done <= 0;
	    end
       end

   assign sdram_data_out = sdram_out;
   
   // sdram ack delay
   reg [6:0] sdram_rdy_delay;

   assign    sdram_ready = sdram_rdy_delay[1];
//   assign    sdram_ready = sdram_rdy_delay[2];
//   assign    sdram_ready = sdram_rdy_delay[3];
//   assign    sdram_ready = sdram_rdy_delay[4];
//   assign    sdram_ready = sdram_rdy_delay[5];
//   assign     sdram_ready = sdram_rdy_delay[6];
   
   always @(posedge cpu_clk)
     if (reset)
       sdram_rdy_delay <= 0;
     else
       begin
	  /* ready is at fixed time from req - assumes we keep up */
	  sdram_rdy_delay[0] <= (sdram_req || sdram_write) & ~|sdram_rdy_delay;
	  sdram_rdy_delay[1] <= sdram_rdy_delay[0];
//	  sdram_rdy_delay[2] <= sdram_rdy_delay[1];
//	  sdram_rdy_delay[3] <= sdram_rdy_delay[2];
//	  sdram_rdy_delay[4] <= sdram_rdy_delay[3];
//	  sdram_rdy_delay[5] <= sdram_rdy_delay[4];
//	  sdram_rdy_delay[6] <= sdram_rdy_delay[5];
       end
`endif

//---------------------------------

//`define hack_dram
`ifdef hack_dram
   parameter 	 DRAM_SIZE = 131072;
   parameter 	 DRAM_BITS = 17;

   reg [31:0] 	 dram[DRAM_SIZE-1:0];
   wire [DRAM_BITS-1:0] sdram_addr20;
   reg [10:0] 	 ack_delayed;
   reg 		 sdram_was_write;
   reg 		 sdram_was_read;

   wire 	 sdram_start;
   wire 	 sdram_start_write;
   wire 	 sdram_start_read;

   integer 	 i;
   
   initial
     for (i = 0; i < DRAM_SIZE; i = i + 1)
       dram[i] = 0;

   assign sdram_addr20 = sdram_addr[DRAM_BITS-1:0];

   assign sdram_data_out = sdram_addr < DRAM_SIZE ?
			   dram[sdram_addr20] : 32'hffffffff;

   assign sdram_start = ack_delayed == 0;
   assign sdram_start_write = sdram_start && sdram_write;
   assign sdram_start_read = sdram_start && sdram_req;

//   assign sdram_done = ack_delayed[2] && sdram_was_write;
//   assign sdram_ready = ack_delayed[2] && sdram_was_read;
//assign sdram_done = ack_delayed[4] && sdram_was_write;
//assign sdram_ready = ack_delayed[4] && sdram_was_read;
assign sdram_done = ack_delayed[6] && sdram_was_write;
assign sdram_ready = ack_delayed[6] && sdram_was_read;
   
   always @(posedge cpu_clk)
     if (reset)
       ack_delayed <= 0;
     else
       begin
          ack_delayed[0] <= sdram_start_read || sdram_start_write;
          ack_delayed[1] <= ack_delayed[0];
          ack_delayed[2] <= ack_delayed[1];
          ack_delayed[3] <= ack_delayed[2];
          ack_delayed[4] <= ack_delayed[3];
          ack_delayed[5] <= ack_delayed[4];
          ack_delayed[6] <= ack_delayed[5];
       end

   always @(posedge cpu_clk)
     begin
	if (sdram_start_write)
	  begin
	     if (sdram_addr < DRAM_SIZE)
	       dram[sdram_addr20] = sdram_data_in;
 	     sdram_was_write = 1;
 	     sdram_was_read = 0;
	  end

	if (sdram_start_read)
	  begin
 	     sdram_was_write = 0;
 	     sdram_was_read = 1;
	  end
     end
`endif
   
//`define hack_mcr
`ifdef hack_mcr
//----------------------------

   parameter MCR_RAM_SIZE = 16384;

   reg [48:0] 	 mcr_ram [0:MCR_RAM_SIZE-1];
   reg [48:0] 	 mcr_out;
 	 
   integer 	 debug;
   integer 	 ii;

   initial
     begin
	debug = 0;
	for (ii = 0; ii < MCR_RAM_SIZE; ii=ii+1)
          mcr_ram[ii] = 49'b0;
     end

   always @(posedge clk)
     if (reset)
       int_mcr_done <= 0;
     else
       begin
	  if (state == S_MCR_WR4 && ~int_mcr_done)
	    begin
	       int_mcr_done <= 1;

               // patch out disk-copy (which takes 12 hours to sim)
//               if (mcr_addr == 14'o24045)
//		 mcr_ram[ mcr_addr ] = 49'h000000001000;
//               else
		 mcr_ram[ mcr_addr ] = mcr_data_in;
	    end

	  if (~mcr_write)
	    int_mcr_done <= 0;
       end

   always @(posedge cpu_clk)
     if (reset)
	  mcr_done <= 0;
     else
       begin
	  if (int_mcr_done)
	    mcr_done <= 1;

	  if (~mcr_write)
	    mcr_done <= 0;
       end

    always @(posedge clk)
     if (reset)
       begin
	  mcr_out <= 0;
	  int_mcr_ready <= 0;
       end
     else
       begin
	  if (state == S_MCR_RD2 && ~int_mcr_ready)
	    begin
	       mcr_out <= mcr_ram[ mcr_addr ];
	       int_mcr_ready <= 1;
	    end

	  if (~mcr_req)
	    int_mcr_ready <= 0;
       end

   always @(posedge cpu_clk)
     if (reset)
       mcr_ready <= 0;
     else
       begin
	  if (int_mcr_ready)
	    mcr_ready <= 1;

	  if (~mcr_req)
	    mcr_ready <= 0;
       end

   assign mcr_data_out = mcr_out;
   
   assign mcr_req = prefetch;

// ---------------------------
`endif //  `ifdef hack_mcr

//`define hack_vga
`ifdef hack_vga
   reg [31:0] 	 vram[0:21503];

   reg [14:0] 	 pending_vram_addr;
   reg [31:0] 	 pending_vram_data;
   reg 		 pending_vram_write;
   reg 		 pending_vram_read;

   integer iii;
   
   initial
     for (iii = 0; iii < 21504; iii = iii + 1)
       vram[iii] = 0;

   assign vram_cpu_data_out = vram[vram_cpu_addr];
   assign vram_vga_data_out = vram[vram_vga_addr];
   assign vram_vga_ready = 1;
   
   always @(posedge cpu_clk)
     if (reset)
       begin
	  pending_vram_addr <= 0;
	  pending_vram_data <= 0;
	  
	  pending_vram_write <= 0;
	  pending_vram_read <= 0;
       end
     else
       begin
	  if (vram_cpu_write)
	    begin
	       pending_vram_addr <= vram_cpu_addr;
	       pending_vram_data <= vram_cpu_data_in;
	       pending_vram_write <= 1;
	    end
	  else
	    if (vram_cpu_done)
	       pending_vram_write <= 0;
	  
	  if (vram_cpu_req)
	    begin
	       $display("vram: R addr %o -> %o; %t",
			vram_cpu_addr, vram[vram_cpu_addr], $time);
	       pending_vram_addr <= vram_cpu_addr;
	       pending_vram_read <= 1;
	    end
	  else
	    pending_vram_read <= 0;
       end

   reg [6:0] 	 vram_ack_delayed;

   always @(posedge cpu_clk)
     if (reset)
       vram_ack_delayed <= 0;
     else
       begin
          vram_ack_delayed[0] <= vram_cpu_req;
//          vram_ack_delayed[1] <= vram_ack_delayed[0];
//          vram_ack_delayed[2] <= vram_ack_delayed[1];
//          vram_ack_delayed[3] <= vram_ack_delayed[2];
//          vram_ack_delayed[4] <= vram_ack_delayed[3];
//          vram_ack_delayed[5] <= vram_ack_delayed[4];
//          vram_ack_delayed[6] <= vram_ack_delayed[5];
       end

//   assign vram_cpu_ready = pending_vram_read;
//   assign vram_cpu_ready = vram_ack_delayed[6];
   assign vram_cpu_ready = vram_ack_delayed[0];

   always @(posedge cpu_clk)
     begin
	vram_cpu_done = 0;
	if (~fetch)
	  begin
	     if (pending_vram_write)
	       begin
		  vram[pending_vram_addr] = pending_vram_data;
		  vram_cpu_done = 1;
		  
		  $display("vram: W addr %o <- %o; %t",
			   pending_vram_addr, pending_vram_data, $time);
	       end
	  end
     end
`endif   

endmodule
  
