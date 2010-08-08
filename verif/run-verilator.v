/*
 */

//`define debug_vcd
`define debug
`define DBG_DLY
  
//`include "defs.v"
`include "rtl.v"

`timescale 1ns / 1ns

module wrap_ide(clk, ide_data_in, ide_data_out,
		ide_dior, ide_diow, ide_cs, ide_da);

   input clk;
   input [15:0]  ide_data_in;
   output [15:0] ide_data_out;
   input 	 ide_dior;
   input 	 ide_diow;
   input [1:0] 	 ide_cs;
   input [2:0] 	 ide_da;
		
   import "DPI-C" function void dpi_ide(input integer data_in,
					output integer data_out,
				        input integer dior,
				        input integer diow,
				        input integer cs,
				        input integer da);

   integer dbi, dbo;
   wire [31:0] dboo;
      
   assign dbi = {16'b0, ide_data_in};
   assign dboo = dbo;

   assign ide_data_out = dboo[15:0];

   always @(posedge clk)
     begin
	dpi_ide(dbi,
		dbo,
		{31'b0, ide_dior}, 
		{31'b0, ide_diow},
		{30'b0, ide_cs},
		{29'b0, ide_da});

`ifdef debug_ide
	if (ide_dior == 0)
	  begin
	     $display("wrap_ide: read (%b %b) %x %x %x %x",
		      ide_dior, ide_diow, dbo, dboo, dboo[15:0], ide_data_out);
	  end
	if (ide_diow == 0)
	  begin
	     $display("wrap_ide: write (%b %b) %x %x %x",
		      ide_dior, ide_diow, dbo, dboo, ide_data_out);
	  end
`endif
     end

endmodule

module test;
   reg clk;
   reg clk100;
   reg reset;
   reg interrupt;

   // controlled by rc circuit at power up
   reg boot;

   reg [15:0]  spyin;
   wire [15:0] spyout;
   wire        dbread, dbwrite;
   wire [3:0]  eadr;

   wire [15:0] 	ide_data_in;
   wire [15:0] 	ide_data_out;
   wire 	ide_dior;
   wire 	ide_diow;
   wire [1:0] 	ide_cs;
   wire [2:0] 	ide_da;

   wire 	halt;

   wire [13:0] 	 mcr_addr;
   wire [48:0] 	 mcr_data_out;
   wire [48:0] 	 mcr_data_in;
   wire 	 mcr_ready;
   wire 	 mcr_write;
   wire 	 mcr_done;

   wire [21:0] 	 sdram_addr;
   wire [31:0] 	 sdram_data_out;
   wire [31:0] 	 sdram_data_in;
   wire 	 sdram_ready;
   wire 	 sdram_req;
   wire 	 sdram_write;
   wire 	 sdram_done;

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

   wire 	 prefetch;
   wire 	 fetch;
   
   wire [17:0] 	 sram_a;
   wire 	 sram_oe_n, sram_we_n;
   /* verilator lint_off UNOPTFLAT */
   wire [15:0] 	 sram1_io;
   wire [15:0] 	 sram2_io;
   /* verilator lint_on UNOPTFLAT */
   wire 	 sram1_ce_n, sram1_ub_n, sram1_lb_n;
   wire 	 sram2_ce_n, sram2_ub_n, sram2_lb_n;

   caddr cpu (.clk(clk),
	      .ext_int(interrupt),
	      .ext_reset(reset),
	      .ext_boot(boot),
	      .ext_halt(halt),

	      .spy_in(spyin),
	      .spy_out(spyout),
	      .dbread(dbread),
	      .dbwrite(dbwrite),
	      .eadr(eadr),

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

`define real_rc
`ifdef real_rc
   ram_controller
`else
   debug_ram_controller
`endif
		  rc
		     (.clk(clk),
		      .clk2x(clk100),
		      .reset(reset),
		      .prefetch(prefetch),
		      .fetch(fetch),
		      
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
		      .sram1_io(sram1_io),
		      .sram1_ce_n(sram1_ce_n),
		      .sram1_ub_n(sram1_ub_n),
		      .sram1_lb_n(sram1_lb_n),
		      .sram2_io(sram2_io),
		      .sram2_ce_n(sram2_ce_n),
		      .sram2_ub_n(sram2_ub_n),
		      .sram2_lb_n(sram2_lb_n)
		      );
   
   wire 	 vga_red, vga_blu, vga_grn, vga_hsync, vga_vsync;

   vga_display vga (.clk(clk),
		    .pixclk(clk100),
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

`ifdef show_vga
   import "DPI-C" function void dpi_vga_init(input integer h,
					     input integer v);

   import "DPI-C" function void dpi_vga_display(input integer vsync,
						input integer hsync,
    						input integer pixel);

   wire [31:0] 	 pxd;
   
   initial
     begin 
	dpi_vga_init(1280, 1024);
     end
   
   assign pxd = { 24'b0,
		  vga_red, vga_red, vga_red,
		  vga_blu, vga_blu,
		  vga_grn, vga_grn, vga_grn };
   
   always @(posedge clk100)
     dpi_vga_display({31'b0, vga_vsync}, {31'b0, vga_hsync}, pxd);

`endif
   
   //---------------------------------------------------------------
   
   assign 	halt = 0;
   
//   integer     addr;
//   integer     debug_level;
//   integer     dumping;
//   integer     cycles;
//   integer     max_cycles;
     
   assign      eadr = 4'b0;
   assign      dbread = 0;
   assign      dbwrite = 0;
   assign      spyin = 0;

   wrap_ide wrap_ide(.clk(clk),
		     .ide_data_in(ide_data_out),
		     .ide_data_out(ide_data_in),
		     .ide_dior(ide_dior),
		     .ide_diow(ide_diow),
		     .ide_cs(ide_cs),
		     .ide_da(ide_da));

   ram_s3board ram(.ram_a(sram_a),
		   .ram_oe_n(sram_oe_n),
		   .ram_we_n(sram_we_n),
		   .ram1_io(sram1_io),
		   .ram1_ce_n(sram1_ce_n),
		   .ram1_ub_n(sram1_ub_n),
		   .ram1_lb_n(sram1_lb_n),
		   .ram2_io(sram2_io),
		   .ram2_ce_n(sram2_ce_n),
		   .ram2_ub_n(sram2_ub_n),
		   .ram2_lb_n(sram2_lb_n));
		   
endmodule
