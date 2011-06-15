/*
 * top of fpga for CADDR
 */

module fpga_clocks(sysclk, slideswitch, dcm_reset,
		   sysclk_buf, clk50, clk100, clk1x, pixclk);

   input sysclk;
   input [7:0] slideswitch;
   input       dcm_reset;
   
   output      sysclk_buf;
   output      clk50;
   output      clk100;
   output      clk1x;
   output      pixclk;
   
   // ------------------------------------
   
   IBUFG sysclk_buffer (.I(sysclk), 
			.O(sysclk_buf));

   // DCM
   wire GND1;
   wire CLKFX_BUF;
   wire CLK2X_BUF;
   wire CLKFB_IN;
   wire LOCKED_OUT;
   
   assign GND1 = 0;
   
   BUFG CLKFX_BUFG_INST (.I(CLKFX_BUF), 
                         .O(pixclk));

   BUFG CLK2X_BUFG_INST (.I(CLK2X_BUF), 
                         .O(CLKFB_IN));

   DCM DCM_INST (.CLKIN(sysclk_buf),
		 .CLKFB(CLKFB_IN), 
                 .DSSEN(GND1), 
                 .PSCLK(GND1), 
                 .PSEN(GND1), 
                 .PSINCDEC(GND1), 
                 .RST(dcm_reset), 
                 .CLKFX(CLKFX_BUF), 
                 .CLK2X(CLK2X_BUF), 
                 .LOCKED(LOCKED_OUT));
   
   defparam DCM_INST.CLK_FEEDBACK = "2X";
   defparam DCM_INST.CLKDV_DIVIDE = 2.0;
   defparam DCM_INST.CLKFX_DIVIDE = 6;
   defparam DCM_INST.CLKFX_MULTIPLY = 13;
   defparam DCM_INST.CLKIN_DIVIDE_BY_2 = "FALSE";
   defparam DCM_INST.CLKIN_PERIOD = 20.0;
   defparam DCM_INST.CLKOUT_PHASE_SHIFT = "NONE";
   defparam DCM_INST.DESKEW_ADJUST = "SYSTEM_SYNCHRONOUS";
   defparam DCM_INST.DFS_FREQUENCY_MODE = "LOW";
   defparam DCM_INST.DLL_FREQUENCY_MODE = "LOW";
   defparam DCM_INST.DUTY_CYCLE_CORRECTION = "TRUE";
   defparam DCM_INST.FACTORY_JF = 16'h8080;
   defparam DCM_INST.PHASE_SHIFT = 0;
   defparam DCM_INST.STARTUP_WAIT = "FALSE";
   
`define use_dcm
`ifdef use_dcm
//   clk100_dcm clk100_dcm(.CLKIN_IN(sysclk_buf), 
//			 .RST_IN(dcm_reset), 
//			 .CLK0_OUT(clk50),
//			 .CLK2X_OUT(clk100), 
//			 .LOCKED_OUT());
   
//   clk_dcm clk_dcm(.CLKIN_IN(sysclk_buf), 
//		   .RST_IN(dcm_reset), 
//		   .CLKFX_OUT(pixclk), 
////		   .CLKIN_IBUFG_OUT(sysclk_buf), 
//		   .LOCKED_OUT());

   wire clk100_dcm;
   wire clk50_dcm;
   
   DCM dcm100(.CLKIN(sysclk_buf),
	      .RST(dcm_reset),
	      .CLKFB(clk50_dcm),
	      .CLK0(clk50_dcm),
	      .CLK2X(clk100_dcm));
   defparam dcm100.CLKIN_PERIOD = 20.0;

   BUFG buf100(.I(clk100_dcm), .O(clk100));

//
reg 	clk100_div2;
assign clk50 = clk100_div2;
always @(posedge clk100)
clk100_div2 <= ~clk100_div2;
//
`else
   reg 	clk100_div2;

   BUFG clk100_bufg (.I(sysclk_buf), .O(clk100));
   assign clk50 = clk100_div2;

   always @(posedge clk100)
     clk100_div2 <= ~clk100_div2;
`endif

   //----
   reg [22:0] slow;

   always @(posedge clk50)
       slow <= slow + 1;

   assign clk1x =
		 slideswitch[6] ? slow[18] :
		 slideswitch[5] ? slow[6] :
		 slideswitch[4] ? slow[5] :
		 slideswitch[3] ? slow[4] :
		 slideswitch[2] ? slow[2] :
		 slideswitch[1] ? slow[1] :
		 slideswitch[0] ? slow[0] :
		 clk50;

endmodule

