//
// lx45_ram_controller.v
//

`include "defines.vh"

`ifdef ISE
 `define lx45_real_sdram
 `undef lx45_fake_sdram
`endif

`ifdef SIMULATION
 `undef lx45_real_sdram
 `define lx45_fake_sdram
 `define debug
`endif

//force for isim
`define lx45_real_sdram
`undef lx45_fake_sdram

`ifdef FAKE_SDRAM
 `undef lx45_real_sdram
 `define lx45_fake_sdram
`endif

`ifdef debug
 `define debug_sdram
`endif
   

/* 
 * stub ram controller which uses internal LX45 ram and lpddr SDRAM
 *
 * ports:
 * 	microcode	r/w, 64 bits
 * 	sdram		r/w, 32 bits
 * 	vram vga	r/o, 32 bits
 * 	vram cpu	r/w, 32 bits
 *
*/

module lx45_ram_controller(
			   sysclk_in,
			   lpddr_clk_out,
			   lpddr_reset,
			   lpddr_calib_done,
			   
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

			   mcb3_dram_dq, mcb3_dram_a, mcb3_dram_ba,
			   mcb3_dram_cke, mcb3_dram_ras_n, mcb3_dram_cas_n,
			   mcb3_dram_we_n, mcb3_dram_dm, mcb3_dram_udqs,
			   mcb3_rzq, mcb3_dram_udm, mcb3_dram_dqs,
			   mcb3_dram_ck, mcb3_dram_ck_n
			   );

   input sysclk_in;
   output lpddr_clk_out;
   input lpddr_reset;
   output lpddr_calib_done;
   
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

   inout [15:0]  mcb3_dram_dq;
   output [12:0] mcb3_dram_a;
   output [1:0]  mcb3_dram_ba;
   output 	 mcb3_dram_cke;
   output 	 mcb3_dram_ras_n;
   output 	 mcb3_dram_cas_n;
   output 	 mcb3_dram_we_n;
   output 	 mcb3_dram_dm;
   inout 	 mcb3_dram_udqs;
   inout 	 mcb3_rzq;
   output 	 mcb3_dram_udm;
   inout 	 mcb3_dram_dqs;
   output 	 mcb3_dram_ck;
   output 	 mcb3_dram_ck_n;

   // ---------------------------

   reg 		 sdram_done;
   reg 		 sdram_ready;
   
   //
   // sdram - internal
   //
   reg [6:0] sdram_state;
   wire [6:0] sdram_state_next;
   parameter [6:0]
		SD_IDLE     = 7'b0000001,
   		SD_READ     = 7'b0000010,
       		SD_READBSY  = 7'b0000100,
   		SD_READW    = 7'b0001000,
		SD_WRITE    = 7'b0010000,
     		SD_WRITEBSY = 7'b0100000,
		SD_WRITEW   = 7'b1000000;
      
   parameter [2:0]
		NSD_IDLE     = 0,
   		NSD_READ     = 1,
        	NSD_READBSY  = 2,
		NSD_READW    = 3,
   		NSD_WRITE    = 4,
        	NSD_WRITEBSY = 5,
		NSD_WRITEW   = 6;
   
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
	    $display("rc: sdram read  @%o -> %o (0x%x)", sdram_addr, sdram_data_out, sdram_data_out);
	  if (sdram_state[NSD_WRITE])
	    $display("rc: sdram write @%o -> %o (0x%x)", sdram_addr, sdram_data_in, sdram_data_in);
       end
`endif

   wire lpddr_rd_rdy, lpddr_rd_done;
   wire lpddr_wr_rdy, lpddr_wr_done;
   
   assign sdram_state_next =
			    (sdram_state[NSD_IDLE] && sdram_req) ? SD_READ :
			    (sdram_state[NSD_IDLE] && sdram_write) ? SD_WRITE :

			    (sdram_state[NSD_READ] && lpddr_rd_rdy) ? SD_READBSY :
			    (sdram_state[NSD_READBSY] && lpddr_rd_done) ? SD_READW :
			    (sdram_state[NSD_READW] && ~sdram_req) ? SD_IDLE :
   
			    (sdram_state[NSD_WRITE] && lpddr_wr_rdy) ? SD_WRITEBSY :
    			    (sdram_state[NSD_WRITEBSY] && lpddr_wr_done) ? SD_WRITEW :
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
	  if (sdram_state[NSD_READBSY])
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
       if (sdram_state[NSD_READ])
	 int_sdram_ready <= 1'b0;
       else
	 if (sdram_state[NSD_READW])
	   int_sdram_ready <= 1'b1;
