`include "caddr.v"

`timescale 1ns / 1ns

module test;
  reg clk;
  reg power_reset_n;
  reg int;

  // controlled by rc circuit at power up
  reg boot1_n, boot2_n;

  wire[15:0] spy;
  wire dbread_n, dbwrite_n;
  wire[3:0] eadr;

  caddr cpu (clk, int, power_reset_n, boot1_n, boot2_n,
	     spy, dbread_n, dbwrite_n, eadr);

  integer addr;

  assign eadr = 4'b0;
  assign dbread_n = 1;
  assign dbwrite_n = 1;

  initial
    begin
      $timeformat(-9, 0, "ns", 7);

      $dumpfile("caddr.vcd");
      $dumpvars(0, test.cpu);
    end

//  initial
//    #0 begin
//	$readmemh("../prom/cadr_prom.hex", cpu.i_PROM0.prom);
//    end

  initial
    begin
      clk = 0;
      int = 0;
      power_reset_n = 1;

      #1 begin
	   power_reset_n = 0;
	   boot1_n = 0;
	   boot2_n = 0;

//`include "rompatch.v"
         end

      #10 begin
            boot1_n = 1;
            boot2_n = 1;
          end

      #250 power_reset_n = 1;

      #5 begin
            boot1_n = 0;
            boot2_n = 0;
          end

      #5 begin
            boot1_n = 1;
            boot2_n = 1;
          end

      #10000 $finish;
    end

  // 50mhz clock
  always
    begin
      #10 clk = 0;
      #10 clk = 1;
    end

endmodule
