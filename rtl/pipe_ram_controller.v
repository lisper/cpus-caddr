// pipe2_ram_controller.v

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
 		 
   reg [14:0] 	 int_vram_cpu_addr;
   reg [31:0] 	 int_vram_cpu_data_in;

`ifdef debug
   reg 		 debug;
   reg 		 debug_mcr;
`endif
 		 
   // ---------------------------

   parameter [10:0]
		S_INIT     = 11'b0_00000_00000,
		S_IDLE     = 11'b0_00000_00001,
		S_VGA_RD   = 11'b0_00000_00010,
		S_MCR_RD1  = 11'b0_00000_00100,
		S_MCR_RD2  = 11'b0_00000_01000,
		S_MCR_WR1  = 11'b0_00000_10000,
		S_MCR_WR2  = 11'b0_00001_00000,
		S_SDRAM_RD = 11'b0_00010_00000,
		S_SDRAM_WR = 11'b0_00100_00000,
		S_VRAM_RD  = 11'b0_01000_00000,
		S_VRAM_WR  = 11'b0_10000_00000,
		S_WAIT     = 11'b1_00000_00000;
   
   parameter [3:0]
		NS_IDLE     = 0,
		NS_VGA_RD   = 1,
		NS_MCR_RD1  = 2,
		NS_MCR_RD2  = 3,
		NS_MCR_WR1  = 4,
		NS_MCR_WR2  = 5,
		NS_SDRAM_RD = 6,
		NS_SDRAM_WR = 7,
		NS_VRAM_RD  = 8,
		NS_VRAM_WR  = 9,
		NS_WAIT     = 10;
   
   reg [10:0] 	 state;
   wire [10:0] 	 next_state;

   wire sram_start, sram_begin, sram_mid0, sram_mid1, sram_mid2, sram_end;

   always @(posedge clk)
     if (reset)
       state <= S_IDLE;
     else
       state <= next_state;

   wire i_mcr_req, i_mcr_write;
   wire i_sdram_req, i_sdram_write;
   wire i_vram_cpu_req, i_vram_cpu_write;
   wire vram_vga_req_sync;
   
   assign next_state =
      (state[NS_IDLE] && i_mcr_req) ? S_MCR_RD1 :
      (state[NS_MCR_RD1] && sram_end) ? S_MCR_RD2 :
      (state[NS_MCR_RD2]) ? S_WAIT :
      (state[NS_IDLE] && i_mcr_write) ? S_MCR_WR1 :
      (state[NS_MCR_WR1] && sram_end) ? S_MCR_WR2 :
      (state[NS_MCR_WR2]) ? S_WAIT :
      (state[NS_IDLE] && vram_vga_req_sync && ~vram_vga_ready) ? S_VGA_RD :
      (state[NS_VGA_RD]) ? S_WAIT :
      (state[NS_IDLE] && i_sdram_req) ? S_SDRAM_RD :
      (state[NS_SDRAM_RD]) ? S_WAIT :
      (state[NS_IDLE] && i_sdram_write) ? S_SDRAM_WR :
      (state[NS_SDRAM_WR]) ? S_WAIT :
      (state[NS_IDLE] && i_vram_cpu_req) ? S_VRAM_RD :
      (state[NS_VRAM_RD]) ? S_WAIT :
      (state[NS_IDLE] && i_vram_cpu_write) ? S_VRAM_WR :
      (state[NS_VRAM_WR]) ? S_WAIT :
      (state[NS_WAIT] && sram_end) ? S_IDLE :
      state;
   
   assign state_out = state[3:0];
   
   // ---------------------------

