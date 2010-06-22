/* 1kx24 asynchronous static ram */

module part_1kx24ram_async(A, DI, DO, CE_N, WE_N);

  input[9:0] A;
  input[23:0] DI;
  input CE_N, WE_N;
  output[23:0] DO;

  reg[23:0] ram [0:1023];

`ifdef debug
  integer i, debug;

  initial
    begin
       debug = 0;
       for (i = 0; i < 1024; i=i+1)
         ram[i] = 24'b0;
    end
`endif

  always @(negedge WE_N)
    begin
      if (CE_N == 0 && WE_N == 0)
        begin
           ram[ A ] = DI;
`ifdef debug
	   if (debug != 0)
	     $display("vmem1: W addr %o <- val %o (async); %t", A, DI, $time);
`endif
        end
    end

  assign DO = ram[ A ];

   always @(A or CE_N or WE_N)
     begin
`ifdef debug
	if (debug != 0)
	  $display("vmem1: R addr %o -> val %o; %t", A, ram[ A ], $time);
`endif
     end

endmodule

module part_1kx24ram_sync(CLK, A, DI, DO, CE_N, WE_N);

   input CLK;
   input [9:0] A;
   input [23:0] DI;
   input CE_N, WE_N;
   output reg [23:0] DO;

   reg [23:0] ram [0:1023];

`ifdef debug
   integer i, debug;

   initial
     begin
	debug = 0;
	for (i = 0; i < 1024; i=i+1)
          ram[i] = 24'b0;
     end
`endif
   
   always @(posedge CLK)
     if (~CE_N && ~WE_N)
       begin
          ram[ A ] <= DI;
`ifdef debug
	  if (debug)
	    $display("vmem1: W addr %o <- val %o (sync); %t ", A, DI, $time);
`endif
       end

   always @(posedge CLK)
     if (~CE_N)
       begin
	  DO <= ram[ A ];
       end

endmodule



