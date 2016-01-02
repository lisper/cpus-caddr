/*
 * top of LX45 fpga for CADDR
 */

`define full_design
`define use_spyport
`define use_vga
//`define use_hdmi
`define use_ps2
`define use_mmc
//`define spy_mmc

module top(usb_txd, usb_rxd,
	   sysclk, led,
	   ps2_clk, ps2_data,
	   ms_ps2_clk, ms_ps2_data,
	   vga_hsync, vga_vsync, vga_r, vga_g, vga_b,
	   mmc_cs, mmc_di, mmc_do, mmc_sclk,
	   switch,
	   mcb3_dram_dq, mcb3_dram_a, mcb3_dram_ba,
	   mcb3_dram_cke, mcb3_dram_ras_n, mcb3_dram_cas_n,
	   mcb3_dram_we_n, mcb3_dram_dm, mcb3_dram_udqs,
	   mcb3_rzq, mcb3_dram_udm, mcb3_dram_dqs,
	   mcb3_dram_ck, mcb3_dram_ck_n,
	   tmds, tmdsb
	   );

   input	usb_rxd;
   output	usb_txd;

   output [4:0] led;
   input 	sysclk;

   input	ps2_clk;
   input 	ps2_data;
   
   inout	ms_ps2_clk;
   inout 	ms_ps2_data;
   
   output 	vga_hsync;
   output 	vga_vsync;
   output 	vga_r;
   output 	vga_g;
   output 	vga_b;

   output 	mmc_cs;
   output 	mmc_do;
   output 	mmc_sclk;
   input 	mmc_di;

   input 	switch;
   
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

   output [3:0]  tmds;
   output [3:0]  tmdsb;

   // -----------------------------------------------------------------

   wire 	 sysclk_buf; // synthesis attribute period clk50 "50 MHz";
   wire 	 clk50;      // synthesis attribute period clk50 "50 MHz";
   wire 	 pixclk;     // synthesis attribute period pixclk "108 MHz";
   wire 	 cpuclk;     // synthesis attribute period cpuclk "25 MHz";

   wire 	 rs232_rxd, rs232_txd;

   wire 	 reset;
   wire 	 vga_reset;
   wire 	 dcm_reset;
   wire 	 lpddr_reset;
   wire 	 interrupt;
   wire		 boot;

   wire [15:0] 	 spy_in;
   wire [15:0] 	 spy_out;
   wire [3:0] 	 spy_reg;
   wire 	 spy_rd;
   wire 	 spy_wr;
   wire 	 dbread, dbwrite;
   wire [4:0] 	 eadr;
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
   wire [15:0] 	 bd_data_cpu2bd;
   wire 	 bd_rd;
   wire 	 bd_wr;
   wire 	 bd_iordy;
   wire [11:0] 	 bd_state;

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

   wire [15:0] 	 kb_data;
   wire 	 kb_ready;
   
   wire [11:0] 	 ms_x, ms_y;
   wire [2:0] 	 ms_button;
   wire 	 ms_ready;

   BUFG sysclk_bufg (.I(sysclk), .O(sysclk_buf));

