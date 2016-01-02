/*
 * fpga clock generation
 */

//`define pixclk_dcm
//`define clk100_dcm

//`define fixed_dcm_12Mhz
//`define no_dcm

//`define switch_clock
//`define fixed_clock_6mhz
//`define fixed_clock_12mhz
`define fixed_clock_25mhz
//`define fixed_clock_50mhz
   
module fpga_clocks(sysclk, slideswitch, switches, dcm_reset,
		   sysclk_buf, clk50, clk100, clk1x, pixclk);

   input sysclk;
   input [7:0] slideswitch;
   input       dcm_reset;
   
   output      sysclk_buf;
   output      clk50;
   output      clk100;
   output      clk1x;
   output      pixclk;

   output [7:0] switches;
   reg [7:0] 	switches;
   
   // ------------------------------------

   IBUFG sysclk_buffer (.I(sysclk), 
			.O(sysclk_buf));

   always @(posedge clk100)
     switches <= slideswitch;
   
`ifdef pixclk_dcm
   // DCM - pixclk
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

   DCM DCM_INST (.CLKIN(clk50/*sysclk_buf*/),
		 .CLKFB(CLKFB_IN), 
                 .DSSEN(GND1), 
                 .PSCLK(GND1), 
                 .PSEN(GND1), 
                 .PSINCDEC(GND1), 
                 .RST(dcm_reset),
		 .CLK0(),
		 .CLKDV(),
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
`endif
   
`ifdef clk100_dcm
   wire clk100_dcm;
   wire clk50_dcm;

   DCM dcm100(.CLKIN(sysclk_buf),
	      .RST(dcm_reset),
	      .DSSEN(), 
              .PSCLK(), 
              .PSEN(), 
              .PSINCDEC(), 
	      .CLKDV(),
              .CLKFX(), 
              .LOCKED(),
	      .CLKFB(clk50/*_dcm*/),
	      .CLK0(clk50_dcm),
	      .CLK2X(clk100_dcm));
   defparam dcm100.CLKIN_PERIOD = 20.0;

   BUFG buf100(.I(clk100_dcm), .O(clk100));
   BUFG buf50(.I(clk50_dcm), .O(clk50));
`endif

`ifdef no_dcm
   BUFG buf100(.I(sysclk_buf), .O(clk100));
   
   reg 	clk50;
   always @(posedge clk100)
     clk50 <= ~clk50;
`endif

`ifdef switch_clock   
   //----
   reg [22:0] slow;

   always @(posedge clk50)
       slow <= slow + 1;

   assign clk1x =
		 switches[6] ? slow[10] :
		 switches[5] ? slow[8] :
		 switches[4] ? slow[4] : // 32
		 switches[3] ? slow[3] : // 16
		 switches[2] ? slow[2] : // 8
		 switches[1] ? slow[1] : // 4
		 switches[0] ? slow[0] : // 2
		 clk50;
`else
   always @(posedge clk100)
     switches <= slideswitch;
`endif

`ifdef fixed_clock_50mhz
   BUFG CLK1X_BUFGT (.I(clk50), .O(clk1x));
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

`ifdef fixed_dcm_12Mhz
   wire clk100_dcm;
   wire clk50_dcm;
   wire clk1x_dcm;
   
   DCM dcm100(.CLKIN(sysclk_buf),
	      .RST(dcm_reset),
	      .CLKFB(clk50/*_dcm*/),
	      .CLKDV(clk1x_dcm),
	      .CLK0(clk50_dcm),
	      .CLK2X(clk100_dcm));
   defparam dcm100.CLKIN_PERIOD = 20.0;
   defparam dcm100.CLKDV_DIVIDE = 4;
   defparam dcm100.FACTORY_JF = 16'h8080;

   BUFG buf100(.I(clk100_dcm), .O(clk100));
   BUFG buf50(.I(clk50_dcm), .O(clk50));
   BUFG buf1x(.I(clk1x_dcm), .O(clk1x));
`endif
   
`ifndef pixclk_dcm
   assign pixclk = 0;
`endif
   
endmodule

