// ------------------

`timescale 1ns / 1ns

`define debug
`include "../rtl/scancode_rom.v"
`include "../rtl/scancode_convert.v"

module test;

   reg clk, reset;
   reg [7:0] 	  testcode;
   reg 		  strobe_in;
   
   wire 	  strobe_out;
   wire [7:0] 	  keycode;

   scancode_convert scancode_convert(.clk(clk),
				     .reset(reset),
				     .strobe_in(strobe_in),
				     .code_in(testcode),
				     .strobe_out(strobe_out),
				     .keycode(keycode));
   
   initial
     begin
	$timeformat(-9, 0, "ns", 7);
	
	$dumpfile("test-scancode_convert.vcd");
	$dumpvars(0, test.scancode_convert);
     end

   task sendscan;
      input [7:0] scan;
      begin
	 @(posedge clk);
	 strobe_in = 1;
	 testcode = scan;
	 @(posedge clk);
	 strobe_in = 0;
	 repeat (100) @(posedge clk);
      end
   endtask

   task pause;
      begin
	 repeat(500) @(posedge clk);
	 $display("----");
      end
   endtask

   task monitor;
      begin
	 $display("monitor start");
	 while (1)
	   begin
	      @(posedge clk);
	      if (strobe_in)
		begin
		   $display("in: 0x%x %o", testcode, testcode);
		end
	      if (strobe_out)
		begin
		   $display("out: 0x%x %o; ", keycode, keycode);
		end
	   end
	 $display("monitor end");
      end
   endtask
      
   task sender;
      begin
	 $display("begin test");
	 
	 #200 begin
            reset = 0;
	 end

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

	 $display("end test");
	 
	 #5000 $finish;
      end
   endtask
   
   initial
     begin
	clk = 0;
	reset = 1;
	strobe_in = 0;

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
