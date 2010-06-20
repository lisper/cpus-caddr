/* 1kx32 synchronous static ram */

module part_1kx32ram_sync_a(CLK, A, DI, DO, CE_N, WE_N);

   input CLK;
   input [9:0] A;
   input [31:0] DI;
   input CE_N, WE_N;
   output reg [31:0] DO;

   reg [31:0] ram [0:1023];

`ifdef debug
  integer i, debug;

  initial
    begin
       debug = 0;
       for (i = 0; i < 1024; i=i+1)
         ram[i] = 32'b0;
    end
`endif

   always @(posedge CLK)
     if (~CE_N && ~WE_N)
       begin
          ram[ A ] <= DI;
`ifdef debug
	  if (A != 0 && debug != 0)
	    $display("amem: W addr %o val %o; %t", A, DI, $time);
`endif
       end

   always @(posedge CLK)
     if (~CE_N)
       begin
	  DO <= ram[ A ];
`ifdef debug
	  if (A != 0 && debug != 0)
	    $display("amem: R addr %o val %o; %t", A, ram[ A ], $time);
`endif
       end

endmodule

module part_1kx32ram_async_a(A, DI, DO, CE_N, WE_N);

  input[9:0] A;
  input[31:0] DI;
  input CE_N, WE_N;
  output[31:0] DO;

  reg[31:0] ram [0:1023];

`ifdef debug
  integer i, debug;

  initial
    begin
       debug = 0;
       for (i = 0; i < 1024; i=i+1)
         ram[i] = 32'b0;
    end
`endif
   
   always @(negedge WE_N)
     begin
	if (CE_N == 0)
          begin
             ram[ A ] = DI;
`ifdef debug
	     if (debug != 0)
	       $display("amem: W addr %o val %o; %t", A, DI, $time);
`endif
          end
     end

   assign DO = ram[ A ];

`ifdef debug
   always @(A or WE_N)
     begin
	if (debug != 0) $display("amem: R addr %o val %o, CE_N %d; %t",
				 A, ram[A], CE_N, $time);
     end
`endif

endmodule

