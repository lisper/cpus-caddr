// ------------------

`timescale 1ns / 1ns

`define debug

`include "../rtl/scancode_rom.v"
`include "../rtl/scancode_convert.v"
`include "../rtl/ps2.v"
`include "../rtl/keyboard.v"


module test_keyboard;

   reg clk;
   reg reset;
   reg ps2_clk;
   reg ps2_data;
   wire [15:0] scancode;
   wire        strobe;
   
   keyboard keyboard(.clk(clk),
		     .reset(reset),
		     .ps2_clk(ps2_clk),
		     .ps2_data(ps2_data),
		     .data(scancode),
		     .strobe(strobe));

   task clockout;
      input bit;
      begin
	 ps2_data = bit;
	 ps2_clk = 0;
	 repeat (100) @(posedge clk);
	 ps2_clk = 1;
	 repeat (100) @(posedge clk);
      end
   endtask
   
   task sendscan;
      input [7:0] scan;
      begin
	 @(posedge clk);
	 clockout(0);
	 clockout(scan[0]);
	 clockout(scan[1]);
	 clockout(scan[2]);
	 clockout(scan[3]);
	 clockout(scan[4]);
	 clockout(scan[5]);
	 clockout(scan[6]);
	 clockout(scan[7]);
	 clockout(0);
	 clockout(1);
	 repeat (10000) @(posedge clk);
      end
   endtask

   task pause;
      begin
	 repeat(5000) @(posedge clk);
	 $display("----");
      end
   endtask

   task sender;
      begin
	 $display("begin test");
	 
	 #200 begin
            reset = 0;
	 end

	 #100000;

	 // press "a"
	 sendscan(8'h1c);
	 sendscan(8'hf0);
	 sendscan(8'h1c);
	 pause;
	 
	 // press "b"
	 sendscan(8'h32);
	 sendscan(8'hf0);
	 sendscan(8'h32);
	 pause;

	 // enter
	 sendscan(8'h5a);
	 sendscan(8'hf0);
	 sendscan(8'h5a);
	 pause;
	 
	 // shift "a"
	 sendscan(8'h12);

	 sendscan(8'h1c);
	 sendscan(8'hf0);
	 sendscan(8'h1c);

	 sendscan(8'hf0);
	 sendscan(8'h12);
	 pause;

	 // press "c"
	 sendscan(8'h21);
	 sendscan(8'hf0);
	 sendscan(8'h21);
	 pause;

	 // ctrl "a"
	 sendscan(8'h14);

	 sendscan(8'h1c);
	 sendscan(8'hf0);
	 sendscan(8'h1c);

	 sendscan(8'hf0);
	 sendscan(8'h14);
	 pause;

	 // press "d"
	 sendscan(8'h23);
	 sendscan(8'hf0);
	 sendscan(8'h23);
	 pause;

	 // press "end"
	 sendscan(8'he0);
	 sendscan(8'h69);

	 sendscan(8'he0);
	 sendscan(8'hf0);
	 sendscan(8'h69);
	 pause;

	 // press "escape"
	 sendscan(8'h76);

	 sendscan(8'hf0);
	 sendscan(8'h76);
	 pause;

	 $display("end test");
	 
	 #5000 $finish;
      end
   endtask
   
   task monitor;
      begin
	 $display("monitor start");
	 while (1)
	   begin
	      @(posedge clk);
	      if (strobe)
		begin
		   $display("out: 0x%x %o; ", scancode, scancode);
		end
	   end
	 $display("monitor end");
      end
   endtask

   initial
     begin
	$timeformat(-9, 0, "ns", 7);
	
	$dumpfile("test-keyboard.vcd");
	$dumpvars(0, test_keyboard);
     end

   initial
     begin
	clk = 0;
	reset = 1;
	ps2_clk = 1;
	ps2_data = 1;

	fork
	   monitor;
	   sender;
	join;
     end

   always
     begin
	#40 clk = 0;
	#40 clk = 1;
     end

endmodule

