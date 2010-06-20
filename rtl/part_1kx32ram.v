/* 1kx32 asynchronous static ram */

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

module part_1kx32ram_sync_p(CLK, A, DI, DO, CE_N, WE_N);

  input CLK;
  input [9:0] A;
  input [31:0] DI;
  input CE_N, WE_N;
  output reg [31:0] DO;

  reg[31:0] ram [0:1023];

  integer i;

  initial
    begin
      for (i = 0; i < 1024; i=i+1)
        ram[i] = 32'b0;
    end

   always @(posedge CLK)
     if (~CE_N && ~WE_N)
        begin
           ram[ A ] = DI;
	   $display("pdl: W addr %o val %o; %t", A, DI, $time);
        end

   always @(posedge CLK)
     if (~CE_N)
       begin
	  DO <= ram[ A ];
//	  if (A != 0)
//	  $display("pdl: R %t addr %o val %o", $time, A, ram[A]);
       end

endmodule

