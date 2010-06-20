/* 2kx5 static ram */

module part_2kx5ram_async(A, DI, DO, CE_N, WE_N);

  input[10:0] A;
  input[4:0] DI;
  input CE_N, WE_N;
  output[4:0] DO;

  reg[4:0] ram [0:2047];

`ifdef debug
  integer i;

  initial
    begin
      for (i = 0; i < 2048; i=i+1)
        ram[i] = 5'b0;
    end
`endif

  always @(negedge WE_N)
    begin
      if (CE_N == 0 && WE_N == 0)
        begin
          ram[ A ] = DI;
`ifdef debug
	   $display("vmem0: W addr %o <- val %o; %t", A, DI, $time);
`endif
        end
    end

  assign DO = ram[ A ];

endmodule

module part_2kx5ram_sync(CLK, A, DI, DO, CE_N, WE_N);

  input CLK;
  input [10:0] A;
  input [4:0] DI;
  input CE_N, WE_N;
  output reg [4:0] DO;

  reg[4:0] ram [0:2047];

  integer i;

  initial
    begin
      for (i = 0; i < 2048; i=i+1)
        ram[i] = 5'b0;
    end

   always @(posedge CLK)
     if (~CE_N && ~WE_N)
        begin
          ram[ A ] = DI;
	   $display("vmem0: W addr %o <- val %o; %t", A, DI, $time);
        end

   always @(posedge CLK)
     if (~CE_N)
       begin
	  DO <= ram[ A ];
       end

endmodule

