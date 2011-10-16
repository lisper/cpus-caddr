
module cpu_test_mcr (clk, reset, addr, data);
   input clk;
   input reset;
   input [13:0] addr;
   output [48:0] data;
   reg [48:0] data;

   always @(posedge clk)
     if (reset)
       data <= 0;
     else
       data <= { 7'b1111111, addr, 7'b0, ~addr, 8'b01011010};

endmodule
