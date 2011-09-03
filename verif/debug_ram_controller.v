// debug_ram_controller.v

module debug_ram_controller(clk, vga_clk, cpu_clk, reset,
			    prefetch, fetch, machrun, state_out,

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
   reg 		 mcr_ready;
   input 	 mcr_write;
   output 	 mcr_done;

   reg [3:0]	 mcr_dly;
   
   input [21:0]  sdram_addr;
   output [31:0] sdram_data_out;
   input [31:0]  sdram_data_in;
   output 	 sdram_ready;
   input 	 sdram_req;
   input 	 sdram_write;
   output 	 sdram_done;

//   reg 		 sdram_ready;
//   reg 		 sdram_done;
   
   input [14:0]  vram_cpu_addr;
   output [31:0] vram_cpu_data_out;
   input [31:0]  vram_cpu_data_in;
   output 	 vram_cpu_ready;
   input 	 vram_cpu_req;
   input 	 vram_cpu_write;
   output 	 vram_cpu_done;

//   reg 		 vram_cpu_ready;
   reg 		 vram_cpu_done;

   input [14:0]  vram_vga_addr;
   output [31:0] vram_vga_data_out;
   input 	 vram_vga_req;
   output 	 vram_vga_ready;
   
   
   output [17:0] sram_a;
   output 	 sram_oe_n;
   output 	 sram_we_n;
   input [15:0]  sram1_in;
   output [15:0]  sram1_out;
   input [15:0]  sram2_in;
   output [15:0]  sram2_out;
   output 	 sram1_ce_n, sram1_ub_n, sram1_lb_n;
   output 	 sram2_ce_n, sram2_ub_n, sram2_lb_n;

   // ---------------------------

   parameter MCR_RAM_SIZE = 16384;

   reg [48:0] 	 mcr_ram [0:MCR_RAM_SIZE-1];
   reg [48:0] 	 mcr_out;
   reg  	 mcr_state;
 	 
   assign mcr_data_out = mcr_out;

   integer 	 i, debug;

   initial
     begin
	debug = 0;
	for (i = 0; i < MCR_RAM_SIZE; i=i+1)
          mcr_ram[i] = 49'b0;
     end

   always @(posedge cpu_clk)
     if(reset)
       mcr_state <= 0;
     else
       mcr_state <= mcr_write;

   assign mcr_done = mcr_state;
     
   always @(posedge cpu_clk)
     if (mcr_write)
       begin
`ifdef debug_xxx
          // patch out disk-copy (which takes hours to sim)
          if (mcr_addr == 14'o24045)
	    mcr_ram[ mcr_addr ] = 49'h000000001000;
          else
`endif
	  mcr_ram[ mcr_addr ] = mcr_data_in;
`ifdef debug
	  if (debug != 0)
	    $display("iram: W addr %o <- %o; %t",
		     mcr_addr, mcr_data_in, $time);
`endif
       end

   always @(posedge cpu_clk)
     if (reset)
       mcr_dly <= 0;
     else
       mcr_dly <= { mcr_dly[2:0], prefetch };
   
   always @(posedge cpu_clk)
     if (reset)
       begin
	  mcr_out <= 0;
	  mcr_ready <= 0;
       end
     else
       if (mcr_dly[3])
	 begin
	    mcr_out <= mcr_ram[ mcr_addr ];
	    mcr_ready <= 1;
`ifdef debug
	    if (debug != 0)
	      $display("iram: R addr %o -> %o; %t",
		       mcr_addr, mcr_ram[ mcr_addr ], $time);
`endif
	 end
       else
	 mcr_ready <= 0;


   // -------------------------------------------

//   parameter 	 DRAM_SIZE = 2097152;
//   parameter 	 DRAM_BITS = 21;

//   parameter 	 DRAM_SIZE = 1048576;
//   parameter 	 DRAM_SIZE = 524288;

//   parameter 	 DRAM_SIZE = 262144;
//   parameter 	 DRAM_BITS = 18;

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
   
   initial
     for (i = 0; i < DRAM_SIZE; i = i + 1)
       dram[i] = 0;

   assign sdram_addr20 = sdram_addr[DRAM_BITS-1:0];

   assign sdram_data_out = sdram_addr < DRAM_SIZE ?
			   dram[sdram_addr20] : 32'hffffffff;

//   assign sdram_start = ~fetch && ~mcr_state && ack_delayed == 0;
   assign sdram_start = ack_delayed == 0;
   assign sdram_start_write = sdram_start && sdram_write;
   assign sdram_start_read = sdram_start && sdram_req;

   assign sdram_done = ack_delayed[1] && sdram_was_write;
   assign sdram_ready = ack_delayed[1] && sdram_was_read;
   
   always @(posedge cpu_clk)
     if (reset)
       ack_delayed <= 0;
     else
       begin
          ack_delayed[0] <= sdram_start_read || sdram_start_write;
          ack_delayed[1] <= ack_delayed[0];
          ack_delayed[2] <= ack_delayed[1];
          ack_delayed[3] <= ack_delayed[2];
       end

   always @(posedge cpu_clk)
     begin
//	sdram_done = 0;
//	sdram_ready = 0;

`ifdef debug_ddr
	if (sdram_done)
	  begin
	     $display("ddr: write done @%o <- %o; %t",
		      sdram_addr20, sdram_data_in, $time);
	  end

	if (sdram_ready)
	  begin
	     $display("ddr: read done @%o -> %o (0x%x), %t",
		      sdram_addr20,
		      dram[sdram_addr20], dram[sdram_addr20],
		      $time);
	  end
`endif
	  
	if (sdram_start_write)
	  begin
`ifdef debug_ddr
	     $display("ddr: write start @%o <- %o; %t",
		      sdram_addr20, sdram_data_in, $time);
`endif
	     if (sdram_addr < DRAM_SIZE)
	       dram[sdram_addr20] = sdram_data_in;
 	     sdram_was_write = 1;
 	     sdram_was_read = 0;
	  end

	if (sdram_start_read)
	  begin
`ifdef debug_ddr
	     $display("ddr: read start @%o -> %o (0x%x), %t",
		      sdram_addr20,
		      dram[sdram_addr20], dram[sdram_addr20],
		      $time);
`endif
 	     sdram_was_write = 0;
 	     sdram_was_read = 1;
	  end
     end

   // ---------------------------------------------------------

   reg [31:0] 	 vram[0:21503];

   reg [14:0] 	 pending_vram_addr;
   reg [31:0] 	 pending_vram_data;
   reg 		 pending_vram_write;
   reg 		 pending_vram_read;

   initial
     for (i = 0; i < 21504; i = i + 1)
       vram[i] = 0;

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
//	    if (vram_cpu_ready)
	      pending_vram_read <= 0;
       end
   
   reg [2:0] 	 vram_ack_delayed;

   always @(posedge cpu_clk)
     if (reset)
       vram_ack_delayed <= 0;
     else
       begin
          vram_ack_delayed[0] <= vram_cpu_req;
          vram_ack_delayed[1] <= vram_ack_delayed[0];
          vram_ack_delayed[2] <= vram_ack_delayed[1];
       end

//   assign vram_cpu_ready = pending_vram_read;
   assign vram_cpu_ready = vram_ack_delayed[2];

   always @(posedge cpu_clk)
     begin
	vram_cpu_done = 0;
//	vram_cpu_ready = 0;

	//$display("drc: %b %b %b; %b %b",
	//  fetch, mcr_state, pending_vram_write, vram_cpu_done, vram_cpu_ready);

	if (~fetch && ~mcr_state)
	  begin
	     if (pending_vram_write)
	       begin
		  vram[pending_vram_addr] = pending_vram_data;
		  vram_cpu_done = 1;
		  
		  $display("vram: W addr %o <- %o; %t",
			   pending_vram_addr, pending_vram_data, $time);
	       end

//	     if (pending_vram_read)
//	       begin
//		  vram_ready = 1;
//
//		  $display("vram: R addr %o -> %o; %t",
//			   pending_vram_addr, vram[pending_vram_addr], $time);
//	       end
	  end
     end

   // --------------------------------------------------------

   assign sram_a = 0;
   assign sram_oe_n = 1;
   assign sram_we_n = 1;

   assign sram1_out = 0;
   assign sram1_ce_n = 1;
   assign sram1_ub_n = 1;
   assign sram1_lb_n = 1;

   assign sram2_out = 0;
   assign sram2_ce_n = 1;
   assign sram2_ub_n = 1;
   assign sram2_lb_n = 1;

endmodule