module top(rs232_txd, rs232_rxd,
	   button, led, sysclk,
	   ps2_clk, ps2_data,
	   vga_red, vga_blu, vga_grn, vga_hsync, vga_vsync,
	   sevenseg, sevenseg_an,
	   slideswitch,
	   sram_a, sram_oe_n, sram_we_n,
	   sram1_io, sram1_ce_n, sram1_ub_n, sram1_lb_n,
	   sram2_io, sram2_ce_n, sram2_ub_n, sram2_lb_n,
	   ide_data_bus, ide_dior, ide_diow, ide_cs, ide_da);

   input	rs232_rxd;
   output	rs232_txd;

   input [3:0] 	button;

   output [7:0] led;
   input 	sysclk; // synthesis attribute period sysclk "50 MHz";

   input	ps2_clk;
   input 	ps2_data;
   
   output 	vga_red;
   output 	vga_blu;
   output 	vga_grn;
   output 	vga_hsync;
   output 	vga_vsync;

   output [7:0] sevenseg;
   output [3:0] sevenseg_an;

   input [7:0] 	slideswitch;

   output [17:0] sram_a;
   output 	 sram_oe_n;
   output 	 sram_we_n;

   inout [15:0]  sram1_io;
   output 	 sram1_ce_n;
   output 	 sram1_ub_n;
   output 	 sram1_lb_n;

   inout [15:0]  sram2_io;
   output 	 sram2_ce_n;
   output 	 sram2_ub_n;
   output 	 sram2_lb_n;
   
   inout [15:0]  ide_data_bus;
   wire [15:0] 	 ide_data_in;
   wire [15:0] 	 ide_data_out;
   output 	 ide_dior;
   output 	 ide_diow;
   output [1:0]  ide_cs;
   output [2:0]  ide_da;

   // -----------------------------------------------------------------

   wire 	 clk50; // synthesis attribute period clk50 "25 MHz";
   wire 	 clk100; // synthesis attribute period clk100 "50 MHz";
   wire 	 pixclk; // synthesis attribute period clk100 "108 MHz";
   wire 	 clk1x; // synthesis attribute period clk1x "25 MHz";
 	 
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
   wire [31:0] 	 sdram_data_out;
   wire [31:0] 	 sdram_data_in;
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

   wire [13:0] 	 pc;
   wire [4:0] 	 cpu_state; // synthesis attribute keep cpu_state true;
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

   fpga_clocks fpga_clocks(.sysclk(sysclk),
			   .slideswitch(slideswitch),
			   .dcm_reset(dcm_reset),
			   .sysclk_buf(sysclk_buf),
			   .clk50(clk50),
			   .clk100(clk100),
			   .clk1x(clk1x),
			   .pixclk(pixclk)
			   );
   
   support support(.sysclk(sysclk_buf),
		   .cpuclk(clk1x),
		   .button_r(button[3]),
		   .button_b(button[2]),
		   .button_h(button[1]),
		   .button_c(button[0]),
		   .dcm_reset(dcm_reset),
		   .reset(reset),
		   .interrupt(interrupt),
		   .boot(boot),
		   .halt(halt));

`define full_design
`ifdef full_design
   caddr cpu (
	      .clk(clk1x),
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
	      .sdram_data_in(sdram_data_in),
	      .sdram_data_out(sdram_data_out),
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

	      .ide_data_in(ide_data_in),
	      .ide_data_out(ide_data_out),
	      .ide_dior(ide_dior),
	      .ide_diow(ide_diow),
	      .ide_cs(ide_cs),
	      .ide_da(ide_da));
   
   assign ide_data_bus = ~ide_diow ? ide_data_out : 16'bz;
   assign ide_data_in = ide_data_bus;
   
   assign      eadr = 4'b0;
   assign      dbread = 0;
   assign      dbwrite = 0;

   fast_ram_controller rc (
		      .clk(clk100),
		      .vga_clk(clk50),
		      .cpu_clk(clk1x),
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
		      .sdram_data_in(sdram_data_out),
		      .sdram_data_out(sdram_data_in),
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
      
		      .sram_a(sram_a),
		      .sram_oe_n(sram_oe_n),
		      .sram_we_n(sram_we_n),
		      .sram1_in(sram1_in),
		      .sram1_out(sram1_out),
		      .sram1_ce_n(sram1_ce_n),
		      .sram1_ub_n(sram1_ub_n),
		      .sram1_lb_n(sram1_lb_n),
		      .sram2_in(sram2_in),
		      .sram2_out(sram2_out),
		      .sram2_ce_n(sram2_ce_n),
		      .sram2_ub_n(sram2_ub_n),
		      .sram2_lb_n(sram2_lb_n)
		      );
`else
   assign ide_data_bus = 0;
   assign ide_dior = 1'b1;
   assign ide_diow = 1'b1;
   assign ide_cs = 0;
   assign ide_da = 0;

   assign sram_a = 0;
   assign sram_oe_n = 1'b1;
   assign sram_we_n = 1'b1;

   assign sram1_io = 0;
   assign sram1_ce_n = 1'b1;
   assign sram1_ub_n = 1'b1;
   assign sram1_lb_n = 1'b1;

   assign sram2_io = 0;
   assign sram2_ce_n = 1'b1;
   assign sram2_ub_n = 1'b1;
   assign sram2_lb_n = 1'b1;
`endif

`define use_vga   
`ifdef use_vga
   wire vram_vga_req_x;
   
   vga_display vga (.clk(clk50),
		    .pixclk(pixclk),
		    .reset(reset),

		    .vram_addr(vram_vga_addr),
		    .vram_data(vram_vga_data_out),
		    .vram_req(vram_vga_req_x),
		    .vram_ready(vram_vga_ready),
      
		    .vga_red(vga_red),
		    .vga_blu(vga_blu),
		    .vga_grn(vga_grn),
		    .vga_hsync(vga_hsync),
		    .vga_vsync(vga_vsync)
		    );

   assign vram_vga_req = slideswitch[7] ? vram_vga_req_x : 0;
`else
   assign vram_vga_req = 0;
   assign vga_red = 0;
   assign vga_blu = 0;
   assign vga_grn = 0;
   assign vga_hsync = 0;
   assign vga_vsync = 0;
`endif
   
   display show_pc(.clk(clk50), .reset(reset),
		   .pc(pc), .dots(dots),
		   .sevenseg(sevenseg), .sevenseg_an(sevenseg_an));

   assign led[7:3] = disk_state[4:0];
   assign led[2] = machrun;
   assign led[1] = ~ide_diow;
   assign led[0] = ~ide_dior;

   assign dots[3:0] = machrun ? cpu_state[3:0] : bus_state[3:0];
   
   assign rs232_txd = 1'b1;

   assign sram1_io = ~sram_we_n ? sram1_out : 16'bz;
   assign sram1_in = sram1_io;
   
   assign sram2_io = ~sram_we_n ? sram2_out : 16'bz;
   assign sram2_in = sram2_io;
   
endmodule
