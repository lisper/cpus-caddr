// debounce.v

module debounce(clk, in, out);
   input clk;
   input in;
   output out;

`ifdef sim_time
   reg [1:0] clkdiv;
`else
   reg [14:0] clkdiv;
`endif
   reg 	      slowclk;
   reg [9:0]  hold;
   reg 	      onetime;
   
   initial
     begin
	onetime = 0;
	hold = 0;
	clkdiv = 0;
	slowclk = 0;
     end
   
   assign out = hold == 10'b1111111111 || ~onetime;
		
   always @(posedge clk)
     begin
       clkdiv <= clkdiv + 15'b1;
       if (clkdiv == 0)
         slowclk <= ~slowclk;
     end

   always @(posedge slowclk)
     begin
	hold <= { hold[8:0], in };
	onetime <= 1;
     end
   
endmodule
