
module cpu_test_mcr (clk, reset, addr, data, ena);
   input clk;
   input reset;
   input [13:0] addr;
   input 	ena;
   output [48:0] data;
   reg [48:0] data;

   wire [13:0] a;

   always @(posedge clk)
     if (reset)
       data <= 0;
     else
       if (ena)
	 data <= { 8'b11111111, addr, 7'b0, ~addr, 6'b011010};

endmodule
