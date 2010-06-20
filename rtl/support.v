
module support(sysclk, clk, reset, interrupt, boot, halt);

   input sysclk;
   output clk;
   output reset;
   output interrupt;
   output boot;
   output halt;

   reg [7:0] count;
   reg 	     slowclk;
   reg 	     onetime;
   
   assign clk = sysclk;
   assign reset = count > 10 && ~onetime;
   assign boot = count >= 240 && count < 250 && ~onetime;
   assign interrupt = 1'b0;
   assign halt = 1'b0;
   
   initial
     begin
	onetime = 0;
	slowclk = 0;
     end
   
   always @(posedge clk)
     begin
	count <= count + 1;
	if (count == 255)
          slowclk <= ~slowclk;
     end
   
   always @(posedge slowclk)
     begin
	onetime <= 1;
     end
   
endmodule

   
   
