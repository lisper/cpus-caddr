/* 1kx24 asynchronous static ram */

module part_1kx24ram_async(A, DI, DO, CE_N, WE_N);

  input[9:0] A;
  input[23:0] DI;
  input CE_N, WE_N;
  output[23:0] DO;

  reg[23:0] ram [0:1023];

  integer i;

  initial
    begin
      for (i = 0; i < 1024; i=i+1)
        ram[i] = 24'b0;
    end

  always @(negedge WE_N)
    begin
      if (CE_N == 0 && WE_N == 0)
        begin
           ram[ A ] = DI;
	   $display("vmem1: W addr %o <- val %o (async); %t", A, DI, $time);
        end
    end

  assign DO = ram[ A ];

   always @(A or CE_N or WE_N)
     begin
	$display("vmem1: R addr %o -> val %o; %t", A, ram[ A ], $time);
     end

endmodule

module part_1kx24ram_sync(CLK, A, DI, DO, CE_N, WE_N);

   input CLK;
   input [9:0] A;
   input [23:0] DI;
   input CE_N, WE_N;
   output reg [23:0] DO;

   reg [23:0] ram [0:1023];

   integer i;

   initial
     begin
	for (i = 0; i < 1024; i=i+1)
          ram[i] = 24'b0;
     end

   always @(posedge CLK)
     if (~CE_N && ~WE_N)
       begin
          ram[ A ] <= DI;
	  $display("vmem1: W addr %o <- val %o (sync); %t ", A, DI, $time);
       end

   always @(posedge CLK)
     if (~CE_N)
       begin
	  DO <= ram[ A ];
       end

endmodule



