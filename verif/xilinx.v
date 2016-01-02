module PULLDOWN(output O);
  assign O = 1'b0;
endmodule

module IBUFG(input I, output O);
  assign O = I;
endmodule

module BUFG(input I, output O);
  assign O = I;
endmodule

module DCM(
    input CLKIN,
    input RST,
    input CLKFB,
    input DSSEN,
    input PSCLK,
    input PSEN,
    input PSINCDEC,
    output reg CLKDV,
    output CLKFX,
    output reg CLK2X,
    output CLK0,
    output LOCKED);

   parameter
     CLK_FEEDBACK = 0,
       CLKDV_DIVIDE = 0,
       CLKFX_DIVIDE = 0,
       CLKFX_MULTIPLY = 0,
       CLKIN_DIVIDE_BY_2 = 0,
       CLKIN_PERIOD = 0,
       CLKOUT_PHASE_SHIFT = 0,
       DESKEW_ADJUST = 0,
       DFS_FREQUENCY_MODE = 0,
       DLL_FREQUENCY_MODE = 0,
       DUTY_CYCLE_CORRECTION = 0,
       FACTORY_JF = 0,
       PHASE_SHIFT = 0,
       STARTUP_WAIT = 0;

   assign  CLK0 = CLKIN;
   assign  CLKFX = CLKIN;

//   assign  CLKDV = CLKIN;
//   reg 	   CLKDV;

   initial
     CLKDV = 0;
   
`ifdef xxx
   always @(posedge CLKIN)
     CLKDV = ~CLKDV;
`endif

   // 100mhz clock
   always
     begin
	#5 CLK2X = 0;
	#5 CLK2X = 1;
     end
   
   reg [1:0] div;
   initial
     div = 0;

   always @(posedge CLKIN)
     begin
	div <= div + 1;
//	if (div[0])
	if (div == 2'b11)
	  CLKDV = ~CLKDV;
     end
   
endmodule

module lpddr_model_c3(Dq, Dqs, Addr, Ba, Clk, Clk_n, Cke, Cs_n, Ras_n, Cas_n, We_n, Dm);

   input [15:0] Dq;
   input        Dqs;
   input [12:0] Addr;
   input [1:0]  Ba;
   input        Clk;
   input 	Clk_n;
   input 	Cke;
   input 	Cs_n;
   input        Ras_n;
   input 	Cas_n;
   input 	We_n;
   input [1:0] 	Dm;

endmodule
