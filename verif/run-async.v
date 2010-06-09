/*
 */

`include "rtl-async.v"

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
//      #20000 $stop;
    end

  // 50mhz clock
  always
    begin
      #10 clk = 0;
      #10 clk = 1;
    end

   always @(posedge cpu.CLK)
     begin
	$display("%t pc %o", $time, cpu.pc);

	$display("     PC=%o NPC=%o OPC=%o PCS %b%b IR=%o",
		 cpu.pc, cpu.npc, cpu.opc, cpu.pcs1, cpu.pcs0, cpu.ir);
	$display("     A=%x M=%x, N=%x, Q=%x", cpu.a, cpu.m, cpu.n, cpu.q);
	$display("     mwp_n=%x madr=%o awp_n=%x aadr=%o",
		 cpu.mwp_n, cpu.madr, cpu.awp_n, cpu.aadr);
	$display("     nop=%x inop=%x", cpu.nop, cpu.inop);
	$display("     dest=%x ir[25]=%x", cpu.dest, cpu.ir[25]);
	

	$display("     iwrite=%x, iwrited=%x, destm=%x, destmd=%x",
		 cpu.iwrite, cpu.iwrited, cpu.destm, cpu.destmd);
	$display("     trap=%x dispenb=%x dn=%x jfalse=%x jcond=%b, popj=%b",
		 cpu.trap, cpu.dispenb, cpu.dn,
		 cpu.jfalse, cpu.jcond, cpu.popj);

	$display("     iralu=%x irjump=%x irdisp=%x irbyte_n=%x",
		 ~cpu.iralu_n, ~cpu.irjump_n, ~cpu.irdisp_n, ~cpu.irbyte_n);
     end 


endmodule
