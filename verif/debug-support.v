module support(sysclk, cpuclk, button_r, button_b, button_h, button_c,
	       dcm_reset, reset, interrupt, boot, halt);

   input sysclk;
   input cpuclk;
   input button_r;
   input button_b;
   input button_h;
   input button_c;

   output dcm_reset;
   output reset;
   output interrupt;
   output boot;
   output halt;

   reg 	  reset;
   
   assign dcm_reset = 0;
   assign interrupt = 0;
   assign boot = 0;
   assign halt = 0;

   initial
     begin
	reset = 0;
	
	#5 reset = 1;
	#100 reset = 0;
     end
   
endmodule
