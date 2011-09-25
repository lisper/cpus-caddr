// pipe_ram_controller.v

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
 * 		assert address & data, we, wr mcr hi
 * S_MCR_WR2
 * 		assert address & data, we, wr mcr lo
 * S_VGA_RD
 * 		vram-rd; latch vram-vga data
 * S_MCR_RD1 -> S_MCR_RD2
 * 		latch mcr data hi
 * S_MCR_RD2
 * 		latch mcr data lo
 * S_VRAM_WR
 * 		assert address & data, we, vram-wr
 * S_VRAM_RD
 * 		vram-rd; latch vram-cpu data
 * S_SDRAM_RD
 * 		sdram-rd; latch sdram data
 * S_SDRAM_WR
 * 		assert address & data, we, sdram-wr
*/

module pipe_ram_controller(
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
   reg [17:0] 	 sram_a;
   
   output 	 sram_oe_n;
   reg 		 sram_oe_n;
   
   output 	 sram_we_n;
   reg 		 sram_we_n;
   
   input [15:0]  sram1_in;
   input [15:0]  sram2_in;

   output [15:0]  sram1_out;
   reg [15:0] 	  sram1_out;

   output [15:0]  sram2_out;
   reg [15:0] 	  sram2_out;

   output 	 sram1_ce_n, sram1_ub_n, sram1_lb_n;
   reg 		 sram1_ce_n, sram1_ub_n, sram1_lb_n;
   output 	 sram2_ce_n, sram2_ub_n, sram2_lb_n;
   reg 		 sram2_ce_n, sram2_ub_n, sram2_lb_n;

   //
   wire [17:0] 	 sram_req_a;
   wire 	 sram_req_oe_n;
   wire 	 sram_req_we_n;
   
   reg [15:0] 	 sram1_resp_in;
   reg [15:0] 	 sram2_resp_in;
   
   wire [15:0] 	  sram1_req_out;
   wire [15:0] 	  sram2_req_out;

   wire 	  sram1_req_ce_n, sram1_req_ub_n, sram1_req_lb_n;
   wire 	  sram2_req_ce_n, sram2_req_ub_n, sram2_req_lb_n;

   reg [7:0]	  sram_busy;
   reg [7:0]	  sram_done;
 		  
   //

   reg 		 vram_vga_ready;
   reg 		 vram_cpu_ready;
   reg 		 vram_cpu_done;

   reg 		 sdram_done;
   reg 		 sdram_ready;

   reg 		 mcr_ready;
   reg 		 mcr_done;
   
   wire 	 mcr_req;

   reg [13:0] 	 int_mcr_addr;
   reg [48:0] 	 int_mcr_data_in;

   reg 		 int_mcr_ready;
   reg 		 int_mcr_done;
   reg 		 int_vram_cpu_ready;
   reg 		 int_vram_cpu_done;

   reg 		 int_sdram_done;
   reg 		 int_sdram_ready;
 		 
   wire		 int_sdram_done_e;
   wire		 int_sdram_ready_e;
   
   reg [14:0] 	 int_vram_cpu_addr;
   reg [31:0] 	 int_vram_cpu_data_in;

`ifdef debug
   reg 		 debug;
`endif
 		 
   // ---------------------------

   parameter S_IDLE = 0,
	       S_VGA_RD = 1,
	       S_MCR_RD1 = 2,
	       S_MCR_RD2 = 3,
	       S_MCR_WR1 = 4,
	       S_MCR_WR2 = 5,
	       S_SDRAM_RD = 6,
	       S_SDRAM_WR = 7,
	       S_VRAM_RD = 8,
	       S_VRAM_WR = 9;
   
   reg [3:0] 	 state;
   wire [3:0] 	 next_state;

   wire sram_idle;
   wire sram_start, sram_end;

   always @(posedge clk)
     if (reset)
       state <= S_IDLE;
     else
       if ((state == S_IDLE && sram_idle) || sram_end)
	 state <= next_state;

   wire vram_vga_req_sync;

   assign sram_idle = ~|sram_busy && ~|sram_done;
   
   assign next_state =
      (state == S_IDLE && mcr_req && ~mcr_write && ~int_mcr_ready) ? S_MCR_RD1 :
      (state == S_MCR_RD1) ? S_MCR_RD2 :
      (state == S_MCR_RD2) ? S_IDLE :
      (state == S_IDLE && mcr_write && ~int_mcr_done) ? S_MCR_WR1 :
      (state == S_MCR_WR1) ? S_MCR_WR2 :
      (state == S_MCR_WR2) ? S_IDLE :
      (state == S_IDLE && vram_vga_req_sync && ~vram_vga_ready) ? S_VGA_RD :
      (state == S_VGA_RD) ? S_IDLE :
      (state == S_IDLE && sdram_req && ~int_sdram_ready) ? S_SDRAM_RD :
      (state == S_SDRAM_RD) ? S_IDLE :
      (state == S_IDLE && sdram_write && ~int_sdram_done) ? S_SDRAM_WR :
      (state == S_SDRAM_WR) ? S_IDLE :
      (state == S_IDLE && vram_cpu_req && ~int_vram_cpu_ready) ? S_VRAM_RD :
      (state == S_VRAM_RD) ? S_IDLE :
      (state == S_IDLE && vram_cpu_write && ~int_vram_cpu_done) ? S_VRAM_WR :
      (state == S_VRAM_WR) ? S_IDLE :
      S_IDLE;
   
   assign state_out = state;
   
   // ---------------------------

`ifdef debug
   always @(posedge clk)
     begin
	if (^mcr_addr === 1'bx) $display("assert: mcr_addr undefined' %t", $time);
	if (^mcr_data_in === 1'bx) $display("assert: mcr_data_in undefined; %t", $time);

	if (^sdram_addr === 1'bx) $display("assert: sdram_addr undefined; %t", $time);
	if (^sdram_data_in === 1'bx) $display("assert: sdram_data_in undefined; %t", $time);

	if (^vram_cpu_addr === 1'bx)
	  $display("assert: vram_cpu_addr undefined; %t", $time);
	if (^vram_cpu_data_in === 1'bx)
	  $display("assert: vram_cpu_data_in undefined; %t", $time);
	if (^{vram_vga_addr} === 1'bx)
	  $display("assert: vram_vga_addr undefined; %t", $time);
     end
`endif
   
   // ---------------------------

   wire vram_access; wire sdram_access;
   
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
	state == S_SDRAM_RD || state == S_SDRAM_WR;

   assign sram_a_mcr_h =
	state == S_MCR_RD1 || state == S_MCR_WR1;

   assign sram_a_mcr_l =
	state == S_MCR_RD2 || state == S_MCR_WR2;

   assign sram_a_vga =
	state == S_VGA_RD;

   assign sram_a_vram = 
	state == S_VRAM_RD || state == S_VRAM_WR;
   
   assign sram_req_a =
		  sram_a_sdram ? { 1'b0, sdram_addr[16:0] } :
		  sram_a_mcr_h ? { 3'b100, int_mcr_addr, 1'b0 } :
		  sram_a_mcr_l ? { 3'b100, int_mcr_addr, 1'b1 } :
		  sram_a_vga   ? { 3'b110, vram_vga_addr } :
		  sram_a_vram  ? { 3'b110, int_vram_cpu_addr } :
		  0;

   assign sram_req_oe_n =
		     ((state == S_VGA_RD) ||
		      (state == S_MCR_RD1 || state == S_MCR_RD2) ||
		      (state == S_VRAM_RD) ||
		      (state == S_SDRAM_RD)) ? 1'b0 :
		     1'b1;

   assign sram_req_we_n =
		     ((state == S_MCR_WR1 || state == S_MCR_WR2) ||
		      (state == S_SDRAM_WR) ||
		      (state == S_VRAM_WR)) ? 1'b0 :
		     1'b1;

   assign sram1_req_ce_n = state != S_IDLE ? 1'b0 : 1'b1;
   assign sram2_req_ce_n = state != S_IDLE ? 1'b0 : 1'b1;
   
   assign sram1_req_ub_n = state != S_IDLE ? 1'b0 : 1'b1;
   assign sram1_req_lb_n = state != S_IDLE ? 1'b0 : 1'b1;

   assign sram2_req_ub_n = state != S_IDLE ? 1'b0 : 1'b1;
   assign sram2_req_lb_n = state != S_IDLE ? 1'b0 : 1'b1;

   //
   // [48:0]
   //	{15'b0, [48:32]} [31:0]
   //	{15'b0[48]}, [47:32] [31:16] [15:0]
   //

   always @(posedge clk)
     if (reset)
       int_mcr_data_in <= 0;
     else
       if (mcr_write)
	 int_mcr_data_in <=
`ifdef debug_patch_disk_copy
	   // patch out disk-copy (which takes hours to sim)
	   mcr_addr == 14'o24045 ? 49'h000000001000 : mcr_data_in;
`else
           mcr_data_in;
`endif

`ifdef debug
   always @(posedge clk)
     if (mcr_write && state == S_MCR_WR1 && debug)
       $display("mcr: write @%o <- %o",
		mcr_addr, mcr_addr == 14'o24045 ? 49'h000000001000 : mcr_data_in);
`endif
   
   always @(posedge clk)
     if (reset)
       int_mcr_addr <= 0;
     else
       if (mcr_req || mcr_write)
	 int_mcr_addr <= mcr_addr;
   
   assign sram1_req_out =
    (state == S_MCR_WR1) ? {15'b0, int_mcr_data_in[48]} :
    (state == S_MCR_WR2) ? int_mcr_data_in[31:16] :
    (state == S_VRAM_WR)   ? int_vram_cpu_data_in[31:16] :
    (state == S_SDRAM_WR) ? sdram_data_in[31:16] :
    16'b0;
		    
   assign sram2_req_out =
    (state == S_MCR_WR1) ? int_mcr_data_in[47:32] :
    (state == S_MCR_WR2) ? int_mcr_data_in[15:0] :
    (state == S_VRAM_WR) ? int_vram_cpu_data_in[15:0] :
    (state == S_SDRAM_WR) ? sdram_data_in[15:0] :
    16'b0;

   // ---------------------------

   reg [48:0] 	 mcr_out;

   //
   // mcr read - internal
   //
   always @(posedge clk)
     if (reset)
       mcr_out <= 0;
     else
       if (sram_done[0])
	 mcr_out[48:32] <= { sram1_resp_in[0], sram2_resp_in };
       else
	 if (sram_done[1])
	   mcr_out[31:0] <= { sram1_resp_in, sram2_resp_in };

   always @(posedge clk)
     if (reset)
       int_mcr_ready <= 0;
     else
       begin
	  if (state == S_MCR_RD2 && ~int_mcr_ready)
	    int_mcr_ready <= 1;
	  else
	    if (~mcr_req)
	      int_mcr_ready <= 0;
       end

   always @(posedge clk)
     if (reset)
       int_mcr_done <= 0;
     else
       begin
	  if (state == S_MCR_WR2 && ~int_mcr_done)
	    int_mcr_done <= 1;
	  else
	    if (~mcr_write)
	      int_mcr_done <= 0;
       end

   //
   // mcr read - cpu interface
   //
   assign mcr_req = prefetch;

   assign mcr_data_out = mcr_out;

   always @(posedge cpu_clk)
     if (reset)
       mcr_ready <= 0;
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
	    if (~mcr_req)
	      mcr_ready <= 0;
       end

   always @(posedge cpu_clk)
     if (reset)
       mcr_done <= 0;
     else
       begin
	  if (int_mcr_done)
	    mcr_done <= 1;
	  else
	    if (~mcr_write)
	      mcr_done <= 0;
       end

`ifdef debug_mcr
   always @(posedge clk)
     begin
	if (mcr_write)
	  $display("rc: mcr_write state %d", state);
				
	if (state == S_MCR_WR1)
	  $display("rc: mcr_write1 %o -> %o", int_mcr_addr, mcr_data_in);
	if (state == S_MCR_WR2)
	  $display("rc: mcr_write2 %o -> %o", int_mcr_addr, mcr_data_in);

	if (state == S_MCR_RD1)
	  $display("rc: mcr_read1 %o -> %o", int_mcr_addr, { sram1_resp_in, sram2_resp_in });
	if (state == S_MCR_RD2)
	  $display("rc: mcr_read2 %o -> %o; %t",
		   int_mcr_addr, { mcr_data_out[48:32], { sram1_resp_in, sram2_resp_in } },
		   $time);
     end
`endif
   
   //
   // vram_vga read - vga controller only
   //
   reg vga_req;
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
	  if (sram_done[2]/*state == S_VGA_RD*/)
	    begin
	       vram_vga_data <= { sram1_resp_in, sram2_resp_in };
	       vram_vga_ready <= 1;
`ifdef debug
	       $display("rc: vram vga read %o -> %o",
			vram_vga_addr, { sram1_resp_in, sram2_resp_in });
`endif
	    end

	  if (~vram_vga_req_sync)
	    vram_vga_ready <= 0;
       end

   assign vram_vga_data_out = vram_vga_data;
   
   // vram_cpu read/write

   //
   // vram_cpu - internal
   //
   always @(posedge clk)
     if (reset)
	  vram_cpu_data <= 0;
     else
       if (sram_done[4])
	 begin
	    vram_cpu_data <= { sram1_resp_in, sram2_resp_in };
	    $display("vram_cpu_data %o", { sram1_resp_in, sram2_resp_in });
	 end

   always @(posedge clk)
     if (reset)
       int_vram_cpu_ready <= 0;
     else
       begin
	  if (state == S_VRAM_RD && ~int_vram_cpu_ready)
	    int_vram_cpu_ready <= 1;
	  else
	    if (~vram_cpu_req)
	      int_vram_cpu_ready <= 0;
       end

   always @(posedge clk)
     if (reset)
       int_vram_cpu_done <= 0;
     else
       begin
	  if (state == S_VRAM_WR && ~int_vram_cpu_done)
	    int_vram_cpu_done <= 1;
	  else
	    if (~vram_cpu_write)
	      int_vram_cpu_done <= 0;
       end

   assign vram_cpu_data_out = vram_cpu_data;

   //
   // vram_cpu - register addr & data
   //

   wire   latch_vram_addr;
   wire   latch_vram_data;
   
   assign latch_vram_addr = state == S_IDLE && vram_cpu_req && ~int_vram_cpu_ready;
   assign latch_vram_data = state == S_IDLE && vram_cpu_write && ~int_vram_cpu_done;

   always @(posedge clk)
     if (reset)
       begin
	  int_vram_cpu_addr <= 0;
	  int_vram_cpu_data_in <= 0;
       end
     else
       begin
	  if (latch_vram_addr || latch_vram_data)
	    int_vram_cpu_addr <= vram_cpu_addr;
	  if (latch_vram_data)
	    int_vram_cpu_data_in <= vram_cpu_data_in;
       end

   // vram_cpu - cpu interface
   always @(posedge cpu_clk)
     if (reset)
       vram_cpu_ready <= 0;
     else
       begin
	  if (int_vram_cpu_ready)
	    vram_cpu_ready <= 1;
	  else
	    if (~vram_cpu_req)
	      vram_cpu_ready <= 0;
       end

   always @(posedge cpu_clk)
     if (reset)
       vram_cpu_done <= 0;
     else
       begin
	  if (int_vram_cpu_done)
	    vram_cpu_done <= 1;
	  else
	    if (~vram_cpu_write)
	      vram_cpu_done <= 0;
       end

`ifdef debug
   always @(posedge cpu_clk)
     if (int_vram_cpu_done && vram_cpu_write)
       $display("vram: W addr %o <- %o; %t",
		int_vram_cpu_addr, int_vram_cpu_data_in, $time);

   always @(posedge cpu_clk)
     if (vram_cpu_write)
       $display("vram: W addr %o <- %o; state %d %t",
		int_vram_cpu_addr, int_vram_cpu_data_in, state, $time);
`endif
   
   //
   // sdram - internal
   //
   reg [31:0] sdram_out; // synthesis attribute keep sdram_out true;

   assign int_sdram_done_e = state == S_SDRAM_WR;
   assign int_sdram_ready_e = sram_done[3]/*state == S_SDRAM_RD*/;

   always @(posedge clk)
     if (reset)
       sdram_out <= 0;
     else
       begin
	  if (sram_done[3]/*state == S_SDRAM_RD*/)
	    begin
	       sdram_out <= sdram_addr[21:17] == 0 ?
			    {sram1_resp_in, sram2_resp_in} : 32'hffffffff;
	    end

`ifdef debug
	  if (~sdram_ready && int_sdram_ready_e && debug)
	    $display("rc: sdram read %o -> %o; %t", sdram_addr, sdram_out, $time);
	  if (sdram_write && int_sdram_done_e && debug)
	    $display("rc: sdram write %o <- %o; %t", sdram_addr, sdram_data_in, $time);
`endif
       end

   always @(posedge clk)
     if (reset)
       int_sdram_done <= 0;
     else
       if (int_sdram_done_e)
	 int_sdram_done <= 1;
       else
	 if (~sdram_write)
	   int_sdram_done <= 0;

   always @(posedge clk)
     if (reset)
       int_sdram_ready <= 0;
     else
       if (int_sdram_ready_e)
	 int_sdram_ready <= 1;
       else
	 if (~sdram_req)
	   int_sdram_ready <= 0;

   
   //
   // sdram - cpu interface
   //
   assign sdram_data_out = sdram_out;
   
   always @(posedge cpu_clk)
     if (reset)
       sdram_ready <= 0;
     else
       begin
	  if (int_sdram_ready)
	    begin
	       sdram_ready <= 1;
	    end
	  else
	    if (~sdram_req)
	      sdram_ready <= 0;
       end

`define normal
`ifdef normal
   always @(posedge cpu_clk)
     if (reset)
       sdram_done <= 0;
     else
       begin
	  if (int_sdram_done)
	    sdram_done <= 1;
	  else
	    if (~sdram_write/* || ~sdram_ready*/)
	      sdram_done <= 0;
       end
`else
   reg [7:0] sdram_done_delay;
   
   always @(posedge cpu_clk)
     if (reset)
       sdram_done_delay <= 0;
     else
       begin
	  if (int_sdram_done)
	    sdram_done_delay[0] <= 1;
	  else
	    if (~sdram_write/* || ~sdram_ready*/)
	      sdram_done_delay[0] <= 0;

	  sdram_done_delay[7:1] <= sdram_done_delay[6:0];
       end

   always @(posedge cpu_clk)
     if (reset)
       sdram_done <= 0;
     else
       sdram_done <= sdram_done_delay[7];
`endif

   //----

   reg [1:0] sram_state;
   wire [1:0] sram_state_next;
   wire [7:0] sram_req;
   
   always @(posedge clk)
     if (reset)
       sram_state <= 0;
     else
       sram_state <= sram_state_next;

   assign sram_start = (sram_state == 0) && |sram_req;
   assign sram_end = sram_state == 2;
   
   assign sram_state_next =
			   (sram_state == 0) && |sram_req ? 1 :
			   (sram_state == 1) ? 2 :
			   (sram_state == 2) ? 0 :
			   sram_state;

   assign sram_req = {
		      state == S_MCR_WR1 | state == S_MCR_WR2, // [7]
		      state == S_VRAM_WR, // [6]
		      state == S_SDRAM_WR,// [5]
		      state == S_VRAM_RD, // [4]
		      state == S_SDRAM_RD,// [3]
		      state == S_VGA_RD,	// [2]
		      state == S_MCR_RD2,	// [1]
		      state == S_MCR_RD1	// [0]
		      };
			   
   always @(posedge clk)
     if (reset)
       begin
	  sram_busy <= 0;

	  sram_a <= 0;
	  sram1_out <= 0;
	  sram2_out <= 0;

	  sram1_resp_in <= 0;
	  sram2_resp_in <= 0;
	  
	  sram_oe_n <= 1;
	  sram_we_n <= 1;

	  sram1_ce_n <= 1;
	  sram1_ub_n <= 1;
	  sram1_lb_n <= 1;

	  sram2_ce_n <= 1;
	  sram2_ub_n <= 1;
	  sram2_lb_n <= 1;
       end
     else
       begin
	  if (sram_start)
	    begin
	       sram_busy <= sram_req;

	       sram_a <= sram_req_a;

	       sram1_out <= sram1_req_out;
	       sram2_out <= sram2_req_out;

	       sram_oe_n <= sram_req_oe_n;
	       sram_we_n <= sram_req_we_n;
	       
	       sram1_ce_n <= sram1_req_ce_n;
	       sram1_ub_n <= sram1_req_ub_n;
	       sram1_lb_n <= sram1_req_lb_n;

	       sram2_ce_n <= sram2_req_ce_n;
	       sram2_ub_n <= sram2_req_ub_n;
	       sram2_lb_n <= sram2_req_lb_n;
	    end
	  else
	    if (sram_end)
	      begin
		 sram1_resp_in <= sram1_in;
		 sram2_resp_in <= sram2_in;

		 sram_done <= sram_busy;
		 sram_busy <= 0;

		 sram_oe_n <= 1;
		 sram_we_n <= 1;

		 sram1_ce_n <= 1;
		 sram1_ub_n <= 1;
		 sram1_lb_n <= 1;

		 sram2_ce_n <= 1;
		 sram2_ub_n <= 1;
		 sram2_lb_n <= 1;
	      end
	    else
	      sram_done <= 0;
       end
   

endmodule
  
