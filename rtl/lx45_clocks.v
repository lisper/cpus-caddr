/*
 * fpga clock generation
 */

module lx45_clocks(sysclk, dcm_reset,
		   clk50, clk1x, pixclk);

   input sysclk;
   input dcm_reset;

   output clk50;
   output clk1x;
   output pixclk;

//`define fixed_clock_6mhz
//`define fixed_clock_12mhz
`define fixed_clock_25mhz
//`define fixed_clock_50mhz
   
   // ------------------------------------

   assign pixclk = 1'b0;
   assign clk50 = sysclk;
   
`ifdef fixed_clock_50mhz
   assign clk1x = clk50;
`endif

`ifdef fixed_clock_25mhz
   reg clk25;

   initial
     clk25 = 0;

   always @(posedge clk50)
     clk25 = ~clk25;

   BUFG CLK1X_BUFGT (.I(clk25), .O(clk1x));
`endif

`ifdef fixed_clock_12mhz
   reg clk25, clk12;

   initial
     begin
	clk12 = 0;
	clk25 = 0;
     end

   always @(posedge clk50)
     clk25 = ~clk25;

   always @(posedge clk25)
     clk12 = ~clk12;

   BUFG CLK1X_BUFGT (.I(clk12), .O(clk1x));
`endif

`ifdef fixed_clock_6mhz
   reg clk25, clk12, clk6;

   initial
     begin
	clk6 = 0;
	clk12 = 0;
	clk25 = 0;
     end

   always @(posedge clk50)
     clk25 = ~clk25;

   always @(posedge clk25)
     clk12 = ~clk12;

   always @(posedge clk12)
     clk6 = ~clk6;

   BUFG CLK1X_BUFGT (.I(clk6), .O(clk1x));
`endif

endmodule

