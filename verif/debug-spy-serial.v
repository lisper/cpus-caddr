
module spy_port_driver(input sysclk, 
		       input 	    clk,
		       input 	    reset,
		       output 	    rs232_rxd,
		       input 	    rs232_txd,
		       input [15:0] spy_in,
		       input [15:0] spy_out,
		       input 	    dbread,
		       input 	    dbwrite,
		       input [4:0]  eadr,
		       input 	    tx_req,
		       input 	    tx_ack,
		       input [7:0]  tx_data);
   

   // send rs232 data by wiggling rs232 input
   //
   // 50,000,000Mhz clock = 20ns cycle
   // 115200 baud is 1 bit every 1/115200 = .00000868 = 8.68us
   // 8.68us = 8680ns
`define bitdelay 8680

   integer success;
   integer done;
   reg rx;

   assign rs232_rxd = rx;
   
   //
   task final_wait;
      integer i;
      begin
	 for (i = 0; i < 10; i = i + 1)
	   #`bitdelay;
      end
   endtask

   task stop_one;
      begin
	 $display("set step %t", $time);
	 test.cpu.step = 1'b1;
	 test.cpu.run = 1'b0;
	 while (test.cpu.machrun != 0)
	   @(posedge clk);

	 $display("reset step %t", $time);
	 test.cpu.step = 1'b0;
	 repeat(20) @(posedge clk);

	 $display("stopped pc=%o state=%b %t", test.cpu.pc, test.cpu.state, $time);
      end
   endtask
	 
   task step_one;
      begin
	 $display("set step %t", $time);
	 test.cpu.step = 1'b1;
	 while (test.cpu.machrun == 0)
	   @(posedge clk);
	 while (test.cpu.machrun != 0)
	   @(posedge clk);

	 $display("reset step %t", $time);
	 test.cpu.step = 1'b0;
	 repeat(20) @(posedge clk);

	 $display("stopped pc=%o state=%b %t", test.cpu.pc, test.cpu.state, $time);
      end
   endtask // step_one
   
   task do_step;
      integer i;
      
      begin
	 stop_one;

	 for (i = 0; i < 100; i = i + 1)
	   step_one;

	 done = 1;
      end
   endtask
   
   task notice_tx;
      begin
	 while (done == 0)
	   begin
	      @(posedge clk)
	      if (tx_req && tx_ack)
		$display("tx_req: tx_data %x", tx_data);
	   end
      end
   endtask
   
   task notice_rw;
      begin
	 while (done == 0)
	   begin
	      //@(posedge clk)
	      if (dbread)
		begin
		   $display("dbread; eadr %x; %t", eadr, $time);
		   @(posedge clk);
		end // if (dbread)

	      if (dbwrite)
		begin
		   $display("dbwrite; eadr %x out %x in %x; %t", eadr, spy_out, spy_in, $time);
		   @(posedge clk);
		end
	      #1;
	   end
      end
   endtask
   
   task send_tt_rx;
      input [7:0] data;
      begin
	 $display("send %x", data);
	 #`bitdelay rx = 0;
	 #`bitdelay rx = data[0];
	 #`bitdelay rx = data[1];
	 #`bitdelay rx = data[2];
	 #`bitdelay rx = data[3];
	 #`bitdelay rx = data[4];
	 #`bitdelay rx = data[5];
	 #`bitdelay rx = data[6];
	 #`bitdelay rx = data[7];
	 #`bitdelay rx = 1;
	 #`bitdelay rx = 1;
      end
   endtask 

   task tx_delay;
	#1000000;
   endtask
   
   task send_req0;
      begin
	 send_tt_rx(8'h80); tx_delay;
      end
   endtask

   task send_req1;
      begin
	 send_tt_rx(8'h81); tx_delay;
      end
   endtask // send_req1

   task send_req3;
      begin
	 send_tt_rx(8'h31); tx_delay;
	 send_tt_rx(8'h42); tx_delay;
	 send_tt_rx(8'h53); tx_delay;
	 send_tt_rx(8'h64); tx_delay;
	 send_tt_rx(8'ha2); tx_delay;
      end
   endtask // send_req3

   task send_req4;
      begin
	 send_tt_rx(8'h60); tx_delay;
	 send_tt_rx(8'ha3); tx_delay;
      end
   endtask

   task send_req5;
      begin
	 send_tt_rx(8'h34); tx_delay;
	 send_tt_rx(8'h43); tx_delay;
	 send_tt_rx(8'h52); tx_delay;
	 send_tt_rx(8'h61); tx_delay;
	 send_tt_rx(8'ha8); tx_delay;
	 send_tt_rx(8'ha9); tx_delay;
      end
   endtask

   task send_req6;
      begin
	 send_tt_rx(8'h90); tx_delay;
	 send_tt_rx(8'h91); tx_delay;
      end
   endtask // send_req1

   task send_req7;
      begin
	 send_tt_rx(8'h31); tx_delay;
	 send_tt_rx(8'h41); tx_delay;
	 send_tt_rx(8'h52); tx_delay;
	 send_tt_rx(8'h62); tx_delay;
	 send_tt_rx(8'haa); tx_delay;

	 send_tt_rx(8'h33); tx_delay;
	 send_tt_rx(8'h43); tx_delay;
	 send_tt_rx(8'h54); tx_delay;
	 send_tt_rx(8'h64); tx_delay;
	 send_tt_rx(8'hab); tx_delay;
      end
   endtask

   task send_req8;
      begin
	 send_tt_rx(8'h92); tx_delay;
	 send_tt_rx(8'h93); tx_delay;
      end
   endtask // send_req1

   task send_reqs;
      begin
	 //send_req0;
	 //send_req1;
	 //send_req3;
	 //send_req4;
	 send_req5;
	 send_req6;
	 send_req7;
	 send_req8;
	 final_wait;
	 done = 1;
      end
   endtask
      
   initial
     begin
     end

   always @(posedge clk)
     begin
	if (dbread)
	  $display("SPY: read %o", eadr);
	if (dbwrite)
	  $display("SPY: write %o <- %o", eadr, spy_out);
     end

   initial
     begin
	success = 1;
	done = 0;
	#5000;

	// stop cpu and step a few times
	do_step;

	fork
	   send_reqs;
	   notice_rw;
	   notice_tx;
	join
	
	$finish;
	
     end
   
endmodule
