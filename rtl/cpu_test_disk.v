
module cpu_test_disk (clk, reset, addr, data);
   input clk;
   input reset;
   input [7:0] addr;
   output [31:0] data;
   reg [31:0] data;

   always @(posedge clk)
     if (reset)
       data <= 0;
     else
       data <= { ~addr, addr, addr, ~addr };

endmodule
