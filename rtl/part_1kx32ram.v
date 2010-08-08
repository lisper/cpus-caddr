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

  integer i;

  initial
    begin
      for (i = 0; i < 1024; i=i+1)
        ram[i] = 32'b0;
    end

   always @(posedge clk_a)
     if (wren_a)
        begin
           ram[ address_a ] = data_a;
`ifdef debug
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

`ifdef never

module part_1kx32ram_async(A, DI, DO, CE_N, WE_N);

  input[9:0] A;
  input[31:0] DI;
  input CE_N, WE_N;
  output[31:0] DO;

  reg[31:0] ram [0:1023];

  integer i;

  initial
    begin
      for (i = 0; i < 1024; i=i+1)
        ram[i] = 32'b0;
    end

// I really want negedge(WE_N) + some time
//  always @(posedge WE_N)
always @(negedge WE_N)
    begin
      if (CE_N == 0)
        begin
          ram[ A ] = DI;
	   $display("pdl: W addr %o val %o; %t", A, DI, $time);
        end
    end

  assign DO = ram[ A ];

  always @(A or WE_N or CE_N)
    begin
//       $display("pdl: R %t addr %o val %o, CE_N %d", $time, A, ram[A], CE_N);
    end

endmodule

`endif //  `ifdef never
