/* 32x32 synchronous static ram */

module part_32x32ram_sync(CLK, A, DI, DO, CE_N, WE_N);

   input[4:0] A;
   input [31:0] DI;
   input CLK, WE_N, CE_N;
   output reg [31:0] DO;

   reg [31:0] ram [0:31];

`ifdef debug
   integer index, debug;

   initial
     begin
	debug = 0;
	for (index = 0; index < 32; index=index+1)
          ram[index] = 32'b0;
    end
`endif
   
   always @(posedge CLK)
    if (~CE_N && ~WE_N)
     begin
	ram[ A ] = DI;
`ifdef debug
	if (A != 0 && debug != 0)
	  $display("mmem: W addr %o val %0o; %t", A, DI, $time);
`endif
     end

   always @(A or CE_N or WE_N or CLK)
     begin
	DO = ram[ A ];
`ifdef debug
	if (A != 0 && debug != 0)
	  $display("mmem: R addr %o val %0o; %t", A, ram[ A ], $time);
`endif
     end
   
endmodule

module part_32x32ram_async(A, DI, DO, WE_N, CE_N);

   input[4:0] A;
   input [31:0] DI;
   input WE_N, CE_N;
   output [31:0] DO;

   reg [31:0] ram [0:31];

`ifdef debug
   integer    index, debug;

   initial
    begin
      for (index = 0; index < 32; index=index+1)
        ram[index] = 32'b0;
    end
`endif
   
   always @(negedge WE_N)
     begin
	if (CE_N == 0)
	  begin
	     ram[ A ] = DI;
`ifdef debug
	     if (debug == 1)
	       $display("mmem: W addr %o val %o; %t", A, DI, $time);
`endif
	  end
     end

   assign DO = ram[ A ];

   always @(A or CE_N or WE_N)
     begin
`ifdef debug
	if (CE_N == 0 && WE_N && debug == 1)
	  $display("mmem: R addr %o val %o; %t", A, ram[ A ], $time);
`endif
     end
   
endmodule

