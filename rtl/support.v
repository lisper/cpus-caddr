//
// fpga support
// generate dcm_reset, lpddr_reset, reset & boot signals for cpu
//

module support(sysclk, cpuclk, button_r, button_b, button_h, button_c,
	       lpddr_reset, lpddr_calib_done,
	       dcm_reset, reset, interrupt, boot, halt);

   input sysclk;
   input cpuclk;
   input button_r;
   input button_b;
   input button_h;
   input button_c;
   input lpddr_calib_done;
  
   output lpddr_reset;
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

   parameter r_init = 3'd0,	// power-on	    dcm-reset lpddr-reset cpu-reset
	       r_reset1 = 3'd1,	// reset-pushed	              lpddr-reset cpu-reset
	       r_reset2 = 3'd2,	// 		                          cpu-reset
	       r_reset3 = 3'd3,	// lpddr-calib-wait                       cpu-reset
	       r_reset4 = 3'd4,	// cpu-wait
     	       r_reset5 = 3'd5,	// (unused)
	       r_wait   = 3'd6,	// reset-released
	       r_idle   = 3'd7;	// system-up, idle
   

   reg [2:0]   cpu_state;
   wire [2:0]  cpu_state_next;

   parameter c_init = 3'd0,        // power-on
	       c_reset1 = 3'd1,	//                cpu-reset
	       c_reset2 = 3'd2,	//                cpu-reset
	       c_reset3 = 3'd3,	//                cpu-reset boot
	       c_boot   = 3'd4,	//                          boot
   	       c_wait   = 3'd5,	// wait-for-reset-idle
               c_idle   = 3'd6;	// cpu-running, idle
   
   reg [9:0]  hold;
   wire       press_detected;
   wire       pressed;
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
       cpu_slowcount <= cpu_slowcount + 2'd1;

   // wait n clocks before asserting lpddr reset
   wire lpddr_reset_holdoff;
   reg [3:0] lpddr_reset_holdoff_cnt;

   initial
     lpddr_reset_holdoff_cnt = 0;

   always @(posedge sysclk)
     if (lpddr_reset_holdoff_cnt != 4'd4)
       lpddr_reset_holdoff_cnt <= lpddr_reset_holdoff_cnt + 4'd1;
   
   assign lpddr_reset_holdoff = lpddr_reset_holdoff_cnt != 4'd4;

   // sequence resets... dcm, lpddr, reset, boot
   wire cpu_in_reset;

   assign cpu_in_reset = (reset_state == r_init ||
			  reset_state == r_reset1 ||
			  reset_state == r_reset2 ||
			  reset_state == r_reset3) ||
			 (cpu_state == c_init ||
			  cpu_state == c_reset1 ||
			  cpu_state == c_reset2 ||
			  cpu_state == c_reset3);
   
   
   assign dcm_reset = reset_state == r_init/* || reset_state == r_reset1*/;
   assign lpddr_reset = (reset_state == r_init || reset_state == r_reset1) &&
			~lpddr_reset_holdoff ? 1'b1 : 1'b0;
   assign reset = cpu_in_reset;
   assign boot = cpu_state == c_reset3 || cpu_state == c_boot;
   
   // cpu reset state machine
   assign cpu_state_next =
			  (cpu_state == c_init && reset_state == r_reset4) ? c_reset1 :
			  (cpu_state == c_reset1) ? c_reset2 :
			  (cpu_state == c_reset2) ? c_reset3 :
			  (cpu_state == c_reset3) ? c_boot :
			  (cpu_state == c_boot) ? c_wait :
			  (cpu_state == c_wait && reset_state == r_idle) ? c_idle :
			  (cpu_state == c_idle && reset_state == r_reset4) ? c_reset1 :
			  cpu_state;

   assign cpu_slowevent = cpu_slowcount == 2'b11;
   
   always @(posedge cpuclk)
     if (cpu_slowevent)
       begin
	  cpu_state <= cpu_state_next;
`ifdef debug
	  if (cpu_state != cpu_state_next)
	    $display("cpu_state %d", cpu_state_next);
`endif
       end

   // infrastructure reset state machine
   assign reset_state_next =
			    (reset_state == r_init) ? r_reset1 :
			    (reset_state == r_reset1) ? r_reset2 :
			    (reset_state == r_reset2) ? r_reset3 :
			    (reset_state == r_reset3 && lpddr_calib_done) ? r_reset4 :
			    (reset_state == r_reset4 && cpu_state != c_idle) ? r_wait :
			    (reset_state == r_wait & ~pressed) ? r_idle :
			    (reset_state == r_idle && pressed) ? r_reset1 :
			    reset_state;
			    
   always @(posedge sysclk)
     if (sys_medevent)
       begin
	  reset_state <= reset_state_next;
`ifdef debug
	  if (reset_state != reset_state_next)
	    $display("reset_state %d", reset_state_next);
`endif
       end
   
   // dcm clock
   always @(posedge sysclk)
     begin
	sys_medcount <= sys_medcount + 6'd1;
     end

   assign sys_medevent = sys_medcount == 6'b111111;
   
   // debounce clock
   always @(posedge sysclk)
     begin
	sys_slowcount <= sys_slowcount + 12'd1;
     end

   assign sys_slowevent = sys_slowcount == 12'hfff;
   
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
   //assign released = (press_history && ~press_detected);

endmodule

