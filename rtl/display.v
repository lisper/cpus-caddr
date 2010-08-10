// display.v
// display pc on led'and 4x7 segment digits

module display(clk, reset, pc, dots, sevenseg, sevenseg_an);
   
    input 	clk;
    input 	reset;
    input [15:0] pc;
    input [3:0]  dots;
    output [7:0] sevenseg;
    output [3:0] sevenseg_an;

   //
   wire [2:0] 	 digit;
   reg [1:0] 	 anode;

   reg [10:0]    divider;
   reg           aclk;
   
   assign digit = (anode == 2'b11) ? pc[11:9] :
		  (anode == 2'b10) ? pc[8:6] :
		  (anode == 2'b01) ? pc[5:3] :
		  (anode == 2'b00) ? pc[2:0] :
		  3'b0;

   assign sevenseg_an = (anode == 2'b11) ? 4'b0111 :
			(anode == 2'b10) ? 4'b1011 :
			(anode == 2'b01) ? 4'b1101 :
			(anode == 2'b00) ? 4'b1110 :
			4'b1111;

   assign sevenseg[0] = ~dots[anode];
   
   sevensegdecode decode({1'b0, digit}, sevenseg[7:1]);

   always @(posedge clk)
     begin
       divider <= divider + 11'b1;
       if (divider == 0)
          aclk = ~aclk;
     end

   // digit scan clock
   always @(posedge aclk)
       anode <= anode + 1'b1;

endmodule
