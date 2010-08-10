//

`ifdef xxxx

module support(sysclk, button, reset, interrupt, boot, halt);

   input sysclk;
   input button;

   output reset;
   output interrupt;
   output boot;
   output halt;

//   reg [14:0] count;
reg [24:0] count;
   reg 	     slowclk;
   reg 	     onetime;
   reg [9:0]  hold;
   wire       pressed;
   
//   assign reset = (count > 10 && count < 32000 && ~onetime) || pressed;
//   assign boot = count >= 30000 && ~onetime;
assign reset = (count > 10 && count < 25'h0ffffff && ~onetime) || pressed;
assign boot = count >= 25'h07fffff && ~onetime;
   assign interrupt = 1'b0;
   assign halt = 1'b0;

   assign pressed = hold == 10'b1111111111;

   initial
     begin
	onetime = 0;
	slowclk = 0;
	hold = 0;
     end
   
   always @(posedge sysclk)
     begin
	count <= count + 1;
	if (count == 0)
          slowclk <= ~slowclk;
	if (pressed)
	  count <= 0;
     end
   
   always @(posedge slowclk)
     begin
	hold <= { hold[8:0], button };
	onetime <= pressed ? 0 : 1;
     end
   
   
endmodule
`else // !`ifdef xxxx

module support(sysclk, cpuclk, button_r, button_b, 
	       reset, interrupt, boot, halt);

   input sysclk;
   input cpuclk;
   input button_r;
   input button_b;

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
   wire       pressed;
   
   assign reset = (cpu_count > 10 && cpu_count < 50 && ~onetime) || pressed;
   assign boot = (cpu_count >= 40 && ~onetime) || button_b;
   assign interrupt = 1'b0;
   assign halt = 1'b0;

   assign pressed = hold == 10'b1111111111;

   initial
     begin
	onetime = 0;
	sys_slowclk = 0;
	cpu_slowclk = 0;
	hold = 0;
	cpu_count = 0;
	sys_count = 0;
     end
   
   always @(posedge cpuclk or posedge pressed)
     if (pressed)
       cpu_count <= 0;
     else
       begin
	  cpu_count <= cpu_count + 1;

	  if (cpu_count == 0)
	    cpu_slowclk <= ~cpu_slowclk;
       end

   always @(posedge cpu_slowclk)
     onetime <= pressed ? 0 : 1;
   
   always @(posedge sysclk)
     begin
	if (pressed)
	  sys_count <= 0;
	else
	  sys_count <= sys_count + 1;

	if (sys_count == 0)
          sys_slowclk <= ~sys_slowclk;
     end
   
   always @(posedge sys_slowclk)
     hold <= { hold[8:0], button_r };
   
   
endmodule


`endif