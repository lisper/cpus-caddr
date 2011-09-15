// 
// serial port spy support
//

// brg.v
// baud rate generator for uart

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


`ifndef fake_uart
// uart.v
// simple low speed async uart for RS-232
// brad@heeltoe.com 2009

module uart(clk, reset,
	    txclk, ld_tx_req, ld_tx_ack, tx_data, tx_enable, tx_out, tx_empty,
	    rxclk, uld_rx_req, uld_rx_ack, rx_data, rx_enable, rx_in, rx_empty);
   
   input        clk;
   input        reset;
   input        txclk;
   input        ld_tx_req;
   output 	ld_tx_ack;
   input [7:0] 	tx_data;
   input        tx_enable;
   output       tx_out;
   output       tx_empty;
   input        rxclk;
   input        uld_rx_req;
   output 	uld_rx_ack;
   output [7:0] rx_data;
   input        rx_enable;
   input        rx_in;
   output       rx_empty;

   reg [7:0] 	tx_reg;
   reg          tx_empty;
   reg          tx_over_run;
   reg [3:0] 	tx_cnt;
   reg          tx_out;
   reg [7:0] 	rx_reg;
   reg [7:0] 	rx_data;
   reg [3:0] 	rx_sample_cnt;
   reg [3:0] 	rx_cnt;  
   reg          rx_frame_err;
   reg          rx_over_run;
   reg          rx_empty;
   reg          rx_d1;
   reg          rx_d2;
   reg          rx_busy;

   //
   reg [1:0]	rx_uld;
   wire [1:0] 	rx_uld_next;
   wire 	uld_rx_data;
   
   reg [1:0]	tx_ld;
   wire [1:0] 	tx_ld_next;
   wire 	ld_tx_data;

   // require uld_rx_req to deassert before sending next char
   always @(posedge rxclk or posedge reset)
     if (reset)
       rx_uld <= 2'b00;
     else
       rx_uld <= rx_uld_next;

   assign rx_uld_next =
		      (rx_uld == 0 && uld_rx_req) ? 1 :
		      (rx_uld == 1 && ~uld_rx_req) ? 0 :
		      (rx_uld == 1 && uld_rx_req) ? 2 :
		      (rx_uld == 2 && ~uld_rx_req) ? 0 :
		       rx_uld;

   assign uld_rx_ack = (rx_uld == 1) || (rx_uld == 2);
   assign uld_rx_data = (rx_uld == 1);
   
   // require tx_ld_req to deassert before accepting next char
   always @(posedge txclk or posedge reset)
     if (reset)
       tx_ld <= 2'b00;
     else
       tx_ld <= tx_ld_next;

   assign tx_ld_next =
		      (tx_ld == 0 && ld_tx_req) ? 1 :
		      (tx_ld == 1 && ~ld_tx_req) ? 0 : /* only load once */
		      (tx_ld == 1 && ld_tx_req) ? 2 :
		      (tx_ld == 2 && ~ld_tx_req) ? 0 :
		      tx_ld;

   assign ld_tx_ack = (tx_ld == 1) || (tx_ld == 2);
   assign ld_tx_data = (tx_ld == 1);
   
   
   // uart rx
   always @(posedge rxclk or posedge reset)
     if (reset)
       begin
	  rx_reg <= 0; 
	  rx_data <= 0;
	  rx_sample_cnt <= 0;
	  rx_cnt <= 0;
	  rx_frame_err <= 0;
	  rx_over_run <= 0;
	  rx_empty <= 1;
	  rx_d1 <= 1;
	  rx_d2 <= 1;
	  rx_busy <= 0;
       end
     else
       begin
	  // synchronize the asynch signal
	  rx_d1 <= rx_in;
	  rx_d2 <= rx_d1;

	  // uload the rx data
	  if (uld_rx_data && ~rx_empty)
	    begin
	       rx_data <= rx_reg;
	       rx_empty <= 1;
	  end

	  // receive data only when rx is enabled
	  if (rx_enable)
	    begin
	       // check if just received start of frame
	       if (!rx_busy && !rx_d2)
		 begin
		    rx_busy <= 1;
		    rx_sample_cnt <= 1;
		    rx_cnt <= 0;
		 end
	       
	       // start of frame detected
	       if (rx_busy)
		 begin
		    rx_sample_cnt <= rx_sample_cnt + 4'd1;
		    
		    // sample at middle of data
		    if (rx_sample_cnt == 7)
		      begin
			 if ((rx_d2 == 1) && (rx_cnt == 0))
			   rx_busy <= 0;
			 else
			   begin
			      rx_cnt <= rx_cnt + 4'd1; 

			      // start storing the rx data
			      if (rx_cnt > 0 && rx_cnt < 9)
				   rx_reg[rx_cnt - 1] <= rx_d2;

			      if (rx_cnt == 4'd9)
				begin
				   //$display("rx_cnt %d, rx_reg %o",
				   //  rx_cnt, rx_reg);
				   
				   rx_busy <= 0;

				   // check if end of frame received correctly
				   if (rx_d2 == 0)
				     rx_frame_err <= 1;
				   else
				     begin
					rx_empty <= 0;
					rx_frame_err <= 0;

					// check for overrun
					rx_over_run <= (rx_empty) ?
							 1'b0 : 1'b1;
				     end
				end
			   end
		      end 
		 end 
	    end

	  if (!rx_enable)
	    rx_busy <= 0;
       end

    // uart tx
    always @ (posedge txclk or posedge reset)
      if (reset)
	begin
	   tx_empty <= 1'b1;
	   tx_out <= 1'b1;
	   tx_cnt <= 4'b0;

	   tx_reg <= 0;
	   tx_over_run <= 0;
	end
      else
	begin
   	   if (ld_tx_data)
	     begin
		if (!tx_empty)
		  tx_over_run <= 1;
		else
		  begin
		     tx_reg <= tx_data;
		     tx_empty <= 0;
		  end
	     end

	  if (tx_enable && !tx_empty)
	    begin
	       tx_cnt <= tx_cnt + 4'b1;

	       case (tx_cnt)
		 4'd0: tx_out <= 0;
		 4'd1: tx_out <= tx_reg[0];
		 4'd2: tx_out <= tx_reg[1];
		 4'd3: tx_out <= tx_reg[2];
		 4'd4: tx_out <= tx_reg[3];
		 4'd5: tx_out <= tx_reg[4];
		 4'd6: tx_out <= tx_reg[5];
		 4'd7: tx_out <= tx_reg[6];
		 4'd8: tx_out <= tx_reg[7];
		 4'd9: tx_out <= 1;
		 4'd10:
		   begin
		      tx_cnt <= 0;
		      tx_empty <= 1;
		   end
		 default: tx_out <= 0;
	       endcase
	    end

	  if (!tx_enable)
	    tx_cnt <= 0;
	end
   
endmodule

`else // !`ifndef fake_uart

