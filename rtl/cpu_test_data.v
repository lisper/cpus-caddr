
module cpu_test_data (clk, reset, addr, data, ena);
   input clk;
   input reset;
   input [21:0] addr;
   input 	ena;
   output [31:0] data;
   reg [31:0] data;

   always @(posedge clk)
     if (reset)
       data <= 0;
     else
       if (ena)
	 data <= ~addr;

endmodule
