`timescale 1ns / 1ns

`include "debounce.v"
`include "vga_display.v"
`include "ram_controller.v"
`include "ram_s3board.v"

`include "top.v"

`timescale 1ns / 1ns

module test_top;

   wire	rs232_txd;
   wire rs232_rxd;

   reg [3:0] button;

   wire [7:0] led;
   reg 	      sysclk;

   reg 	      ps2_clk;
   reg 	      ps2_data;
   
   wire       vga_red;
   wire       vga_blu;
   wire       vga_grn;
   wire       vga_hsync;
   wire       vga_vsync;

   wire [7:0] sevenseg;
   wire [3:0] sevenseg_an;

   reg [7:0]  slideswitch;

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

   wire [7:0]  pxd;


   top top(.rs232_txd(rs232_txd),
	   .rs232_rxd(rs232_rxd),
	   .button(button),
	   .led(led),
	   .sysclk(sysclk),

	   .ps2_clk(ps2_clk),
	   .ps2_data(ps2_data),

	   .vga_red(vga_red),
	   .vga_blu(vga_blu), 
	   .vga_grn(vga_grn),
	   .vga_hsync(vga_hsync),
	   .vga_vsync(vga_vsync),

	   .sevenseg(sevenseg),
	   .sevenseg_an(sevenseg_an),
	   .slideswitch(slideswitch),

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
	   .sram2_lb_n(sram2_lb_n),

	   .ide_data_bus(ide_data_bus),
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
		   
  initial
    begin
      $timeformat(-9, 0, "ns", 7);

      $dumpfile("test_top.vcd");
      $dumpvars(0, test_top.top);
    end

  initial
    begin
       sysclk = 0;
//      #5000000
//	begin
//	   $display("SIM DONE!");
//	   $finish;
//	end
    end

  always
    begin
      #10 sysclk = 0;
      #10 sysclk = 1;
    end

   initial
     begin 
	$cv_init_display(1280+64, 1024+64);
//	$cv_init_display(2048, 2048);
     end
   
   assign pxd = { vga_red, vga_red, vga_red, vga_blu, vga_blu, vga_grn, vga_grn, vga_grn };
   
   always @(posedge sysclk) 
     $cv_clk_display(vga_vsync, vga_hsync, pxd);

endmodule