module uart(clk, reset,
	    txclk, ld_tx_req, ld_tx_ack, tx_data, tx_enable, tx_out, tx_empty,
	    rxclk, uld_rx_req, uld_rx_ack, rx_data, rx_enable, rx_in, rx_empty);
   
   input        clk;
   input        reset;
   input        txclk;
   input        ld_tx_req;
   output 	ld_tx_ack;
   input [7:0] 	tx_data;
   input        tx_enable;
   output       tx_out;
   output       tx_empty;
   input        rxclk;
   input        uld_rx_req;
   output 	uld_rx_ack;
   output [7:0] rx_data;
   input        rx_enable;
   input        rx_in;
   output       rx_empty;

   reg [7:0] 	rx_data;
   reg 		rx_empty;
   
   //
   integer 	tx_count;
   integer 	tx_ptr;
   integer 	tx_list[10:0];

   assign 	tx_empty = 0;

   initial
     begin
	rx_empty = 1;

	#2000;
	
//`define test_halt
//`define test_step
`define test_get

`ifdef test_halt
	tx_ptr = 0;
	tx_count = 5;
	tx_list[0] = 8'h30;
	tx_list[1] = 8'h40;
	tx_list[2] = 8'h50;
	tx_list[3] = 8'h60;
	tx_list[4] = 8'h93;
	rx_empty = 0;
	#110000;
	tx_ptr = 0;
	tx_count = 5;
	tx_list[0] = 8'h30;
	tx_list[1] = 8'h40;
	tx_list[2] = 8'h50;
	tx_list[3] = 8'h61;
	tx_list[4] = 8'h93;
	rx_empty = 0;
	#110000;
