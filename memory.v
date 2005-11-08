/*
 * $Id$
 */

/* 1kx32 static ram */

module part_1kx32ram(A, DI, DO,	CE_N, WE_N);

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
//$display("amem: %t addr %o val 0x%x, CE_N %d", $time, A, ram[ A ], CE_N);
        end
    end

  assign DO = ram[ A ];

//  always @(A)
//    begin
//      $display("amem: %t addr %o val 0x%x, CE_N %d", $time, A, ram[ A ], CE_N);
//    end

endmodule

/* 2kx5 static ram */

module part_2kx5ram(A, DI, DO, CE_N, WE_N);

  input[10:0] A;
  input[4:0] DI;
  input CE_N, WE_N;
  output[4:0] DO;

  reg[4:0] ram [0:2047];

  integer i;

  initial
    begin
      for (i = 0; i < 2048; i=i+1)
        ram[i] = 5'b0;
    end

  always @(posedge WE_N)
    begin
      if (CE_N == 0)
        begin
          ram[ A ] = DI;
$display("vmem0: %t addr %x <- val 0x%x", $time, A, ram[ A ]);
        end
    end

  assign DO = ram[ A ];

endmodule

/* 1kx24 static ram */

module part_1kx24ram(A, DI, DO,	CE_N, WE_N);

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

  always @(posedge WE_N)
    begin
      if (CE_N == 0)
        begin
          ram[ A ] = DI;
$display("vmem1: %t addr %x <- val 0x%x", $time, A, ram[ A ]);
        end
    end

  assign DO = ram[ A ];

always @(A)
  begin
    $display("vmem1: %t addr %x -> val 0x%x", $time, A, ram[ A ]);
  end

endmodule



/* 2kx17 static ram */

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

//  assign DO = ram[ A ];
assign DO = (^A === 1'bX || A === 1'bz) ? 17'b0 : ram[A];

endmodule

/* 32x32 static ram */

module part_32x32ram(A, DI, DO, WCLK_N, CE, WE_N);

  input[4:0] A;
  input[31:0] DI;
  input WE_N, WCLK_N, CE;
  output[31:0] DO;

  reg[31:0] ram [0:31];

  integer index;

  initial
    begin
      for (index = 0; index < 32; index=index+1)
        ram[index] = 32'b0;
    end

  always @(posedge WCLK_N)
    if (CE == 1 && WE_N == 0)
     begin
       ram[ A ] = DI;
//$display("mmem: %t addr %o val 0x%x, CE %d", $time, A, ram[ A ], CE);
     end

  assign DO = ram[ A ];

endmodule

/* 32x19 static ram */

module part_32x19ram(A, DI, DO, WCLK_N, WE_N, CE);

  input[4:0] A;
  input[18:0] DI;
  input WE_N, WCLK_N, CE;
  output[18:0] DO;

  reg[18:0] ram [0:31];

  initial
    begin
      ram[ 5'b00000 ] = 19'b0;
      ram[ 5'b11111 ] = 19'b0;
    end

  always @(posedge WCLK_N)
    if (CE == 1 && WE_N == 0)
       ram[ A ] = DI;

  assign DO = ram[ A ];

endmodule

/* 16k49 sram */

module part_16kx49ram(A, DI, DO, CE_N, WE_N);

  input[13:0] A;
  input[48:0] DI;
  input CE_N, WE_N;
  output[48:0] DO;

  reg[48:0] ram [0:16383];

  integer i;
  initial
    begin
      for (i = 0; i < 16384; i=i+1)
        ram[i] = 49'b0;
    end

  always @(posedge WE_N)
    begin
      if (CE_N == 0)
          ram[ A ] = DI;
    end

  assign DO = ram[ A ];

//always @(A)
//  begin
//    $display("iram: %t addr %o val 0x%x, CE_N %d", $time, A, ram[ A ], CE_N);
//  end

endmodule

