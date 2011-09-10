/*
 * fpga clock generation
 */

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

`define pixclk_dcm
`define clk100_dcm
//`define no_dcm
   
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
`endif
   
`ifdef clk100_dcm
   wire clk100_dcm;
   wire clk50_dcm;
   
   DCM dcm100(.CLKIN(sysclk_buf),
	      .RST(dcm_reset),
	      .CLKFB(clk50_dcm),
	      .CLK0(clk50_dcm),
	      .CLK2X(clk100_dcm));
   defparam dcm100.CLKIN_PERIOD = 20.0;

   BUFG buf100(.I(clk100_dcm), .O(clk100));
   BUFG buf50(.I(clk50_dcm), .O(clk50));
`endif

`ifdef no_dcm
   assign sysclk_buf = sysclk;
   
   reg 	clk100, clk50;

   always @(posedge sysclk_buf)
     clk100 <= ~clk100;

   always @(posedge clk100)
     clk50 <= ~clk50;
`endif
   
   //----
   reg [22:0] slow;

   always @(posedge clk100)
     switches <= slideswitch;
   
   always @(posedge clk50)
       slow <= slow + 1;

   assign clk1x =
		 switches[6] ? slow[20] :
		 switches[5] ? slow[19] :
		 switches[4] ? slow[18] :
		 switches[3] ? slow[17] :
		 switches[2] ? slow[2] :
		 switches[1] ? slow[1] :
		 switches[0] ? slow[0] :
		 clk50;

endmodule

