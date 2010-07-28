
module support(sysclk, button, clk, reset, interrupt, boot, halt);

   input sysclk;
   input button;

   output clk;
   output reset;
   output interrupt;
   output boot;
   output halt;

   reg [7:0] count;
   reg 	     slowclk;
   reg 	     onetime;
   reg [9:0]  hold;
   wire       pressed;
   
   assign clk = sysclk;
   assign reset = (count > 10 && ~onetime) || pressed;
   assign boot = count >= 240 && count < 250 && ~onetime;
   assign interrupt = 1'b0;
   assign halt = 1'b0;

   assign pressed = hold == 10'b1111111111;

   initial
     begin
	onetime = 0;
	slowclk = 0;
	hold = 0;
     end
   
   always @(posedge clk)
     begin
	count <= count + 1;
	if (count == 255)
          slowclk <= ~slowclk;
	if (pressed)
	  count <= 0;
     end
   
   always @(posedge slowclk)
     begin
	hold <= { hold[8:0], in };
	onetime <= pressed ? 0 : 1;
     end
   
   
endmodule

   
   
