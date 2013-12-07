/*
 * top of LX45 fpga for CADDR
 */

`define full_design
`define use_spyport
`define use_vga
`define use_ps2

module top(rs232_txd, rs232_rxd,
	   sysclk, led,
	   ps2_clk, ps2_data,
	   ms_ps2_clk, ms_ps2_data,
	   vga_out, vga_hsync, vga_vsync,
	   mmc_cs, mmc_di, mmc_do, mmc_sclk
	   );

   input	rs232_rxd;
   output	rs232_txd;

   output [3:0] led;
   input 	sysclk; // synthesis attribute period sysclk "50 MHz";

   input	ps2_clk;
   input 	ps2_data;
   
   inout	ms_ps2_clk;
   inout 	ms_ps2_data;
   
   output 	vga_out;
   output 	vga_hsync;
   output 	vga_vsync;

   output 	mmc_cs;
   output 	mmc_do;
   output 	mmc_sclk;
   input 	mmc_di;
   
   // -----------------------------------------------------------------

   wire 	 clk50; // synthesis attribute period clk50 "50 MHz";
   wire 	 clk100; // synthesis attribute period clk100 "100 MHz";
   wire 	 pixclk; // synthesis attribute period pixclk "108 MHz";
   wire 	 cpuclk; // synthesis attribute period cpuclk "12.5 MHz";
 	 
   wire 	 dcm_reset;
   wire 	 reset;
   wire 	 interrupt;
   wire		 boot;

   wire [15:0] 	 spy_in;
   wire [15:0] 	 spy_out;
   wire 	 dbread, dbwrite;
   wire [3:0] 	 eadr;
   wire 	 halt;
   
   wire [13:0] 	 mcr_addr;
   wire [48:0] 	 mcr_data_out;
   wire [48:0] 	 mcr_data_in;
   wire 	 mcr_ready;
   wire 	 mcr_write;
   wire 	 mcr_done;

   wire [21:0] 	 sdram_addr;
   wire [31:0] 	 sdram_data_cpu2rc;
   wire [31:0] 	 sdram_data_rc2cpu;
   wire 	 sdram_ready; // synthesis attribute keep sdram_ready true;
   wire 	 sdram_req; // synthesis attribute keep sdram_req true;
   wire 	 sdram_write; // synthesis attribute keep sdram_write true;
   wire 	 sdram_done; // synthesis attribute keep sdram_done true;

   wire [14:0] 	 vram_cpu_addr;
   wire [31:0] 	 vram_cpu_data_out;
   wire [31:0] 	 vram_cpu_data_in;
   wire 	 vram_cpu_req;
   wire 	 vram_cpu_ready;
   wire 	 vram_cpu_write;
   wire 	 vram_cpu_done;

   wire [14:0] 	 vram_vga_addr;
   wire [31:0] 	 vram_vga_data_out;
   wire 	 vram_vga_req;
   wire 	 vram_vga_ready;

   wire [1:0] 	 bd_cmd;	/* generic block device interface */
   wire 	 bd_start;
   wire 	 bd_bsy;
   wire 	 bd_rdy;
   wire 	 bd_err;
   wire [23:0] 	 bd_addr;
   wire [15:0] 	 bd_data_bd2cpu;
   wire [15:0] 	 bd_data_cpu2cpu;
   wire 	 bd_rd;
   wire 	 bd_wr;
   wire 	 bd_iordy;

   wire [13:0] 	 pc;
   wire [5:0] 	 cpu_state; // synthesis attribute keep cpu_state true;
   wire [4:0] 	 disk_state; // synthesis attribute keep disk_state true;
   wire [3:0] 	 bus_state; // synthesis attribute keep bus_state true;
   wire [3:0] 	 rc_state; // synthesis attribute keep rc_state true;
   wire 	 machrun;
   wire 	 prefetch;
   wire 	 fetch;

   wire [3:0] 	 dots;

   wire [15:0] 	 sram1_in;
   wire [15:0] 	 sram1_out;
   wire [15:0] 	 sram2_in;
   wire [15:0] 	 sram2_out;

   wire 	 sysclk_buf;

   wire [15:0] 	 kb_data;
   wire 	 kb_ready;
   
   wire [11:0] 	 ms_x, ms_y;
   wire [2:0] 	 ms_button;
   wire 	 ms_ready;

   wire [7:0] 	 switches;
   
   fpga_clocks fpga_clocks(.sysclk(sysclk),
			   .slideswitch(8'b0),
			   .switches(switches),
			   .dcm_reset(dcm_reset),
			   .sysclk_buf(sysclk_buf),
			   .clk50(clk50),
			   .clk100(clk100),
			   .clk1x(cpuclk),
			   .pixclk(pixclk)
			   );
   
   support support(.sysclk(sysclk_buf),
		   .cpuclk(cpuclk),
		   .button_r(1'b0),
		   .button_b(1'b0),
		   .button_h(1'b0),
		   .button_c(1'b0),
		   .dcm_reset(dcm_reset),
		   .reset(reset),
		   .interrupt(interrupt),
		   .boot(boot),
		   .halt(halt));

`ifdef full_design
   caddr cpu (
	      .clk(cpuclk),
	      .ext_int(interrupt),
	      .ext_reset(reset),
	      .ext_boot(boot),
	      .ext_halt(halt),

	      .spy_in(spy_in),
	      .spy_out(spy_out),
	      .dbread(dbread),
	      .dbwrite(dbwrite),
	      .eadr(eadr),

	      .pc_out(pc),
	      .state_out(cpu_state),
	      .disk_state_out(disk_state),
	      .bus_state_out(bus_state),
	      .machrun_out(machrun),
	      .prefetch_out(prefetch),
	      .fetch_out(fetch),
	      .mcr_addr(mcr_addr),
	      .mcr_data_out(mcr_data_out),
	      .mcr_data_in(mcr_data_in),
	      .mcr_ready(mcr_ready),
	      .mcr_write(mcr_write),
	      .mcr_done(mcr_done),

	      .sdram_addr(sdram_addr),
	      .sdram_data_in(sdram_data_rc2cpu),
	      .sdram_data_out(sdram_data_cpu2rc),
	      .sdram_req(sdram_req),
	      .sdram_ready(sdram_ready),
	      .sdram_write(sdram_write),
	      .sdram_done(sdram_done),
      
	      .vram_addr(vram_cpu_addr),
	      .vram_data_in(vram_cpu_data_in),
	      .vram_data_out(vram_cpu_data_out),
	      .vram_req(vram_cpu_req),
	      .vram_ready(vram_cpu_ready),
	      .vram_write(vram_cpu_write),
	      .vram_done(vram_cpu_done),

	      .bd_cmd(bd_cmd),
	      .bd_start(bd_start),
	      .bd_bsy(bd_bsy),
	      .bd_rdy(bd_rdy),
	      .bd_err(bd_err),
	      .bd_addr(bd_addr),
	      .bd_data_in(bd_data_bd2cpu),
	      .bd_data_out(bd_data_cpu2bd),
	      .bd_rd(bd_rd),
	      .bd_wr(bd_wr),
	      .bd_iordy(bd_iordy),

	      .kb_data(kb_data),
	      .kb_ready(kb_ready),
	      .ms_x(ms_x),
	      .ms_y(ms_y),
	      .ms_button(ms_button),
	      .ms_ready(ms_ready));
   
`ifdef use_spyport
   spy_port spy_port(
		     .sysclk(clk50),
		     .clk(cpuclk),
		     .reset(reset),
		     .rs232_rxd(rs232_rxd),
		     .rs232_txd(rs232_txd),
		     .spy_in(spy_out),
		     .spy_out(spy_in),
		     .dbread(dbread),
		     .dbwrite(dbwrite),
		     .eadr(eadr)
		     );
`else   
   assign      eadr = 4'b0;
   assign      dbread = 0;
   assign      dbwrite = 0;
   assign      spyin = 0;
   assign      rs232_txd = 1'b1;
`endif
   
   lx45_ram_controller rc (
			   .clk(clk100),
			   .vga_clk(clk50),
			   .cpu_clk(cpuclk),
			   .reset(reset),
			   .prefetch(prefetch),
			   .fetch(fetch),
			   .machrun(machrun),
			   .state_out(rc_state),

			   .mcr_addr(mcr_addr),
			   .mcr_data_out(mcr_data_in),
			   .mcr_data_in(mcr_data_out),
			   .mcr_ready(mcr_ready),
			   .mcr_write(mcr_write),
			   .mcr_done(mcr_done),

			   .sdram_addr(sdram_addr),
			   .sdram_data_in(sdram_data_cpu2rc),
			   .sdram_data_out(sdram_data_rc2cpu),
			   .sdram_req(sdram_req),
			   .sdram_ready(sdram_ready),
			   .sdram_write(sdram_write),
			   .sdram_done(sdram_done),
      
			   .vram_cpu_addr(vram_cpu_addr),
			   .vram_cpu_data_in(vram_cpu_data_out),
			   .vram_cpu_data_out(vram_cpu_data_in),
			   .vram_cpu_req(vram_cpu_req),
			   .vram_cpu_ready(vram_cpu_ready),
			   .vram_cpu_write(vram_cpu_write),
			   .vram_cpu_done(vram_cpu_done),
      
			   .vram_vga_addr(vram_vga_addr),
			   .vram_vga_data_out(vram_vga_data_out),
			   .vram_vga_req(vram_vga_req),
			   .vram_vga_ready(vram_vga_ready)
			   );
`else
   assign eadr = 4'b0;
   assign dbread = 0;
   assign dbwrite = 0;
   assign spyin = 0;
   assign rs232_txd = 1'b1;
`endif

   mmc_block_dev mmc_bd(
			.clk(clk50),
			.reset(reset),
   			.bd_cmd(bd_cmd),
			.bd_start(bd_start),
			.bd_bsy(bd_bsy),
			.bd_rdy(bd_rdy),
			.bd_err(bd_err),
			.bd_addr(bd_addr),
			.bd_data_in(bd_data_cpu2bd),
			.bd_data_out(bd_data_bd2cpu),
			.bd_rd(bd_rd),
			.bd_wr(bd_wr),
			.bd_iordy(bd_iordy),

			.mmc_cs(mmc_cs),
			.mmc_di(mmc_di),
			.mmc_do(mmc_do),
			.mmc_sclk(mmc_sclk)
			);

`ifdef use_vga
   wire vga_red, vga_blu, vga_grn;
   assign vga_out = vga_grn;
   
   vga_display vga (.clk(clk50),
		    .pixclk(pixclk),
		    .reset(reset),

		    .vram_addr(vram_vga_addr),
		    .vram_data(vram_vga_data_out),
		    .vram_req(vram_vga_req),
		    .vram_ready(vram_vga_ready),
      
		    .vga_red(vga_red),
		    .vga_blu(vga_blu),
		    .vga_grn(vga_grn),
		    .vga_hsync(vga_hsync),
		    .vga_vsync(vga_vsync)
		    );
`else
   assign vram_vga_req = 0;
   assign vga_out = 0;
   assign vga_hsync = 0;
   assign vga_vsync = 0;
`endif

`ifdef use_ps2
   wire   kb_ps2_clk_in;
   wire   kb_ps2_data_in;
   wire   ms_ps2_clk_in;
   wire   ms_ps2_data_in;
   wire   ms_ps2_clk_out;
   wire   ms_ps2_data_out;
   wire   ms_ps2_dir;

   assign kb_ps2_clk_in = ps2_clk;
   assign kb_ps2_data_in = ps2_data;

   assign ms_ps2_clk_in = ms_ps2_clk;
   assign ms_ps2_data_in = ms_ps2_data;

   assign ms_ps2_clk = ms_ps2_dir ? ms_ps2_clk_out : 1'bz;
   assign ms_ps2_data = ms_ps2_dir ? ms_ps2_data_out : 1'bz;
   
   ps2_support ps2_support(
			   .clk(cpuclk),
			   .reset(reset),
			   .kb_ps2_clk_in(kb_ps2_clk_in),
			   .kb_ps2_data_in(kb_ps2_data_in),
			   .ms_ps2_clk_in(ms_ps2_clk_in),
			   .ms_ps2_data_in(ms_ps2_data_in),
			   .ms_ps2_clk_out(ms_ps2_clk_out),
			   .ms_ps2_data_out(ms_ps2_data_out),
			   .ms_ps2_dir(ms_ps2_dir),
			   .kb_data(kb_data),
			   .kb_ready(kb_ready),
			   .ms_x(ms_x),
			   .ms_y(ms_y),
			   .ms_button(ms_button),
			   .ms_ready(ms_ready)
			   );
`else
   assign ps2_clk = 1'bz;
   assign ps2_data = 1'bz;

   assign kb_ready = 0;
   assign kb_data = 0;
   
   assign ms_ready = 0;
   assign ms_x = 0;
   assign ms_y = 0;
   assign ms_button = 0;
`endif
   
   assign led[3] = machrun;
   assign led[2] = disk_state[4];
   assign led[1] = disk_state[3];
   assign led[0] = disk_state[0];

endmodule
