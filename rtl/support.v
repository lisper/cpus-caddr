//
// fpga support
// generate dcm_reset, reset & boot signals for cpu
//

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

   //
   reg [11:0] sys_slowcount;
   reg [5:0]  sys_medcount;
   reg [1:0]  cpu_slowcount;
   
   wire       sys_medevent;
   wire       sys_slowevent;
   wire       cpu_slowevent;
   
   reg [2:0]  reset_state;
   wire [2:0]  reset_state_next;

   parameter r_init = 0,
	       r_idle = 1,
	       r_reset1 = 2,
	       r_reset2 = 3,
	       r_wait = 4;

   reg [2:0]   cpu_state;
   wire [2:0]  cpu_state_next;

   parameter c_idle = 0,
	       c_reset1 = 1,
	       c_reset2 = 2,
	       c_reset3 = 3,
	       c_boot = 4,
   	       c_wait = 5;

   
   reg [9:0]  hold;
   wire       press_detected;
   wire       pressed;
   wire       released;
   reg 	      press_history;

   assign interrupt = 1'b0;
   assign halt = 1'b0;

   initial
     begin
	reset_state = 0;
	cpu_state = 0;
	sys_slowcount = 0;
	sys_medcount = 0;
	cpu_slowcount = 0;
	hold = 0;
	press_history = 0;
     end

   // debounce clock
   always @(posedge cpuclk or posedge dcm_reset)
     if (dcm_reset)
       cpu_slowcount <= 0;
     else
       cpu_slowcount = cpu_slowcount + 1;
   
   assign dcm_reset = reset_state == r_reset1;
   assign reset = cpu_state == c_reset1 || cpu_state == c_reset2 || cpu_state == c_reset3;
   assign boot = cpu_state == c_reset3 || cpu_state == c_boot;
   
   // cpu clk state machine
   assign cpu_state_next =
			  (cpu_state == c_idle && reset_state == r_reset2) ? c_reset1 :
			  (cpu_state == c_reset1) ? c_reset2 :
			  (cpu_state == c_reset2) ? c_reset3 :
			  (cpu_state == c_reset3) ? c_boot :
			  (cpu_state == c_boot) ? c_wait :
			  (cpu_state == c_wait && reset_state == r_idle) ? c_idle :
			  cpu_state;

   assign cpu_slowevent = cpu_slowcount == 2'b11;
   
   always @(posedge cpuclk)
     if (cpu_slowevent)
       cpu_state <= cpu_state_next;

   // main state machine
   assign reset_state_next =
			    (reset_state == r_init) ? r_reset1 :
			    (reset_state == r_idle && pressed) ? r_reset1 :
			    (reset_state == r_reset1) ? r_reset2 :
			    (reset_state == r_reset2 && cpu_state != c_idle) ? r_wait :
			    (reset_state == r_wait & ~pressed) ? r_idle :
			    reset_state;
			    
   always @(posedge sysclk)
     if (sys_medevent)
       reset_state <= reset_state_next;
   
   // dcm clock
   always @(posedge sysclk)
     begin
	sys_medcount <= sys_medcount + 1;
     end

   assign sys_medevent = sys_medcount == 6'b111111;
   
   // debounce clock
   always @(posedge sysclk)
     begin
	sys_slowcount <= sys_slowcount + 1;
     end

   assign sys_slowevent = sys_slowcount == 12'h0fff;
   
   // sample push button
   always @(posedge sysclk)
     if (sys_slowevent)
       hold <= { hold[8:0], button_r };

   assign press_detected = hold == 10'b1111111111;

   // generate button events
   always @(posedge sysclk)
     if (sys_slowevent)
       press_history <= press_detected;

   assign pressed = (!press_history && press_detected);
   assign released = (press_history && ~press_detected);
   
endmodule