`endif
`ifdef test_get
	tx_ptr = 0;
	tx_count = 1;
	tx_list[0] = 8'h80;
	rx_empty = 0;
	#1250000;
`endif
`ifdef test_step
	tx_ptr = 0;
	tx_count = 5;
	tx_list[0] = 8'h30;
	tx_list[1] = 8'h40;
	tx_list[2] = 8'h50;
	tx_list[3] = 8'h62;
	tx_list[4] = 8'h93;
	rx_empty = 0;

	#110000;
	tx_ptr = 0;
	tx_count = 5;
	tx_list[0] = 8'h30;
	tx_list[1] = 8'h40;
	tx_list[2] = 8'h50;
	tx_list[3] = 8'h60;
	tx_list[4] = 8'h93;
	rx_empty = 0;

	#110000;
	tx_ptr = 0;
	tx_count = 5;
	tx_list[0] = 8'h30;
	tx_list[1] = 8'h40;
	tx_list[2] = 8'h50;
	tx_list[3] = 8'h62;
	tx_list[4] = 8'h93;
	rx_empty = 0;

	#110000;
	tx_ptr = 0;
	tx_count = 5;
	tx_list[0] = 8'h30;
	tx_list[1] = 8'h40;
	tx_list[2] = 8'h50;
	tx_list[3] = 8'h60;
	tx_list[4] = 8'h93;
	rx_empty = 0;
`endif 	

	#120000;
	$finish;
     end

   reg [1:0]	rx_uld;
   wire [1:0] 	rx_uld_next;
   wire 	uld_rx_data;
   
   reg [1:0]	tx_ld;
   wire [1:0] 	tx_ld_next;
   wire 	ld_tx_data;

   // require uld_rx_req to deassert before sending next char
   always @(posedge rxclk or posedge reset)
     if (reset)
       rx_uld <= 2'b00;
     else
       rx_uld <= rx_uld_next;

   assign rx_uld_next =
		      (rx_uld == 0 && uld_rx_req) ? 1 :
		      (rx_uld == 1) ? 2 :
		      (rx_uld == 2 && ~uld_rx_req) ? 0 :
		       rx_uld;

   assign uld_rx_ack = (rx_uld == 1) || (rx_uld == 2);
   assign uld_rx_data = (rx_uld == 1);

   always @(posedge rxclk)
     if (rx_uld == 1)
       begin
	  if (tx_count > 0)
	    begin
	       rx_data = tx_list[tx_ptr];
	       $display("fake_uart: jam %x, count %d", tx_list[tx_ptr], tx_count);
	    end
	  else
	    begin
	       rx_data = 0;
	    end
       end // if (rx_uld == 1)
   
   always @(posedge rxclk)
     if (rx_uld == 2 && ~uld_rx_req)
       begin
	  tx_ptr = tx_ptr + 1;
	  tx_count = tx_count - 1;
	  if (tx_count == 0)
	    rx_empty = 1;
       end
   
   // require tx_ld_req to deassert before accepting next char
   always @(posedge txclk or posedge reset)
     if (reset)
       tx_ld <= 2'b00;
     else
       tx_ld <= tx_ld_next;

   assign tx_ld_next =
		      (tx_ld == 0 && ld_tx_req) ? 1 :
		      (tx_ld == 1 && ~ld_tx_req) ? 0 :
//		      (tx_ld == 1) ? 2 :
//		      (tx_ld == 2 && ~ld_tx_req) ? 0 :
		      tx_ld;

   assign ld_tx_ack = (tx_ld == 1) || (tx_ld == 2);
   assign ld_tx_data = (tx_ld == 1);

   always @(posedge txclk)
     if (tx_ld == 1)
       $display("fake_uart: send %x", tx_data);
   
endmodule

`endif // !`ifndef fake_uart

