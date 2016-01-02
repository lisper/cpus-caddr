// 
// serial port spy support
//


`ifdef SIMULATION
 //`define test_output
 `define sim_time
 `define debug
`endif

`include "uart.v"

/*
 serial spy port

   input [15:0] spy_in;
   output [15:0] spy_out;
   input 	dbread;
   input 	dbwrite;
   input [4:0] 	eadr;

8 bits/byte, 115200 8N1

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
8 read eadr, eadr 0x00-0x0f
9 read eadr, eadr 0x10-0x1f
a write eadr, eadr 0x00-0x0f
b write eadr, eadr 0x10-0x1f
c
d
e
f

 sending 0x8x returns 4 characters, result of reg "x", same format as set
 sending 0x9x returns 4 characters, result of reg "x", same format as set
 sending 0xax writes data buffer to reg "x" 
 sending 0xbx writes data buffer to reg "x" 
 sending 0x3x sets high nibble of data buffer
 sending 0x4x sets medh nibble of data buffer
 sending 0x5x sets medl nibble of data buffer
 sending 0x6x sets low nibble of data buffer
*/

module spy_port(sysclk, clk, reset, rs232_rxd, rs232_txd,
		spy_in, spy_out, dbread, dbwrite, eadr,
		bd_cmd, bd_start, bd_bsy, bd_rdy, bd_err, bd_addr,
		bd_data_in, bd_data_out, bd_rd, bd_wr, bd_iordy, bd_state
		);

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
   
   output [4:0]	 eadr;
   reg [4:0] 	 eadr;

   //
   output [1:0]  bd_cmd;
   output 	 bd_start;
   input 	 bd_bsy;
   input 	 bd_rdy;
   input 	 bd_err;
   output [23:0] bd_addr;
   input [15:0] bd_data_in;
   output [15:0]  bd_data_out;
   output 	 bd_rd;
   output 	 bd_wr;
   input 	 bd_iordy;
   input [11:0]	 bd_state;
   
   //   
   wire 	 uart_reset;
   wire 	 uart_clk;
   wire 	 spy_reset;
   wire 	 spy_clk;
   
   assign uart_clk = sysclk;
   assign uart_reset = reset;

   assign spy_clk = clk;
   assign spy_reset = reset;
   
   //   
   wire 	 ld_tx_req, ld_tx_ack;
   wire		 rx_req, rx_ack;
   wire 	 tx_enable, tx_empty;
   wire 	 rx_enable, rx_empty;
   reg [7:0] 	 rx_data;
   wire [7:0] 	 tx_data;
   wire [7:0] 	 rx_out;

   assign 	 rx_enable = 1;
   assign 	 tx_enable = 1;
   
   uart spy_uart(.clk(clk/*uart_clk*/),
		 .reset(uart_reset),

		 .ld_tx_req(ld_tx_req),
		 .ld_tx_ack(ld_tx_ack),
		 .tx_data(tx_data), 
		 .tx_enable(tx_enable),
		 .tx_out(rs232_txd),
		 .tx_empty(tx_empty),
		 
		 .rx_empty(rx_empty),
		 .rx_req(rx_req),
		 .rx_ack(rx_ack),
		 .rx_data(rx_out),
		 .rx_enable(rx_enable),
		 .rx_in(rs232_rxd)
		 );

   reg [15:0] data;
   reg [4:0]  reg_addr;
   reg [15:0] response;
   reg	      respond;
 	      
   reg [3:0]  spyu_state;
   wire [3:0]  spyu_next_state;

   wire       start_read;
   wire       start_write;

   wire       start_bd_read;
   wire       start_bd_write;
   
   wire       tx_start;
   wire       tx_done;
   
   parameter SPYU_IDLE = 4'd0,
	       SPYU_RX1  = 4'd1,
   	       SPYU_RX2  = 4'd2,
   	       SPYU_OP   = 4'd3,
   	       SPYU_OPR  = 4'd4,
               SPYU_OPW1 = 4'd5,
               SPYU_OPW2 = 4'd6,
   	       SPYU_TX1  = 4'd7,
   	       SPYU_TX2  = 4'd8,
   	       SPYU_TX3  = 4'd9,
   	       SPYU_TX4  = 4'd10,
   	       SPYU_TX5  = 4'd11,
   	       SPYU_TX6  = 4'd12,
   	       SPYU_TX7  = 4'd13,
   	       SPYU_TX8  = 4'd14;

   //
   assign spyu_next_state =
			   (spyu_state == SPYU_IDLE && ~rx_empty) ? SPYU_RX1 :
			   (spyu_state == SPYU_IDLE && respond) ? SPYU_TX1 :
			   (spyu_state == SPYU_RX1 && rx_ack) ? SPYU_RX2 :
			   (spyu_state == SPYU_RX2 && ~rx_ack) ? SPYU_OP :
			   (spyu_state == SPYU_OP && start_read) ? SPYU_OPR:
			   (spyu_state == SPYU_OP && start_write) ? SPYU_OPW1 :
			   (spyu_state == SPYU_OP) ? SPYU_IDLE :			  
 			   (spyu_state == SPYU_OPR) ? SPYU_IDLE :
			   (spyu_state == SPYU_OPW1) ? SPYU_OPW2 :
			   (spyu_state == SPYU_OPW2) ? SPYU_IDLE :
			   (spyu_state == SPYU_TX1) ? SPYU_TX2 :
			   (spyu_state == SPYU_TX2 && tx_done) ? SPYU_TX3 :
			   (spyu_state == SPYU_TX3) ? SPYU_TX4 :
			   (spyu_state == SPYU_TX4 && tx_done) ? SPYU_TX5 :
			   (spyu_state == SPYU_TX5) ? SPYU_TX6 :
			   (spyu_state == SPYU_TX6 && tx_done) ? SPYU_TX7 :
			   (spyu_state == SPYU_TX7) ? SPYU_TX8 :
			   (spyu_state == SPYU_TX8 && tx_done) ? SPYU_IDLE :
			   spyu_state;

   always @(posedge spy_clk)
     if (spy_reset)
       spyu_state <= 0;
     else
       spyu_state <= spyu_next_state;

   /* add == 2 so "space" can be used to test interface */
   assign start_read =  (spyu_state == SPYU_OP) && ((rx_data[7:4] == 8) || (rx_data[7:4] == 9) || (rx_data[7:4] == 2));
   assign start_write = (spyu_state == SPYU_OP) && ((rx_data[7:4] == 4'ha) || (rx_data[7:4] == 4'hb));

   // capture uart output
   assign rx_req = spyu_state == SPYU_RX1;
   
   always @(posedge clk)
     if (reset)
       rx_data <= 8'b0;
     else
       if (rx_req)
	 rx_data <= rx_out;
		
   always @(posedge spy_clk)
     if (spy_reset)
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
	      4'h8: reg_addr <= rx_data[4:0];
	      4'h9: reg_addr <= rx_data[4:0];
	      4'ha: reg_addr <= rx_data[4:0];
	      4'hb: reg_addr <= rx_data[4:0];
	      4'hc: ;
	      4'hd: ;
	      4'he: ;
	      4'hf: ;
	    endcase
	 end

   always @(negedge spy_clk)
     if (spy_reset)
       begin
	  dbwrite <= 0;
       end
     else
       begin
       	  dbwrite <= (spyu_state == SPYU_OPW1)/*start_write*//* || (spyu_state == SPYU_OPW)*/;
       end
   
   always @(posedge spy_clk)
     if (spy_reset)
       begin
	  spy_out <= 0;
	  dbread <= 0;
	  eadr <= 0;
	  respond <= 0;
       end
     else
       begin
	  dbread <= start_read || (spyu_state == SPYU_OPR);

	  if (start_write)
	    spy_out <= data;

	  if (start_read || start_write)
	      eadr <= reg_addr;

