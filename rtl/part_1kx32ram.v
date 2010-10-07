/* 1kx32 synchronous static ram */

`include "defines.vh"

module part_1kx32ram_p(clk_a, reset, address_a, data_a, q_a, rden_a, wren_a);

   input clk_a;
   input reset;
   input [9:0] address_a;
   input [31:0] data_a;
   input 	rden_a, wren_a;
   output reg [31:0] q_a;

  reg[31:0] ram [0:1023];

  integer i, debug;

  initial
    begin
      debug = 0;
      for (i = 0; i < 1024; i=i+1)
        ram[i] = 32'b0;
    end

   always @(posedge clk_a)
     if (wren_a)
        begin
           ram[ address_a ] = data_a;
`ifdef debug
	   if (debug != 0)
	     $display("pdl: W addr %o val %o; %t", address_a, data_a, $time);
`endif
        end

   always @(posedge clk_a)
     if (rden_a)
       begin
	  q_a <= ram[ address_a ];
//	  if (address_a != 0)
//	  $display("pdl: R %t addr %o val %o", $time, address_a, ram[address_a]);
       end

endmodule

