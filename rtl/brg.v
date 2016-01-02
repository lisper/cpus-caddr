// brg.v
// baud rate generator for uart

//`define test_output

module brg(clk, reset, tx_baud_clk, rx_baud_clk);

   input clk;
   input reset;
   output tx_baud_clk;
   output rx_baud_clk;

   parameter SYS_CLK = 26'd50000000;
   parameter BAUD = 16'd9600;

`ifdef sim_time
   parameter RX_CLK_DIV = 2;
   parameter TX_CLK_DIV = 2;
`else
   parameter RX_CLK_DIV = SYS_CLK / (BAUD * 16 * 2);
   parameter TX_CLK_DIV = SYS_CLK / (BAUD * 2);
`endif
   
   reg [12:0] rx_clk_div;
   reg [12:0] tx_clk_div;
   reg 		tx_baud_clk;
   reg 		rx_baud_clk;


   wire [31:0] 	rx_clk_div_max;
   assign 	rx_clk_div_max = RX_CLK_DIV;

   wire [31:0] 	tx_clk_div_max;
   assign 	tx_clk_div_max = TX_CLK_DIV;
   
   always @(posedge clk or posedge reset)
     if (reset)
       begin
	  rx_clk_div  <= 0;
	  rx_baud_clk <= 0; 
       end
     else 
       if (rx_clk_div == rx_clk_div_max[12:0])
	 begin
	    rx_clk_div  <= 0;
	    rx_baud_clk <= ~rx_baud_clk;
	 end
       else
	 begin
	    rx_clk_div  <= rx_clk_div + 13'b1;
	    rx_baud_clk <= rx_baud_clk;
	 end

   always @(posedge clk or posedge reset)
     if (reset)
       begin
	  tx_clk_div  <= 0;
	  tx_baud_clk <= 0; 
       end
     else 
       if (tx_clk_div == tx_clk_div_max[12:0])
	 begin
	    tx_clk_div  <= 0;
	    tx_baud_clk <= ~tx_baud_clk;
	 end
       else
	 begin
	    tx_clk_div  <= tx_clk_div + 13'b1;
	    tx_baud_clk <= tx_baud_clk;
	 end
   
endmodule