`ifndef test_output
	  respond <= dbread;
`else
	  respond <= 1'b1;
`endif
   
	  
       end

`ifdef debug
   always @(posedge clk)
     begin
	if (dbread)
	  $display("SPY: read %o", eadr);
	if (dbwrite)
	  $display("SPY: write %o <- %o", eadr, data);

	if (spyu_state == SPYU_RX2)
	  $display("SPY: read  uart byte 0x%x", rx_data);
	if (ld_tx_req)
	  $display("SPY: write uart byte 0x%x", tx_data);
     end
`endif
   
   always @(posedge spy_clk)
     if (spy_reset)
       response <= 0;
     else
       if (dbread)
	 response <= spy_in;
       else
	 if (start_bd_read)
	   response <= 
		       (reg_addr == 0) ? { bd_state, bd_bsy, bd_rdy, bd_err, bd_iordy} :
		       (reg_addr == 1) ? bd_data_in :
		       16'h1111;

   // transmit one character
   assign tx_start = 
		     (spyu_state == SPYU_TX1) ||
		     (spyu_state == SPYU_TX3) ||
		     (spyu_state == SPYU_TX5) ||
		     (spyu_state == SPYU_TX7);

   assign tx_data =
`ifndef test_output
		   (spyu_state == SPYU_TX1 || spyu_state == SPYU_TX2 ) ? { 4'h3, response[15:12] } :
		   (spyu_state == SPYU_TX3 || spyu_state == SPYU_TX4 ) ? { 4'h4, response[11: 8] } :
		   (spyu_state == SPYU_TX5 || spyu_state == SPYU_TX6 ) ? { 4'h5, response[ 7: 4] } :
		   (spyu_state == SPYU_TX7 || spyu_state == SPYU_TX8 ) ? { 4'h6, response[ 3: 0] } :
		   8'h00;
`else
		   (spyu_state == SPYU_TX1 || spyu_state == SPYU_TX2 ) ? 8'h30 :
		   (spyu_state == SPYU_TX3 || spyu_state == SPYU_TX4 ) ? 8'h31 :
		   (spyu_state == SPYU_TX5 || spyu_state == SPYU_TX6 ) ? 8'h0d :
		   (spyu_state == SPYU_TX7 || spyu_state == SPYU_TX8 ) ? 8'h0a :
		   8'h00;
`endif

   //
   reg [2:0] tx_state;
   wire [2:0] tx_next_state;
   wire       tx_delay_done;

   assign ld_tx_req = tx_state == 1;
   assign tx_done = tx_state == 7;
   assign tx_delay_done = 1;
   
   assign tx_next_state =
			 (tx_state == 0 && tx_start)      ? 3'd1 :
			 (tx_state == 1 && ld_tx_ack)     ? 3'd2 :
			 (tx_state == 2 && ~ld_tx_ack)    ? 3'd3 :
			 (tx_state == 3)                  ? 3'd4 :
			 (tx_state == 4 && tx_empty)      ? 3'd5 :
			 (tx_state == 5)                  ? 3'd6 :
			 (tx_state == 6 && tx_delay_done) ? 3'd7 :
			 (tx_state == 7)                  ? 3'd0 :
			 tx_state;
   
   always @(posedge spy_clk)
     if (spy_reset)
       tx_state <= 0;
     else
       tx_state <= tx_next_state;

   //
   assign start_bd_read =  (spyu_state == SPYU_OP) && (rx_data[7:4] == 4'hc);
   assign start_bd_write = (spyu_state == SPYU_OP) && (rx_data[7:4] == 4'hd);

   reg [15:0] spy_bd_reg, spy_bd_data;
   
   always @(posedge spy_clk)
     if (spy_reset)
       spy_bd_reg <= 0;
     else
       begin
	  if (start_bd_write)
	    spy_bd_reg <= data;
	  else
	    spy_bd_reg[2] <= 0;
       end
   
   assign bd_cmd = spy_bd_reg[1:0];
   assign bd_start = spy_bd_reg[2];
   assign bd_rd = spy_bd_reg[3];
   assign bd_wr = spy_bd_reg[4];
   assign bd_data_out = spy_bd_data;
   
endmodule // spy_port

