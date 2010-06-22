/* 32x19 synchronous static ram */

module part_32x19ram_sync(CLK, A, DI, DO, WE_N, CE_N);

   input [4:0] A;
   input [18:0] DI;
   input WE_N, CLK, CE_N;
   output reg [18:0] DO;

   reg [18:0] ram [0:31];

   initial
     begin
	ram[ 5'b00000 ] = 19'b0;
	ram[ 5'b11111 ] = 19'b0;
     end

   always @(posedge CLK)
     if (~CE_N && ~WE_N)
       begin
	  ram[ A ] = DI;
	  if (A != 0)
	    $display("spc: W addr %o val %o; %t", A, DI, $time);
       end

   always @(posedge CLK)
     begin
	DO <= ram[ A ];
//	if (A != 0)
//	  $display("spc: R %t addr %o val %o", $time, A, ram[ A ]);
     end

endmodule

module part_32x19ram_async(A, DI, DO, WE_N, CE_N);

   input [4:0] A;
   input [18:0] DI;
   input WE_N, CE_N;
   output [18:0] DO;

   reg [18:0] ram [0:31];

   initial
     begin
	ram[ 5'b00000 ] = 19'b0;
	ram[ 5'b11111 ] = 19'b0;
     end

  always @(negedge WE_N)
     begin
	if (CE_N == 0)
	  ram[ A ] = DI;
     end

   assign DO = ram[ A ];

endmodule