//       int_sdram_ready <= lpddr_rd_rdy ? 1'b1 : (int_sdram_ready && sdram_state[NSD_READW]);

   always @(posedge clk)
     if (reset)
       int_sdram_done <= 0;
     else
       if (sdram_state[NSD_WRITE])
	 int_sdram_done <= 1'b0;
       else
	 if (sdram_state[NSD_WRITEW])
	   int_sdram_done <= 1'b1;
//       int_sdram_done <= lpddr_wr_rdy ? 1'b1 : (int_sdram_done && sdram_state[NSD_WRITEW]);
	 
   //
   // sdram - cpu interface
   //
   assign sdram_data_out = sdram_out;
   
   always @(posedge cpu_clk)
     if (reset)
       sdram_ready <= 0;
     else
       sdram_ready <= int_sdram_ready && sdram_req;

   always @(posedge cpu_clk)
     if (reset)
       sdram_done <= 0;
     else
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

   assign lpddr_rd_rdy = 1'b1;
   assign lpddr_rd_done = 1'b1;
   assign lpddr_wr_rdy = 1'b1;
   assign lpddr_wr_done = 1'b1;

   always @(posedge clk)
     if (sdram_state[NSD_WRITE])
       begin
	  if (sdram_addr < DRAM_SIZE)
	    ram[sdram_addr[16:0]] <= sdram_data_in;
       end

   assign mcb3_dram_dq = 0;
   assign mcb3_dram_udqs = 0;
   assign mcb3_rzq = 0;
   assign mcb3_dram_dqs = 0;
   assign lpddr_calib_done = 1'b1;
`endif

`ifdef lx45_real_sdram
   wire sys_clk;
   wire sys_rst;
   wire clock;
   wire reset;

   wire        c3_calib_done;
   wire        lpddr_clk;

   wire [2:0]  lpddr_cmd;
   wire        lpddr_cmd_en;
   wire [29:0] lpddr_addr;
   wire        lpddr_cmd_full;
   wire        lpddr_wr_full;
   wire        lpddr_rd_empty;
   
   assign lpddr_cmd = sdram_write ? 3'b000 : 3'b001;
   assign lpddr_addr = { 6'b0, sdram_addr, 2'b0 };