//   lx45_clocks fpga_clocks(.sysclk(sysclk_buf),
//			   .dcm_reset(dcm_reset),
//			   .clk50(clk50),
//			   .clk1x(cpuclk),
//`ifdef use_hdmi
//			   .pixclk()
//`else
//			   .pixclk(pixclk)
//`endif
//			   
//			   );
   
   support support(.sysclk(sysclk_buf),
		   .cpuclk(cpuclk),
		   .button_r(switch),
		   .button_b(1'b0),
		   .button_h(1'b0),
		   .button_c(1'b0),
		   .dcm_reset(dcm_reset),
		   .lpddr_reset(lpddr_reset),
		   .lpddr_calib_done(lpddr_calib_done),
		   .reset(reset),
		   .interrupt(interrupt),
		   .boot(boot),
		   .halt(halt));

   assign rs232_rxd = usb_rxd;
   assign usb_txd = rs232_txd;

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
	      .spy_reg(spy_reg),
	      .spy_rd(spy_rd),
	      .spy_wr(spy_wr),

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
	      .bd_state_in(bd_state),

	      .kb_data(kb_data),
	      .kb_ready(kb_ready),
	      .ms_x(ms_x),
	      .ms_y(ms_y),
	      .ms_button(ms_button),
	      .ms_ready(ms_ready));
   
`ifdef use_spyport
   wire [1:0] 	 spy_bd_cmd;
   wire 	 spy_bd_start;
   wire 	 spy_bd_bsy;
   wire 	 spy_bd_rdy;
   wire 	 spy_bd_err;
   wire [23:0] 	 spy_bd_addr;
   wire [15:0] 	 spy_bd_data_bd2cpu;
   wire [15:0] 	 spy_bd_data_cpu2bd;
   wire 	 spy_bd_rd;
   wire 	 spy_bd_wr;
   wire 	 spy_bd_iordy;
   wire [15:0] 	 spy_bd_state;

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
		     .eadr(eadr),
 `ifdef spy_mmc
   		     .bd_cmd(spy_bd_cmd),
		     .bd_start(spy_bd_start),
		     .bd_bsy(spy_bd_bsy),
		     .bd_rdy(spy_bd_rdy),
		     .bd_err(spy_bd_err),
		     .bd_addr(spy_bd_addr),
		     .bd_data_in(spy_bd_data_bd2cpu),
		     .bd_data_out(spy_bd_data_cpu2bd),
		     .bd_rd(spy_bd_rd),
		     .bd_wr(spy_bd_wr),
		     .bd_iordy(spy_bd_iordy),
		     .bd_state(spy_bd_state)
 `else
   		     .bd_cmd(),
		     .bd_start(),
		     .bd_bsy(1'b0),
		     .bd_rdy(1'b0),
		     .bd_err(1'b0),
		     .bd_addr(),
		     .bd_data_in(16'b0),
		     .bd_data_out(),
		     .bd_rd(),
		     .bd_wr(),
		     .bd_iordy(1'b0),
		     .bd_state(spy_bd_state[11:0])
 `endif
		     );
`else   
   assign      eadr = 4'b0;
   assign      dbread = 0;
   assign      dbwrite = 0;
   assign      spyin = 0;
   assign      rs232_txd = 1'b1;
`endif
   
   lx45_ram_controller rc (
			   .sysclk_in(sysclk/*sysclk_buf*/),
			   .lpddr_clk_out(),
			   .lpddr_reset(lpddr_reset),
			   .lpddr_calib_done(lpddr_calib_done),
			   
			   .clk(clk50),
			   .vga_clk(pixclk/*clk50*/),
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
			   .vram_vga_ready(vram_vga_ready),

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
			   .mcb3_dram_ck_n(mcb3_dram_ck_n)
			   );
`else
   assign eadr = 4'b0;
   assign dbread = 0;
   assign dbwrite = 0;
   assign spyin = 0;
   assign rs232_txd = 1'b1;
`endif

`ifdef use_mmc
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
			.bd_state(bd_state),

			.mmc_cs(mmc_cs),
			.mmc_di(mmc_di),
			.mmc_do(mmc_do),
			.mmc_sclk(mmc_sclk)
			);
`else
   assign bd_bsy = 0;
   assign bd_rdy = 0;
   assign bd_err = 0;
   assign bd_data_out = 0;
   assign bd_iordy = 0;
`endif

`ifdef spy_mmc
   mmc_block_dev mmc_bd(
			.clk(clk50),
			.reset(reset),
   			.bd_cmd(spy_bd_cmd),
			.bd_start(spy_bd_start),
			.bd_bsy(spy_bd_bsy),
			.bd_rdy(spy_bd_rdy),
			.bd_err(spy_bd_err),
			.bd_addr(spy_bd_addr),
			.bd_data_in(spy_bd_data_cpu2bd),
			.bd_data_out(spy_bd_data_bd2cpu),
			.bd_rd(spy_bd_rd),
			.bd_wr(spy_bd_wr),
			.bd_iordy(spy_bd_iordy),
			.bd_state(spy_bd_state),
				  
			.mmc_cs(mmc_cs),
			.mmc_di(mmc_di),
			.mmc_do(mmc_do),
			.mmc_sclk(mmc_sclk)
			);
`endif
   
`ifdef use_vga
   wire vga_red, vga_blu, vga_grn, vga_blank;

   assign vga_r = vga_red;
   assign vga_g = vga_grn;
   assign vga_b = vga_blu;
   
   vga_display vga (.clk(clk50),
		    .pixclk(pixclk),
		    .reset(vga_reset),

		    .vram_addr(vram_vga_addr),
		    .vram_data(vram_vga_data_out),
		    .vram_req(vram_vga_req),
		    .vram_ready(vram_vga_ready),
      
		    .vga_red(vga_red),
		    .vga_blu(vga_blu),
		    .vga_grn(vga_grn),
		    .vga_hsync(vga_hsync),
		    .vga_vsync(vga_vsync),
		    .vga_blank(vga_blank)
		    );

`else
   assign vram_vga_req = 0;
   assign vga_r = 0;
   assign vga_g = 0;
   assign vga_b = 0;
   assign vga_hsync = 0;
   assign vga_vsync = 0;
`endif

`ifdef use_hdmi
   wire [7:0] red_data, blu_data, grn_data;
   assign red_data = vga_red ? 8'hff : 8'h00;
   assign blu_data = vga_blu ? 8'hff : 8'h00;
   assign grn_data = vga_grn ? 8'hff : 8'h00;
   
   dvid_output dvid (
		     .clk50(sysclk_buf/*clk50*/),
		     .reset(reset),
		     .reset_clk(dcm_reset),
		     .red(red_data),
		     .green(blu_data),
		     .blue(grn_data),
		     .hsync(vga_hsync),
		     .vsync(vga_vsync),
		     .blank(vga_blank),
		     .clk_vga_out(pixclk),
		     .tmds(tmds),
		     .tmdsb(tmdsb)
		     );
`else
   // generate xsvga clock (108Mhz)
   wire pixclk_locked;

   clocking clocking_inst(
			  .CLK_50(sysclk_buf/*sysclk*//*sysclk_buf*/),
			  .CLK_VGA(pixclk),
			  .RESET(dcm_reset),
			  .LOCKED(pixclk_locked)
			  );

   assign vga_reset = reset;
   assign clk50 = sysclk_buf;

   //
//   reg [3:0] clkcnt;
//   initial
//     clkcnt = 0;
//   always @(posedge clk50/*sysclk_buf*/)
//     clkcnt <= clkcnt + 4'd1;
//   BUFG cpuclk_bufg (.I(clkcnt[0]), .O(cpuclk));
   assign cpuclk = clk50;
      
   // dummy drivers
   wire [3:0] tmds_dummy;
   OBUFDS obufds_0(.I(tmds_dummy[0]), .O(tmds[0]), .OB(tmdsb[0]));
   OBUFDS obufds_1(.I(tmds_dummy[1]), .O(tmds[1]), .OB(tmdsb[1]));
   OBUFDS obufds_2(.I(tmds_dummy[2]), .O(tmds[2]), .OB(tmdsb[2]));
   OBUFDS obufds_3(.I(tmds_dummy[3]), .O(tmds[3]), .OB(tmdsb[3]));
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

//   assign led[4] = disk_state[3];
//   assign led[3] = machrun;
//   assign led[2] = disk_state[2];
//   assign led[1] = disk_state[1];
//   assign led[0] = disk_state[0];

   assign led[4] = disk_state[3];
   assign led[3] = machrun;
   assign led[2] = boot;
   assign led[1] = reset;
   assign led[0] = switch;


endmodule
