//
//
//

module dvid_output(input clk50,
		   input 	reset,
		   input 	reset_clk,
		   input [7:0] 	red,
		   input [7:0] 	green,
		   input [7:0] 	blue,
		   input 	hsync,
		   input 	vsync,
		   input 	blank,
		   output 	clk_vga_out,
		   output [3:0] tmds,
		   output [3:0] tmdsb);

   wire       red_s;
   wire       green_s;
   wire       blue_s;
   wire       clock_s;
   
   wire       clk_108, clk_vga;
   wire       clk_vga2x, clk_vga10x;
   wire       clk_locked;

   // generate xsvga clock (108Mhz)
   clocking clocking_inst(
			  .CLK_50(clk50),
			  .CLK_VGA(clk_108),
			  .RESET(reset_clk),
			  .LOCKED(clk_locked)
			  );

   // generate hdmi clocks
   wire pll_clkfbout;
   wire pll_locked;
   wire pll_clk, pll_clkd10, pll_clkd5;

  PLL_BASE #(
    .BANDWIDTH              ("OPTIMIZED"),
    .CLK_FEEDBACK           ("CLKFBOUT"),
    .COMPENSATION           ("SYSTEM_SYNCHRONOUS"),
    .DIVCLK_DIVIDE          (1),
    .CLKFBOUT_MULT          (10),
    .CLKFBOUT_PHASE         (0.000),
    .CLKOUT0_DIVIDE         (1),
    .CLKOUT0_PHASE          (0.000),
    .CLKOUT0_DUTY_CYCLE     (0.500),
    .CLKOUT1_DIVIDE         (10),
    .CLKOUT1_PHASE          (0.000),
    .CLKOUT1_DUTY_CYCLE     (0.500),
    .CLKOUT2_DIVIDE         (5),
    .CLKOUT2_PHASE          (0.000),
    .CLKOUT2_DUTY_CYCLE     (0.500),
    .CLKIN_PERIOD           (10/*9.23076923*//*9.26*/),
    .REF_JITTER             (0.010)
/*
    .CLKIN_PERIOD(9.26),
    .CLKFBOUT_MULT(10), //set VCO to 10x of CLKIN
    .CLKOUT0_DIVIDE(1),
    .CLKOUT1_DIVIDE(10),
    .CLKOUT2_DIVIDE(5),
    .COMPENSATION("INTERNAL")
*/
  ) PLL_OSERDES (
    .CLKFBOUT(pll_clkfbout),
    .CLKOUT0(pll_clk),
    .CLKOUT1(pll_clkd10),
    .CLKOUT2(pll_clkd5),
    .CLKOUT3(),
    .CLKOUT4(),
    .CLKOUT5(),
    .LOCKED(pll_locked),
    .CLKFBIN(pll_clkfbout),
    .CLKIN(clk_108),
    .RST(~clk_locked)
  );

  // clk_vga10x is generated in the BUFPLL below
  BUFG bufg_pllclk2x (.I(pll_clkd5), .O(clk_vga2x));
  BUFG bufg_pllclk (.I(pll_clkd10), .O(clk_vga));
      
  wire serdes_strobe;
  wire serdes_reset;
  wire bufpll_locked;

  assign serdes_reset = reset_clk | ~bufpll_locked;

  BUFPLL #(.DIVIDE(5)) ioclk_buf (.PLLIN(pll_clk), .GCLK(clk_vga2x), .LOCKED(pll_locked),
				  .IOCLK(clk_vga10x), .SERDESSTROBE(serdes_strobe), .LOCK(bufpll_locked));

  dvid dvid_inst(
		 .clk_pixel(clk_vga),
		 .clk_pixel2x(clk_vga2x),
		 .clk_pixel10x(clk_vga10x),
		 .reset    (reset),
		 .serdes_strobe(serdes_strobe),
		 .serdes_reset (serdes_reset),
		 .red_p    (red),
		 .green_p  (green),
		 .blue_p   (blue),
		 .blank    (blank),
		 .hsync    (hsync),
		 .vsync    (vsync),
		 // outputs to TMDS drivers
		 .red_s    (red_s),
		 .green_s  (green_s),
		 .blue_s   (blue_s),
		 .clock_s  (clock_s)
		 );

   OBUFDS OBUFDS_blue  ( .O(tmds[0]), .OB(tmdsb[0]), .I(blue_s ) );
   OBUFDS OBUFDS_green ( .O(tmds[1]), .OB(tmdsb[1]), .I(green_s) );
   OBUFDS OBUFDS_red   ( .O(tmds[2]), .OB(tmdsb[2]), .I(red_s  ) );
   OBUFDS OBUFDS_clock ( .O(tmds[3]), .OB(tmdsb[3]), .I(clock_s) );
      
   assign clk_vga_out = clk_vga;
      
endmodule // dvid_output

