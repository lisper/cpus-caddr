//
// fpga support
// generate dcm_reset, reset & boot signals for cpu
//

module support(sysclk, cpuclk, button_r, button_b, 
	       dcm_reset, reset, interrupt, boot, halt);

   input sysclk;
   input cpuclk;
   input button_r;
   input button_b;

   output dcm_reset;
   output reset;
   output interrupt;
   output boot;
   output halt;

   //
   reg [14:0] sys_count;
   reg [5:0]  cpu_count;
   reg 	      sys_slowclk;
   reg 	      cpu_slowclk;
   reg 	      onetime;
   reg [9:0]  hold;
   wire       press;
   wire       pressed;
   wire       released;
   reg 	      press_history;
   
   assign dcm_reset = sys_count < 10 && ~onetime;

   assign reset = (cpu_count > 10 && cpu_count < 50) && ~onetime;
   assign boot = (cpu_count >= 40) && ~onetime;

   assign interrupt = 1'b0;
   assign halt = 1'b0;

   assign press = hold == 10'b1111111111;

   initial
     begin
	onetime = 0;
	sys_slowclk = 0;
	cpu_slowclk = 0;
	hold = 0;
	cpu_count = 0;
	sys_count = 0;
	press_history = 0;
     end

   // debounce clock
   always @(posedge cpuclk)
     begin
	cpu_count <= cpu_count + 1;
	
	if (cpu_count == 6'b111111)
	  cpu_slowclk <= ~cpu_slowclk;
     end

   // re-arm reset trigger
   always @(posedge cpu_slowclk)
     onetime <= /*released*/pressed ? 0 : 1;

   // clock divider
   always @(posedge sysclk)
     begin
	sys_count <= sys_count + 1;

	if (sys_count == 0)
          sys_slowclk <= ~sys_slowclk;
     end

   // sample push button
   always @(posedge sys_slowclk)
     hold <= { hold[8:0], button_r };

   // generate button events
   always @(posedge cpu_slowclk)
     press_history <= press;

   assign pressed = (!press_history && press);
   assign released = (press_history && ~press);
   
   
endmodule