`ifdef debug
   always @(posedge clk)
     begin
	if (^mcr_addr === 1'bx && ~reset) $display("assert: mcr_addr undefined' %t", $time);
	if (^mcr_data_in === 1'bx && ~reset) $display("assert: mcr_data_in undefined; %t", $time);

	if (^sdram_addr === 1'bx && ~reset) $display("assert: sdram_addr undefined; %t", $time);
	if (^sdram_data_in === 1'bx && ~reset) $display("assert: sdram_data_in undefined; %t", $time);

	if (^vram_cpu_addr === 1'bx && ~reset)
	  $display("assert: vram_cpu_addr undefined; %t", $time);
	if (^vram_cpu_data_in === 1'bx && ~reset)
	  $display("assert: vram_cpu_data_in undefined; %t", $time);
	if (^{vram_vga_addr} === 1'bx && ~reset)
	  $display("assert: vram_vga_addr undefined; %t", $time);
     end
`endif
   
   // ---------------------------

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

   assign sram_a_sdram = state[NS_SDRAM_RD] || state[NS_SDRAM_WR];
   assign sram_a_mcr_h = state[NS_MCR_RD1] || state[NS_MCR_WR1];
   assign sram_a_mcr_l = state[NS_MCR_RD2] || state[NS_MCR_WR2];
   assign sram_a_vga   = state[NS_VGA_RD];
   assign sram_a_vram  = state[NS_VRAM_RD] || state[NS_VRAM_WR];
   
   assign sram_req_a =
		  sram_a_sdram ? { 1'b0, sdram_addr[16:0] } :
		  sram_a_mcr_h ? { 3'b100, int_mcr_addr, 1'b0 } :
		  sram_a_mcr_l ? { 3'b100, int_mcr_addr, 1'b1 } :
		  sram_a_vga   ? { 3'b110, vram_vga_addr } :
		  sram_a_vram  ? { 3'b110, int_vram_cpu_addr } :
		  0;

   assign sram_req_oe_n =
		     ((state[NS_VGA_RD]) ||
		      (state[NS_MCR_RD1] || state[NS_MCR_RD2]) ||
		      (state[NS_VRAM_RD]) ||
		      (state[NS_SDRAM_RD])) ? 1'b0 :
		     1'b1;

   assign sram_req_we_n =
		     ((state[NS_MCR_WR1] || state[NS_MCR_WR2]) ||
		      (state[NS_SDRAM_WR]) ||
		      (state[NS_VRAM_WR])) ? 1'b0 :
		     1'b1;

   assign sram1_req_ce_n = ~state[NS_IDLE] ? 1'b0 : 1'b1;
   assign sram2_req_ce_n = ~state[NS_IDLE] ? 1'b0 : 1'b1;
   
   assign sram1_req_ub_n = ~state[NS_IDLE] ? 1'b0 : 1'b1;
   assign sram1_req_lb_n = ~state[NS_IDLE] ? 1'b0 : 1'b1;

   assign sram2_req_ub_n = ~state[NS_IDLE] ? 1'b0 : 1'b1;
   assign sram2_req_lb_n = ~state[NS_IDLE] ? 1'b0 : 1'b1;

   //
   // [48:0]
   //	{15'b0, [48:32]} [31:0]
   //	{15'b0[48]}, [47:32] [31:16] [15:0]
   //

   wire   latch_mcr_addr;
   wire   latch_mcr_data;

   always @(posedge clk)
     if (reset)
       int_mcr_data_in <= 0;
     else
       if (latch_mcr_data)
	 int_mcr_data_in <=
`ifdef debug_patch_disk_copy
	   // patch out disk-copy (which takes hours to sim)
	   mcr_addr == 14'o24045 ? 49'h000000001000 : mcr_data_in;
`else
           mcr_data_in;
`endif

   always @(posedge clk)
     if (reset)
       int_mcr_addr <= 0;
     else
       if (latch_mcr_addr)
	 int_mcr_addr <= mcr_addr;
   
`ifdef debug
   always @(posedge clk)
     if (mcr_write && mcr_state[NMC_IDLE] && debug_mcr)
       $display("mcr: write @%o <- %o",
		mcr_addr, mcr_addr == 14'o24045 ? 49'h000000001000 : mcr_data_in);

   always @(posedge clk)
     if (mcr_state[NMC_READW] && ~mcr_req && debug_mcr)
       $display("mcr: read @%o -> %o",
		int_mcr_addr, mcr_data_out);
`endif
   
   assign sram1_req_out =
			 (state[NS_MCR_WR1])  ? {15'b0, int_mcr_data_in[48]} :
			 (state[NS_MCR_WR2])  ? int_mcr_data_in[31:16] :
			 (state[NS_VRAM_WR])  ? int_vram_cpu_data_in[31:16] :
			 (state[NS_SDRAM_WR]) ? sdram_data_in[31:16] :
			 16'b0;
		    
   assign sram2_req_out =
			 (state[NS_MCR_WR1])  ? int_mcr_data_in[47:32] :
			 (state[NS_MCR_WR2])  ? int_mcr_data_in[15:0] :
			 (state[NS_VRAM_WR])  ? int_vram_cpu_data_in[15:0] :
			 (state[NS_SDRAM_WR]) ? sdram_data_in[15:0] :
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

   //
   // mcr read - cpu interface
   //
   reg [4:0] mcr_state;
   wire [4:0] mcr_state_next;
   parameter [4:0]
		MC_IDLE   = 5'b00001,
   		MC_READ   = 5'b00010,
   		MC_READW  = 5'b00100,
		MC_WRITE  = 5'b01000,
		MC_WRITEW = 5'b10000;
      
   parameter [2:0]
		NMC_IDLE   = 0,
   		NMC_READ   = 1,
		NMC_READW  = 2,
   		NMC_WRITE  = 3,
		NMC_WRITEW = 4;
   
   always @(posedge clk)
     if (reset)
       mcr_state <= MC_IDLE;
     else
       mcr_state <= mcr_state_next;

   assign mcr_state_next =
			    (mcr_state[NMC_IDLE] && mcr_write) ? MC_WRITE :
			    (mcr_state[NMC_IDLE] && mcr_req) ? MC_READ :

			    (mcr_state[NMC_READ] && state[NS_MCR_RD1]) ? MC_READW :
			    (mcr_state[NMC_READW] && ~mcr_req) ? MC_IDLE :
   
			    (mcr_state[NMC_WRITE] && state[NS_MCR_WR1]) ? MC_WRITEW :
			    (mcr_state[NMC_WRITEW] && ~mcr_write) ? MC_IDLE :

			    mcr_state;
   
   assign i_mcr_req = mcr_state[NMC_READ];
   assign i_mcr_write = mcr_state[NMC_WRITE];

   assign latch_mcr_addr = mcr_state[NMC_IDLE] && (mcr_req || mcr_write);
   assign latch_mcr_data = mcr_state[NMC_IDLE] && mcr_write;

   //
   //
   //
   assign mcr_req = prefetch;

   assign mcr_data_out = mcr_out;

   always @(posedge clk)
     if (reset)
       int_mcr_ready <= 0;
     else
       int_mcr_ready <= sram_done[1] ? 1'b1 : (int_mcr_ready && mcr_state[NMC_READW]);
   
   always @(posedge clk)
     if (reset)
       int_mcr_done <= 0;
     else
       int_mcr_done <= state[NS_MCR_WR2] ? 1'b1 : (int_mcr_done && mcr_state[NMC_WRITEW]);

   //
   // mcr - cpu interface
   //   
   always @(posedge cpu_clk)
     if (reset)
       mcr_ready <= 0;
     else
       mcr_ready <= int_mcr_ready;
   
   always @(posedge cpu_clk)
     if (reset)
       mcr_done <= 0;
     else
       mcr_done <= int_mcr_done;
   
`ifdef debug_mcr
   always @(posedge clk)
     begin
	if (mcr_write)
	  $display("rc: mcr_write state %d", state);
				
	if (state[NS_MCR_WR1])
	  $display("rc: mcr_write1 %o -> %o", int_mcr_addr, mcr_data_in);
	if (state[NS_MCR_WR2])
	  $display("rc: mcr_write2 %o -> %o", int_mcr_addr, mcr_data_in);

	if (state[NS_MCR_RD1])
	  $display("rc: mcr_read1 %o -> %o", int_mcr_addr, { sram1_resp_in, sram2_resp_in });
	if (state[NS_MCR_RD2])
	  $display("rc: mcr_read2 %o -> %o; %t",
		   int_mcr_addr, { mcr_data_out[48:32], { sram1_resp_in, sram2_resp_in } },
		   $time);
     end
`endif
   
   //
   // vram_vga read - vga controller only
   //
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
       vram_vga_data <= 0;
     else
       begin
	  if (sram_done[2]/*state == S_VGA_RD*/)
	    begin
	       vram_vga_data <= { sram1_resp_in, sram2_resp_in };
`ifdef debug_vga
	       $display("rc: vram vga read %o -> %o",
			vram_vga_addr, { sram1_resp_in, sram2_resp_in });
`endif
	    end
       end

   always @(posedge clk)
     if (reset)
       vram_vga_ready <= 0;
     else
       begin
	  if (sram_done[2]/*state == S_VGA_RD*/)
	    vram_vga_ready <= 1;
	  else
	    if (~vram_vga_req_sync && ~sram_busy[2])
	      vram_vga_ready <= 0;
       end

   assign vram_vga_data_out = vram_vga_data;
   
   // vram_cpu read/write

   //
   // vram_cpu - internal
   //
   reg [4:0] vram_state;
   wire [4:0] vram_state_next;
   parameter [4:0]
		V_IDLE   = 5'b00001,
   		V_READ   = 5'b00010,
   		V_READW  = 5'b00100,
		V_WRITE  = 5'b01000,
		V_WRITEW = 5'b10000;
      
   parameter [2:0]
		NV_IDLE   = 0,
   		NV_READ   = 1,
		NV_READW  = 2,
   		NV_WRITE  = 3,
		NV_WRITEW = 4;
   
   always @(posedge clk)
     if (reset)
       vram_state <= V_IDLE;
     else
       vram_state <= vram_state_next;

   assign vram_state_next =
			    (vram_state[NV_IDLE] && vram_cpu_req) ? V_READ :
			    (vram_state[NV_IDLE] && vram_cpu_write) ? V_WRITE :

			    (vram_state[NV_READ] && state[NS_VRAM_RD]) ? V_READW :
			    (vram_state[NV_READW] && ~vram_cpu_req) ? V_IDLE :
   
			    (vram_state[NV_WRITE] && state[NS_VRAM_WR]) ? V_WRITEW :
			    (vram_state[NV_WRITEW] && ~vram_cpu_write) ? V_IDLE :

			    vram_state;
   
   assign i_vram_cpu_req = vram_state[NV_READ];
   assign i_vram_cpu_write = vram_state[NV_WRITE];

   //
   //
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

   assign vram_cpu_data_out = vram_cpu_data;

   //
   // vram_cpu - register addr & data
   //

   wire   latch_vram_addr;
   wire   latch_vram_data;
   
   assign latch_vram_addr = vram_state[NV_IDLE] && (vram_cpu_req || vram_cpu_write);
   assign latch_vram_data = vram_state[NV_IDLE] && vram_cpu_write;

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

   always @(posedge clk)
     if (reset)
       int_vram_cpu_ready <= 0;
     else
       int_vram_cpu_ready <= sram_done[4] ? 1'b1 : (int_vram_cpu_ready && vram_state[NV_READW]);
   
   always @(posedge clk)
     if (reset)
       int_vram_cpu_done <= 0;
     else
       int_vram_cpu_done <= sram_done[6] ? 1'b1 : (int_vram_cpu_done && vram_state[NV_WRITEW]);

   //
   // vram_cpu - cpu interface
   //
   always @(posedge cpu_clk)
     if (reset)
       vram_cpu_ready <= 0;
     else
       vram_cpu_ready <= int_vram_cpu_ready;
   
   always @(posedge cpu_clk)
     if (reset)
       vram_cpu_done <= 0;
     else
       vram_cpu_done <= int_vram_cpu_done;
   
`ifdef debug
   always @(posedge clk)
     if (vram_state[NV_WRITEW] && ~vram_cpu_write)
       $display("vram: W addr %o <- %o; %t",
		int_vram_cpu_addr, int_vram_cpu_data_in, $time);
`endif
   
   //
   // sdram - internal
   //
   reg [4:0] sdram_state;
   wire [4:0] sdram_state_next;
   parameter [4:0]
		SD_IDLE   = 5'b00001,
   		SD_READ   = 5'b00010,
   		SD_READW  = 5'b00100,
		SD_WRITE  = 5'b01000,
		SD_WRITEW = 5'b10000;
      
   parameter [2:0]
		NSD_IDLE   = 0,
   		NSD_READ   = 1,
		NSD_READW  = 2,
   		NSD_WRITE  = 3,
		NSD_WRITEW = 4;
   
   always @(posedge clk)
     if (reset)
       sdram_state <= SD_IDLE;
     else
       sdram_state <= sdram_state_next;

   assign sdram_state_next =
			    (sdram_state[NSD_IDLE] && sdram_req) ? SD_READ :
			    (sdram_state[NSD_IDLE] && sdram_write) ? SD_WRITE :

			    (sdram_state[NSD_READ] && state[NS_SDRAM_RD]) ? SD_READW :
			    (sdram_state[NSD_READW] && ~sdram_req) ? SD_IDLE :
   
			    (sdram_state[NSD_WRITE] && state[NS_SDRAM_WR]) ? SD_WRITEW :
			    (sdram_state[NSD_WRITEW] && ~sdram_write) ? SD_IDLE :

			    sdram_state;
   
   assign i_sdram_req = sdram_state[NSD_READ];
   assign i_sdram_write = sdram_state[NSD_WRITE];

   //
   //
   //
   reg [31:0] sdram_out; // synthesis attribute keep sdram_out true;

   always @(posedge clk)
     if (reset)
       sdram_out <= 0;
     else
       begin
	  if (sram_done[3]/*state[NS_SDRAM_RD]*/)
	    begin
	       sdram_out <= sdram_addr[21:17] == 0 ?
			    {sram1_resp_in, sram2_resp_in} : 32'hffffffff;
	    end
       end

   always @(posedge clk)
     if (reset)
       int_sdram_ready <= 0;
     else
       int_sdram_ready <= sram_done[3] ? 1'b1 : (int_sdram_ready && sdram_state[NSD_READW]);
//       int_sdram_ready <= sram_done[3];

   always @(posedge clk)
     if (reset)
       int_sdram_done <= 0;
     else
       int_sdram_done <= sram_done[5] ? 1'b1 : (int_sdram_done && sdram_state[NSD_WRITEW]);
//       int_sdram_done <= sram_done[5];
	 
   //
   // sdram - cpu interface
   //
   assign sdram_data_out = sdram_out;
   
   always @(posedge cpu_clk)
     if (reset)
       sdram_ready <= 0;
     else
//       sdram_ready <= int_sdram_ready;
       sdram_ready <= int_sdram_ready && sdram_req;

   always @(posedge cpu_clk)
     if (reset)
       sdram_done <= 0;
     else
//       sdram_done <= int_sdram_done;
       sdram_done <= int_sdram_done && sdram_write;

`ifdef debug
   always @(posedge clk)
     begin
	if (sdram_state[NSD_READW] && ~sdram_req && debug)
	  $display("rc: sdram read %o -> %o; %t", sdram_addr, sdram_out, $time);
     end
   
   always @(posedge clk)
     begin
	if (sdram_write && sdram_state[NSD_IDLE] && debug)
	  $display("rc: sdram write %o <- %o; %t", sdram_addr, sdram_data_in, $time);

	if (~sdram_write && sdram_state[NSD_WRITEW] && debug)
	  $display("rc: sdram write done %o <- %o; %t", sdram_addr, sdram_data_in, $time);
     end
`endif

   //----

   reg [4:0] sram_state;
   wire [4:0] sram_state_next;
   wire [7:0] sram_req;
   reg 	      sram_we_n_hold;
   
   always @(posedge clk)
     if (reset)
       sram_state <= 0;
     else
       sram_state <= sram_state_next;

   assign sram_start = (sram_state == 5'b00000) && |sram_req;
   assign sram_begin = sram_state[0];
   assign sram_mid0 = sram_state[1];
   assign sram_mid1 = sram_state[2];
   assign sram_mid2 = sram_state[3];
   assign sram_end = sram_state[4];
   
   assign sram_state_next =
			   (sram_state == 5'b00000) && |sram_req ? 5'b00001 :
			   (sram_state == 5'b00001) ? 5'b00010 :
			   (sram_state == 5'b00010) ? 5'b00100 :
			   (sram_state == 5'b00100 && sram_we_n == 1'b1) ? 5'b10000 :
			   (sram_state == 5'b00100 && sram_we_n == 1'b0) ? 5'b01000 :
			   (sram_state == 5'b01000) ? 5'b10000 :
			   (sram_state == 5'b10000) ? 5'b00000 :
			   sram_state;

   assign sram_req = {
		      state[NS_MCR_WR1] |
		      state[NS_MCR_WR2], 	// [7]
		      state[NS_VRAM_WR], 	// [6]
		      state[NS_SDRAM_WR],	// [5]
		      state[NS_VRAM_RD], 	// [4]
		      state[NS_SDRAM_RD],	// [3]
		      state[NS_VGA_RD],		// [2]
		      state[NS_MCR_RD2],	// [1]
		      state[NS_MCR_RD1]		// [0]
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

	  sram_done <= 0;
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
//	       sram_we_n_hold <= sram_req_we_n;
	       
	       sram1_ce_n <= sram1_req_ce_n;
	       sram1_ub_n <= sram1_req_ub_n;
	       sram1_lb_n <= sram1_req_lb_n;

	       sram2_ce_n <= sram2_req_ce_n;
	       sram2_ub_n <= sram2_req_ub_n;
	       sram2_lb_n <= sram2_req_lb_n;
	    end
	  else
//	    if (sram_begin)
//	      sram_we_n <= sram_we_n_hold;
//	    else
	    if (sram_mid2)
	      sram_we_n <= 1'b1;
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

