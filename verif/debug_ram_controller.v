// debug_ram_controller.v

module debug_ram_controller(clk, reset, prefetch, fetch,

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
   input prefetch;
   input fetch;
   
   input [13:0]  mcr_addr;
   output [48:0] mcr_data_out;
   input [48:0]  mcr_data_in;
   output 	 mcr_ready;
   input 	 mcr_write;
   output 	 mcr_done;

   input [21:0]  sdram_addr;
   output [31:0] sdram_data_out;
   input [31:0]  sdram_data_in;
   output 	 sdram_ready;
   input 	 sdram_req;
   input 	 sdram_write;
   output 	 sdram_done;

   reg 		 sdram_ready;
   reg 		 sdram_done;
   
   input [14:0]  vram_addr;
   output [31:0] vram_data_out;
   input [31:0]  vram_data_in;
   output 	 vram_ready;
   input 	 vram_req;
   input 	 vram_write;
   output 	 vram_done;

//   reg 		 vram_ready;
   reg 		 vram_done;
   
   output [17:0] sram_a;
   output 	 sram_oe_n;
   output 	 sram_we_n;
   inout [15:0]  sram1_io;
   inout [15:0]  sram2_io;
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

   always @(posedge clk)
     if(reset)
       mcr_state <= 0;
     else
       mcr_state <= mcr_write;

   assign mcr_done = mcr_state;
     
   always @(posedge clk)
     if (mcr_write)
       begin
	  mcr_ram[ mcr_addr ] = mcr_data_in;
`ifdef debug
	  if (debug != 0)
	    $display("iram: W addr %o <- %o; %t",
		     mcr_addr, mcr_data_in, $time);
`endif
       end

   assign mcr_ready = 1;
   
   always @(posedge clk)
     if (reset)
       mcr_out <= 0;
     else
       if (prefetch)
	 begin
	    mcr_out <= mcr_ram[ mcr_addr ];
`ifdef debug
	    if (debug != 0)
	      $display("iram: R addr %o -> %o; %t",
		       mcr_addr, mcr_ram[ mcr_addr ], $time);
`endif
	 end

   // -------------------------------------------

   parameter 	 DRAM_SIZE = 2097152/*131072*/;

   reg [31:0] 	 dram[DRAM_SIZE-1:0];
   wire [20:0] 	 sdram_addr20;
   reg [10:0] 	 ack_delayed;
   reg 		 sdram_was_write;
   reg 		 sdram_was_read;

   wire 	 sdram_start;
   wire 	 sdram_start_write;
   wire 	 sdram_start_read;
   
   initial
     for (i = 0; i < DRAM_SIZE; i = i + 1)
       dram[i] = 0;

   assign sdram_addr20 = sdram_addr[20:0];

   assign sdram_data_out = sdram_addr < DRAM_SIZE ?
			   dram[sdram_addr20] : 32'hffffffff;

//   assign sdram_start = ~fetch && ~mcr_state && ack_delayed == 0;
assign sdram_start = ack_delayed == 0;
   assign sdram_start_write = sdram_start && sdram_write;
   assign sdram_start_read = sdram_start && sdram_req;

   assign sdram_done = ack_delayed[7] && sdram_was_write;
   assign sdram_ready = ack_delayed[7] && sdram_was_read;
   
   always @(posedge clk)
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
	  ack_delayed[7] <= ack_delayed[6];
	  ack_delayed[8] <= ack_delayed[7];
       end

   always @(posedge clk)
     begin
	sdram_done = 0;
	sdram_ready = 0;

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
	  
	if (sdram_start_write)
	  begin
	     $display("ddr: write start @%o <- %o; %t",
		      sdram_addr20, sdram_data_in, $time);

	     if (sdram_addr < DRAM_SIZE)
	       dram[sdram_addr20] = sdram_data_in;
 	     sdram_was_write = 1;
 	     sdram_was_read = 0;
	  end

	if (sdram_start_read)
	  begin
	     $display("ddr: read start @%o -> %o (0x%x), %t",
		      sdram_addr20,
		      dram[sdram_addr20], dram[sdram_addr20],
		      $time);
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

   assign vram_data_out = vram[vram_addr];

   
   always @(posedge clk)
     if (reset)
       begin
	  pending_vram_addr <= 0;
	  pending_vram_data <= 0;
	  
	  pending_vram_write <= 0;
	  pending_vram_read <= 0;
       end
     else
       begin
	  if (vram_write)
	    begin
	       pending_vram_addr <= vram_addr;
	       pending_vram_data <= vram_data_in;
	       pending_vram_write <= 1;
	    end
	  else
	    if (vram_done)
	       pending_vram_write <= 0;
	  
	  if (vram_req)
	    begin
$display("vram: R addr %o -> %o; %t",
	 vram_addr, vram[vram_addr], $time);
	       pending_vram_addr <= vram_addr;
	       pending_vram_read <= 1;
	    end
	  else
//	    if (vram_ready)
	      pending_vram_read <= 0;
       end
   
   
   assign vram_ready = pending_vram_read;

   always @(posedge clk)
     begin
	vram_done = 0;
//	vram_ready = 0;

	//$display("drc: %b %b %b; %b %b",
	//  fetch, mcr_state, pending_vram_write, vram_done, vram_ready);

	if (~fetch && ~mcr_state)
	  begin
	     if (pending_vram_write)
	       begin
		  vram[pending_vram_addr] = pending_vram_data;
		  vram_done = 1;
		  
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

   assign sram1_io = 0;
   assign sram1_ce_n = 1;
   assign sram1_ub_n = 1;
   assign sram1_lb_n = 1;

   assign sram2_io = 0;
   assign sram2_ce_n = 1;
   assign sram2_ub_n = 1;
   assign sram2_lb_n = 1;

endmodule
