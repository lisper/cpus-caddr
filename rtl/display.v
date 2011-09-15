// display.v
// display pc on led'and 4x7 segment digits

module display(clk, reset, pc, dots, sevenseg, sevenseg_an);
   
    input 	clk;
    input 	reset;
    input [13:0] pc;
    input [3:0]  dots;
    output [7:0] sevenseg;
    output [3:0] sevenseg_an;

   //
   wire [2:0] 	 digit;
   reg [1:0] 	 anode;

   reg [10:0]    divider;

   reg [13:0] 	 pc_reg;
   reg [3:0] 	 dots_reg;
   
   assign digit = (anode == 2'b11) ? pc_reg[11:9] :
		  (anode == 2'b10) ? pc_reg[8:6] :
		  (anode == 2'b01) ? pc_reg[5:3] :
		  (anode == 2'b00) ? pc_reg[2:0] :
		  3'b0;

   assign sevenseg_an = (anode == 2'b11) ? 4'b0111 :
			(anode == 2'b10) ? 4'b1011 :
			(anode == 2'b01) ? 4'b1101 :
			(anode == 2'b00) ? 4'b1110 :
			4'b1111;

   assign sevenseg[0] = ~dots_reg[anode];
   
   sevensegdecode decode({1'b0, digit}, sevenseg[7:1]);

   always @(posedge clk)
     if (reset)
       begin
	  pc_reg <= 0;
	  dots_reg <= 0;
       end
     else
       begin
	  pc_reg <= pc;
	  dots_reg <= dots;
       end
   
   always @(posedge clk)
     if (reset)
       divider <= 0;
     else
       divider <= divider + 11'b00000000001;

   // digit scan clock
   always @(posedge clk or posedge reset)
     if (reset)
       anode <= 0;
     else
       if (divider == 0)
	 anode <= anode + 1'b1;

endmodule
