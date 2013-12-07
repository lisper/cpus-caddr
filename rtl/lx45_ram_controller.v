//
// lx45_ram_controller.v
//

/* 
 * stub ram controller which uses internal LX45 ram and SDRAM
 *
 * ports:
 * 	microcode	r/w, 64 bits
 * 	sdram		r/w, 32 bits
 * 	vram vga	r/o, 32 bits
 * 	vram cpu	r/w, 32 bits
 *
*/

module lx45_ram_controller(
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
			   vram_vga_req, vram_vga_ready);

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

   // ---------------------------

   reg 		 sdram_done;
   reg 		 sdram_ready;
   
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

`ifdef debug_sdram
   always @(posedge clk)
     if (sdram_state != sdram_state_next)
       begin
	  //$display("sdram: state %b", sdram_state_next);
	  if (sdram_state[NSD_READ])
	    $display("sdram: read  @%o -> %o", sdram_addr, sdram_data_out);
	  if (sdram_state[NSD_WRITE])
	    $display("sdram: write @%o -> %o ", sdram_addr, sdram_data_in);
       end
`endif
   
   assign sdram_state_next =
			    (sdram_state[NSD_IDLE] && sdram_req) ? SD_READ :
			    (sdram_state[NSD_IDLE] && sdram_write) ? SD_WRITE :

			    (sdram_state[NSD_READ] /*&& state[NS_SDRAM_RD]*/) ? SD_READW :
			    (sdram_state[NSD_READW] && ~sdram_req) ? SD_IDLE :
   
			    (sdram_state[NSD_WRITE] /*&& state[NS_SDRAM_WR]*/) ? SD_WRITEW :
			    (sdram_state[NSD_WRITEW] && ~sdram_write) ? SD_IDLE :

			    sdram_state;

   wire i_sdram_req, i_sdram_write;
   
   assign i_sdram_req = sdram_state[NSD_READ];
   assign i_sdram_write = sdram_state[NSD_WRITE];

   //
   //
   //
   reg [31:0] sdram_out; // synthesis attribute keep sdram_out true;
   wire [31:0] sdram_resp_in;
   
   always @(posedge clk)
     if (reset)
       sdram_out <= 0;
     else
       begin
	  if (1/*state[NS_SDRAM_RD]*/)
	    begin
	       sdram_out <= sdram_addr[21:17] == 0 ? sdram_resp_in : 32'hffffffff;
	    end
       end

   reg int_sdram_ready;
   reg int_sdram_done;
   
   always @(posedge clk)
     if (reset)
       int_sdram_ready <= 0;
     else
       int_sdram_ready <= 1 ? 1'b1 : (int_sdram_ready && sdram_state[NSD_READW]);

   always @(posedge clk)
     if (reset)
       int_sdram_done <= 0;
     else
       int_sdram_done <= 1 ? 1'b1 : (int_sdram_done && sdram_state[NSD_WRITEW]);
	 
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

`ifdef lx45_fake_sdram
   parameter 	 DRAM_SIZE = 131072;
   reg [31:0] 	 ram[DRAM_SIZE-1:0];

   integer i;
   initial
     begin
	for (i = 0; i < DRAM_SIZE; i = i + 1)
	  ram[i] = 0;
     end

   assign sdram_resp_in = sdram_addr < DRAM_SIZE ? ram[sdram_addr[16:0]] : 32'hffffffff;

   always @(posedge clk)
     if (sdram_state[NSD_WRITE])
       begin
	  if (sdram_addr < DRAM_SIZE)
	    ram[sdram_addr[16:0]] <= sdram_data_in;
       end
   
`endif

   // ---------------------------------------------------------
   // vram_cpu read/write

   part_21kx32dpram vram(
			 .reset(reset),
			 .clk_a(cpu_clk),
			 .address_a(vram_cpu_addr),
			 .q_a(vram_cpu_data_out),
			 .data_a(vram_cpu_data_in),
			 .wren_a(vram_cpu_write),
			 .rden_a(vram_cpu_req),
			
			 .clk_b(clk /*vga_clk*/),
			 .address_b(vram_vga_addr),
			 .q_b(vram_vga_data_out),
			 .data_b(32'b0),
			 .wren_b(1'b0),
			 .rden_b(1'b1)
			 );

   assign vram_cpu_ready = 1'b1;
   assign vram_vga_ready = 1'b1;
   assign vram_cpu_done  = 1'b1;

   // --------------------------------------------------------
   // unused

   assign mcr_data_out = 0;
   assign mcr_ready = 0;
   assign mcr_done = 0;
   assign state_out = 0;

endmodule

