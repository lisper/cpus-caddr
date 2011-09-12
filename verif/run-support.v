`timescale 1ns / 1ns

`include "../rtl/support.v"

module test_support;

   reg sysclk;
   wire sysclk_buf;
   wire clk1x;
   reg [3:0] button;
   reg 	     locked;
   
   wire      reset;
   wire      interrupt;
   wire      boot;
   wire      halt;
   wire      dcm_reset;
      
   support support(.sysclk(sysclk_buf),
		   .cpuclk(clk1x),
		   .button_r(button[3]),
		   .button_b(button[2]),
		   .button_h(button[1]),
		   .button_c(button[0]),
		   .dcm_reset(dcm_reset),
		   .reset(reset),
		   .interrupt(interrupt),
		   .boot(boot),
		   .halt(halt));
   

   reg [2:0] slow;

   always @(posedge sysclk)
       slow <= slow + 1;
   
   assign sysclk_buf = sysclk;
   assign clk1x = slow[0] & locked;

   initial
     begin
	$timeformat(-9, 0, "ns", 7);
	$dumpfile("run-support.vcd");
	$dumpvars(0, test_support);
     end

   always @(posedge sysclk)
     begin
	if (dcm_reset)
	  locked = 0;
	else
	  if (~dcm_reset)
	    #20 locked = 1;
     end

   initial
     begin
	slow = 0;
	sysclk = 0;
	button = 4'b0000;
	locked = 0;

	#5000 button = 4'b1000;
//#5000; $finish;
	
 	#40000000 button = 4'b0000;
	#4000000; button = 4'b1000;
	#40000000 button = 4'b0000;
	
	#40000000 $finish;
     end
   
   always
     begin
	#10 sysclk = 0;
	#10 sysclk = 1;
     end

endmodule