/*
 serial spy port

   input [15:0] spy_in;
   output [15:0] spy_out;
   input 	dbread;
   input 	dbwrite;
   input [3:0] 	eadr;

8 bits/byte, 9600 8N1

top 4 bits are op, bottom 4 bits are data

76543210
oooodddd

op

0
1
2
3 set data-3
4 set data-2
5 set data-1
6 set data-0
7
8 read eadr
9 write eadr
a
b
c
d
e
f

 sending 0x8x returns 4 characters, result of reg "x", same format as set
 sending 0x9x writes data buffer to reg "x"
 sending 0x3x sets high nibble of data buffer
 sending 0x4x sets medh nibble of data buffer
 sending 0x5x sets medl nibble of data buffer
 sending 0x6x sets low nibble of data buffer
*/

module spy_port(sysclk, clk, reset, rs232_rxd, rs232_txd,
		spy_in, spy_out, dbread, dbwrite, eadr);
   

   input sysclk;
   input clk;
   input reset;

   input rs232_rxd;
   output rs232_txd;
   
   input [15:0] spy_in;

   output [15:0] spy_out;
   reg [15:0] 	 spy_out;

   output 	 dbread;
   reg 		 dbread;
   
   output 	 dbwrite;
   reg 		 dbwrite;
   
   output [3:0]	 eadr;
   reg [3:0] 	 eadr;

   
   //   
   wire 	 uart_tx_clk;
   wire 	 uart_rx_clk;
   
   brg baud_rate_generator(.clk(sysclk),
			   .reset(reset),
			   .tx_baud_clk(uart_tx_clk),
			   .rx_baud_clk(uart_rx_clk));

   wire 	 ld_tx_req, ld_tx_ack;
   wire		 uld_rx_req, uld_rx_ack;
   wire 	 tx_enable, tx_empty;
   wire 	 rx_enable, rx_empty;
   wire [7:0] 	 rx_data;
   reg [7:0] 	 tx_data;

   assign 	 rx_enable = 1;
   assign 	 tx_enable = 1;
   
   uart tt_uart(.clk(clk),
		.reset(reset),

		.txclk(uart_tx_clk),
		.ld_tx_req(ld_tx_req),
		.ld_tx_ack(ld_tx_ack),
		.tx_data(tx_data), 
		.tx_enable(tx_enable),
		.tx_out(rs232_txd),
		.tx_empty(tx_empty),

		.rxclk(uart_rx_clk),
		.uld_rx_req(uld_rx_req),
		.uld_rx_ack(uld_rx_ack),
		.rx_data(rx_data),
		.rx_enable(rx_enable),
		.rx_in(rs232_rxd),
		.rx_empty(rx_empty));

   reg [15:0] data;
   reg [3:0]  reg_addr;
   reg [15:0] response;
   reg 	      respond;
 	      
   reg [3:0]  spyu_state;
   wire [3:0]  spyu_next_state;

   wire       start_read;
   wire       start_write;
   
   wire       tx_start;
   wire       tx_done;
   
   parameter SPYU_IDLE = 0,
	       SPYU_RX1 = 1,
   	       SPYU_RX2 = 2,
   	       SPYU_OP = 3,
   	       SPYU_TX1 = 4,
   	       SPYU_TX2 = 5,
   	       SPYU_TX3 = 6,
   	       SPYU_TX4 = 7,
   	       SPYU_TX5 = 8,
   	       SPYU_TX6 = 9,
   	       SPYU_TX7 = 10,
   	       SPYU_TX8 = 11;

   assign uld_rx_req = spyu_state == SPYU_RX1;
   
   assign spyu_next_state =
			   (spyu_state == SPYU_IDLE && ~rx_empty) ? SPYU_RX1 :
			   (spyu_state == SPYU_IDLE && respond) ? SPYU_TX1 :
			   (spyu_state == SPYU_RX1 && uld_rx_ack) ? SPYU_RX2 :
			   (spyu_state == SPYU_RX2 && ~uld_rx_ack) ? SPYU_OP :
			   (spyu_state == SPYU_OP) ? SPYU_IDLE :
			   (spyu_state == SPYU_TX1) ? SPYU_TX2 :
			   (spyu_state == SPYU_TX2 && tx_done) ? SPYU_TX3 :
			   (spyu_state == SPYU_TX3) ? SPYU_TX4 :
			   (spyu_state == SPYU_TX4 && tx_done) ? SPYU_TX5 :
			   (spyu_state == SPYU_TX5) ? SPYU_TX6 :
			   (spyu_state == SPYU_TX6 && tx_done) ? SPYU_TX7 :
			   (spyu_state == SPYU_TX7) ? SPYU_TX8 :
			   (spyu_state == SPYU_TX8 && tx_done) ? SPYU_IDLE :
			   spyu_state;

   always @(posedge clk)
     if (reset)
       spyu_state <= 0;
     else
       spyu_state <= spyu_next_state;

   /* add == 2 so "space" can be used to test interface */
   assign start_read = (spyu_state == SPYU_OP) && ((rx_data[7:4] == 8) || (rx_data[7:4] == 2));
   assign start_write = (spyu_state == SPYU_OP) && (rx_data[7:4] == 9);
   
   always @(posedge clk)
     if (reset)
       begin
	  data <= 0;
	  reg_addr <= 0;
       end
     else
       if (spyu_state == SPYU_RX2)
	 begin
	    case (rx_data[7:4])
	      4'h0: ;
	      4'h1: ;
	      4'h2: ;
	      4'h3: data[15:12] <= rx_data[3:0];
	      4'h4: data[11:8]  <= rx_data[3:0];
	      4'h5: data[7:4]   <= rx_data[3:0];
	      4'h6: data[3:0]   <= rx_data[3:0];
	      4'h7: ;
	      4'h8: reg_addr <= rx_data[3:0];
	      4'h9: reg_addr <= rx_data[3:0];
	      4'ha: ;
	      4'hb: ;
	      4'hc: ;
	      4'hd: ;
	      4'he: ;
	      4'hf: ;
	    endcase
	 end

   always @(posedge clk)
     if (reset)
       begin
	  spy_out <= 0;
	  dbwrite <= 0;
	  dbread <= 0;
	  eadr <= 0;
	  respond <= 0;
       end
     else
       begin
	  spy_out <= start_write ? data : 16'h0000;
	  dbwrite <= start_write;
	  dbread <= start_read;
	  eadr <= (start_read || start_write) ? reg_addr : 0;
	  respond <= start_read;
       end

