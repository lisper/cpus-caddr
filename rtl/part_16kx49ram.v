/* 16k49 sram */

module part_16kx49ram(A, DI, DO, CE_N, WE_N);

  input[13:0] A;
  input[48:0] DI;
  input CE_N, WE_N;
  output[48:0] DO;

//`define no_iram

`ifdef no_iram
   parameter IRAM_SIZE = 2;
`else
   parameter IRAM_SIZE = 16384;
`endif

  reg[48:0] ram [0:IRAM_SIZE-1];

`ifdef debug
  integer i;
  initial
    begin
      for (i = 0; i < 16384; i=i+1)
        ram[i] = 49'b0;
    end
`endif
  
  always @(posedge WE_N)
    begin
      if (CE_N == 0)
	begin
`ifdef debug
	   // patch out disk-copy (which takes 12 hours to sim)
	   if (A == 14'o24045)
	     ram[ A ] = 49'h000000001000;
	   else
`endif
           ram[ A ] = DI;
	   $display("iram: W addr %o val %o; %t", A, DI, $time);
	end
    end

  assign DO = ram[ A ];

`ifdef debug_iram
   always @(A)
     begin
	$display("iram: %t addr %o val 0x%x, CE_N %d",
		 $time, A, ram[ A ], CE_N);
     end
`endif

endmodule

