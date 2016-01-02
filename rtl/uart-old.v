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