`ifdef debug
   always @(posedge clk)
     begin
	if (dbread)
	  $display("SPY: read %o", eadr);
	if (dbwrite)
	  $display("SPY: write %o <- %o", eadr, data);

	//if (spyu_state == SPYU_RX2)
	//$display("SPY: got uart byte 0x%x", rx_data);
     end
`endif
   
   always @(posedge clk)
     if (reset)
       response <= 0;
     else
       if (dbread)
	 response <= spy_in;

   // transmit one character
   assign tx_start = 
		     (spyu_state == SPYU_TX1) ||
		     (spyu_state == SPYU_TX3) ||
		     (spyu_state == SPYU_TX5) ||
		     (spyu_state == SPYU_TX7);

   always @(posedge clk)
     if (reset)
       tx_data <= 0;
     else
       case (spyu_state)
	 SPYU_TX1: tx_data <= { 4'h3, response[15:12] };
	 SPYU_TX3: tx_data <= { 4'h4, response[11:8] };
	 SPYU_TX5: tx_data <= { 4'h5, response[7:4] };
	 SPYU_TX7: tx_data <= { 4'h6, response[3:0] };
	 default: ;
       endcase

   reg [2:0] tx_state;
   wire [2:0] tx_next_state;
   
   assign ld_tx_req = (tx_state == 1) || (tx_state == 2);
   assign tx_done = tx_state == 5;
   
   assign tx_next_state =
			 (tx_state == 0 && tx_start) ? 1 :
			 (tx_state == 1) ? 2 :
			 (tx_state == 2 && ld_tx_ack) ? 3 :
			 (tx_state == 3 && ~ld_tx_ack) ? 4 :
			 (tx_state == 4 && tx_empty) ? 5 :
			 (tx_state == 5) ? 0 :
			 tx_state;
   
   always @(posedge clk)
     if (reset)
       tx_state <= 0;
     else
       tx_state <= tx_next_state;

endmodule // spy_port

