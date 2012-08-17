/*
 * top of synthesizable tb for fpga
 *
 * used to test physical interfaces
 */

//`define use_spyport
`define use_vga
`define use_ps2
//`define show_kb

module top(rs232_txd, rs232_rxd,
	   button, led, sysclk,
	   ps2_clk, ps2_data,
//	   ms_ps2_clk, ms_ps2_data,
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
   
//   inout	ms_ps2_clk;
//   inout 	ms_ps2_data;
   wire	ms_ps2_clk;
   wire ms_ps2_data;
   
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
   wire [7:0] 	 switches;

   wire [15:0] 	 kb_data;
   wire 	 kb_ready;
   
   wire [11:0] 	 ms_x, ms_y;
   wire [2:0] 	 ms_button;
   wire 	 ms_ready;

   fpga_clocks fpga_clocks(.sysclk(sysclk),
			   .slideswitch(slideswitch),
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
		   .button_r(button[3]),
		   .button_b(button[2]),
		   .button_h(button[1]),
		   .button_c(button[0]),
		   .dcm_reset(dcm_reset),
		   .reset(reset),
		   .interrupt(interrupt),
		   .boot(boot),
		   .halt(halt));

   cpu_test cpu (
	      .clk(cpuclk),
	      .ext_int(interrupt),
	      .ext_reset(reset),
	      .ext_boot(boot),
	      .ext_halt(halt),
	      .ext_switches(switches),

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
	      .ide_da(ide_da),

	      .kb_data(kb_data),
	      .kb_ready(kb_ready),
	      .ms_x(ms_x),
	      .ms_y(ms_y),
	      .ms_button(ms_button),
	      .ms_ready(ms_ready));
   
   assign ide_data_bus = ~ide_diow ? ide_data_out : 16'bz;
   assign ide_data_in = ide_data_bus;

`ifdef use_spyport
   spy_port spy_port(
		     .sysclk(clk50/*sysclk_buf*/),
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
   assign      spy_in = 0;
   assign      rs232_txd = 1'b1;
`endif
   
   pipe_ram_controller rc (
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

`ifdef use_vga
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
   assign vga_red = 0;
   assign vga_blu = 0;
   assign vga_grn = 0;
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

//   assign ms_ps2_clk = ms_ps2_dir ? ms_ps2_clk_out : 1'bz;
//   assign ms_ps2_data = ms_ps2_dir ? ms_ps2_data_out : 1'bz;
   
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
   
`ifdef show_kb
   reg [15:0] kd;
   reg 	      kg;
   
   always @(posedge sysclk_buf)
     if (reset)
       begin
	  kd <= 0;
	  kg <= 0;
       end
     else
       begin
       if (kb_ready)
	 begin
	    kd <= kb_data;
	    kg <= 1;
	 end
       end
   
   display show_pc(.clk(cpuclk), .reset(reset),
		   .pc({5'b0, kd[7:0]}), .dots(dots),
		   .sevenseg(sevenseg), .sevenseg_an(sevenseg_an));

   assign led = kd[15:8];
   assign dots[3:0] = { 1'b1, ps2_clk, ps2_data, kg };
`else
   display show_pc(.clk(cpuclk), .reset(reset),
		   .pc(pc), .dots(dots),
		   .sevenseg(sevenseg), .sevenseg_an(sevenseg_an));

   assign led[7:3] = disk_state[4:0];
   assign led[2] = machrun;
   assign led[1] = ~ide_diow;
   assign led[0] = ~ide_dior;

//   assign dots[3:0] = machrun ? cpu_state[3:0] : bus_state[3:0];
   assign dots[3:0] = rc_state;
`endif
   
   assign sram1_io = ~sram_we_n ? sram1_out : 16'bz;
   assign sram1_in = sram1_io;
   
   assign sram2_io = ~sram_we_n ? sram2_out : 16'bz;
   assign sram2_in = sram2_io;
   
endmodule