//   assign lpddr_cmd_en = sdram_state[NSD_READ] || sdram_state[NSD_WRITE];
//   assign lpddr_cmd_en = (sdram_state_next == SD_READBSY) || (sdram_state_next == SD_WRITEBSY);
   assign lpddr_cmd_en = (sdram_state[NSD_READ] && sdram_state_next == SD_READBSY) ||
			  (sdram_state[NSD_WRITE] && sdram_state_next == SD_WRITEBSY);

   assign lpddr_rd_rdy = ~lpddr_cmd_full;
   assign lpddr_rd_done = ~lpddr_rd_empty;
   assign lpddr_wr_rdy = ~lpddr_cmd_full && ~lpddr_wr_full;
   assign lpddr_wr_done = 1'b1;

   assign lpddr_wr_en = sdram_state[NSD_WRITEBSY/*NSD_WRITEW*/];

   assign lpddr_clk_out = lpddr_clk;
   assign lpddr_calib_done = c3_calib_done;

   lpddr lpddr_intf (
		     .sys_clk(sysclk_in),
		     .sys_rst(lpddr_reset),
		     .clock(lpddr_clk),
		     .reset(),

		     .mcb3_dram_dq(mcb3_dram_dq),
		     .mcb3_dram_a(mcb3_dram_a),
		     .mcb3_dram_ba(mcb3_dram_ba),
		     .mcb3_dram_cke(mcb3_dram_cke),
		     .mcb3_dram_ras_n(mcb3_dram_ras_n),
		     .mcb3_dram_cas_n(mcb3_dram_cas_n),
		     .mcb3_dram_we_n(mcb3_dram_we_n),
		     .mcb3_dram_dm(mcb3_dram_dm),
		     .mcb3_dram_udqs(mcb3_dram_udqs),
		     .mcb3_rzq(mcb3_rzq),
		     .mcb3_dram_udm(mcb3_dram_udm),
		     .mcb3_dram_dqs(mcb3_dram_dqs),
		     .mcb3_dram_ck(mcb3_dram_ck),
		     .mcb3_dram_ck_n(mcb3_dram_ck_n),

		     .c3_calib_done(c3_calib_done),
		     .c3_p0_cmd_clk(clk),
		     .c3_p0_cmd_en(lpddr_cmd_en),
		     .c3_p0_cmd_instr(lpddr_cmd),
		     .c3_p0_cmd_bl(6'd0),
		     .c3_p0_cmd_byte_addr(lpddr_addr),
		     .c3_p0_cmd_empty(),
		     .c3_p0_cmd_full(lpddr_cmd_full),

		     .c3_p0_wr_clk(clk),
		     .c3_p0_wr_en(lpddr_wr_en),
		     .c3_p0_wr_mask(4'b0000),
		     .c3_p0_wr_data(sdram_data_in),
		     .c3_p0_wr_full(lpddr_wr_full),
		     .c3_p0_wr_empty(),
		     .c3_p0_wr_count(),
		     .c3_p0_wr_underrun(),
		     .c3_p0_wr_error(),

		     .c3_p0_rd_clk(clk),
		     .c3_p0_rd_en(1'b1),
		     .c3_p0_rd_data(sdram_resp_in),
		     .c3_p0_rd_full(),
		     .c3_p0_rd_empty(lpddr_rd_empty),
		     .c3_p0_rd_count(),
		     .c3_p0_rd_overflow(),
		     .c3_p0_rd_error()
		     );
`endif

   // ---------------------------------------------------------
   // vram_cpu read/write

   reg [31:0]  vram_vga_data;
   wire [31:0]  vram_vga_ram_out;

   part_21kx32dpram vram(
			 .reset(reset),
			 .clk_a(cpu_clk),
			 .address_a(vram_cpu_addr),
			 .q_a(vram_cpu_data_out),
			 .data_a(vram_cpu_data_in),
			 .wren_a(vram_cpu_write),
			 .rden_a(vram_cpu_req),
			
			 .clk_b(vga_clk /*clk*/ /*vga_clk*/),
			 .address_b(vram_vga_addr),
			 .q_b(vram_vga_ram_out),
			 .data_b(32'b0),
			 .wren_b(1'b0),
			 .rden_b(vram_vga_req/*1'b1*/)
			 );

   // this is pretty much a hack
   assign vram_vga_data_out = vram_vga_ready ? vram_vga_ram_out : vram_vga_data;

   always @(posedge vga_clk)
     if (reset)
       vram_vga_data <= 0;
     else
       if (vram_vga_ready)
	 vram_vga_data <= vram_vga_ram_out;
   
   //assign vram_vga_ready = 1'b1;

   reg [3:0] vram_vga_ready_dly;
   always @(posedge vga_clk)
     if (reset)
       vram_vga_ready_dly <= 4'b0;
     else
       vram_vga_ready_dly <= { vram_vga_ready_dly[2:0], vram_vga_req };

   assign vram_vga_ready = vram_vga_ready_dly[0];

   //   
   assign vram_cpu_done  = 1'b1;
   //assign vram_cpu_ready = 1'b1;

   reg [3:0] vram_cpu_ready_dly;
   always @(posedge cpu_clk)
     if (reset)
       vram_cpu_ready_dly <= 4'b0;
     else
       vram_cpu_ready_dly <= { vram_cpu_ready_dly[2:0], vram_cpu_req };

   assign vram_cpu_ready = vram_cpu_ready_dly[3];

   // --------------------------------------------------------
   // unused

   assign mcr_data_out = 0;
   assign mcr_ready = 0;
   assign mcr_done = 0;
   assign state_out = 0;

endmodule

