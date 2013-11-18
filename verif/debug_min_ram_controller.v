// min_ram_controller.v

module min_ram_controller(clk, vga_clk, cpu_clk, reset,
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
   input 	 mcr_write;
   output 	 mcr_done;

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

   // ---------------------------------------------------------

   reg [31:0] 	 vram[0:21503];

   reg [14:0] 	 pending_vram_addr;
   reg [31:0] 	 pending_vram_data;
   reg 		 pending_vram_write;
   reg 		 pending_vram_read;

   integer 	 vi;
   
   initial
     for (vi = 0; vi < 21504; vi = vi + 1)
       vram[vi] = 0;

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

	if (~fetch/* && ~mcr_state*/)
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
