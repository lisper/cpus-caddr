`timescale 1ns / 1ns

`include "vga_display.v"
`include "ram_controller.v"
`include "ram_s3board.v"

`timescale 1ns / 1ns

module test_top;

   reg 	 clk;
   reg 	 clk100;
   reg 	 reset;

   wire       vga_red;
   wire       vga_blu;
   wire       vga_grn;
   wire       vga_hsync;
   wire       vga_vsync;

   wire [17:0] sram_a;
   wire        sram_oe_n;
   wire        sram_we_n;

   wire [15:0] sram1_io;
   wire        sram1_ce_n;
   wire        sram1_ub_n;
   wire        sram1_lb_n;

   wire [15:0] sram2_io;
   wire        sram2_ce_n;
   wire        sram2_ub_n;
   wire        sram2_lb_n;
   
   wire [15:0] ide_data_bus;
   wire        ide_dior, ide_diow;
   wire [1:0]  ide_cs;
   wire [2:0]  ide_da;

   wire [31:0]  pxd;

   wire [11:0] 	 mcr_addr;
   wire [51:0] 	 mcr_data_out;
   reg [51:0] 	 mcr_data_in;
   wire 	 mcr_ready;
   wire 	 mcr_write;
   wire 	 mcr_done;

   wire [17:0] 	 sdram_addr;
   wire [31:0] 	 sdram_data_out;
   reg [31:0] 	 sdram_data_in;
   wire 	 sdram_ready;
   wire 	 sdram_req;
   wire 	 sdram_write;
   wire 	 sdram_done;

   wire [14:0] 	 vram_addr;
   wire [31:0] 	 vram_data_out;
   reg [31:0] 	 vram_data_in;
   wire 	 vram_req;
   wire 	 vram_ready;
   wire 	 vram_write;
   wire 	 vram_done;

   ram_controller ram_controller(.clk(clk),
				 .reset(reset),

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
				 
				 .vram_addr(vram_addr),
				 .vram_data_in(vram_data_in),
				 .vram_data_out(vram_data_out),
				 .vram_req(vram_req),
				 .vram_ready(vram_ready),
				 .vram_write(vram_write),
				 .vram_done(vram_done),
				 
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

   assign mcr_addr = 0;
   assign mcr_write = 1'b0;

   assign sdram_addr = 0;
   assign sdram_req = 1'b0;
   assign sdram_write = 1'b0;

   assign vram_write = 1'b0;
  
   vga_display vga_display(.clk(clk),
			   .pixclk(clk100),
			   .reset(reset),

			   .vram_addr(vram_addr),
			   .vram_data(vram_data_out),
			   .vram_req(vram_req),
			   .vram_ready(vram_ready),
			   
			   .vga_red(vga_red),
			   .vga_blu(vga_blu),
			   .vga_grn(vga_grn),
			   .vga_hsync(vga_hsync),
			   .vga_vsync(vga_vsync)
			   );

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
		   
   initial
     begin
	$timeformat(-9, 0, "ns", 7);
	$dumpfile("test_top.vcd");
	$dumpvars(0, test_top);
     end

   initial
     begin
	mcr_data_in = 0;
	sdram_data_in = 0;
	vram_data_in = 0;
     end

   initial
     begin
	clk = 0;
	clk100 = 0;
	reset = 0;
	#5 reset = 1;
	#200 reset = 0;
       
//	#500000
//	  begin
//	     $display("SIM DONE!");
//	     $finish;
//	  end
     end

   always
     begin
	#5 clk100 = 0;
	#5 clk100 = 1;
     end

   always
     begin
	#10 clk = 0;
	#10 clk = 1;
     end

   initial
     begin 
	$cv_init_display(1280, 1024);
//	$cv_init_display(1688, 1066);
//	$cv_init_display(2048, 2048);
     end
   
   assign pxd = { 24'b0,
		  vga_red, vga_red, vga_red,
		  vga_blu, vga_blu,
		  vga_grn, vga_grn, vga_grn };
   
   always @(posedge clk100)
     $cv_clk_display(vga_vsync, vga_hsync, pxd);

endmodule


