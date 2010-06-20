/* 2kx17 asynchronous static ram */

module part_2kx17ram(A, DI, DO,	CE_N, WE_N);

  input[10:0] A;
  input[16:0] DI;
  input CE_N, WE_N;
  output[16:0] DO;

  reg[16:0] ram [0:2047];

  integer i;

  initial
    begin
      for (i = 0; i < 2048; i=i+1)
        ram[i] = 17'b0;
    end

  always @(posedge WE_N)
    begin
      if (CE_N == 0)
          ram[ A ] = DI;
    end

   assign DO = ram[ A ];
   //assign DO = (^A === 1'bX || A === 1'bz) ? 17'b0 : ram[A];

endmodule

