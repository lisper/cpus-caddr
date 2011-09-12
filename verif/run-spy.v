// run-spy.v

`timescale 1ns / 1ns

//`define fake_uart
//`define sim_time

`include "../rtl/spy.v"

module run_spy;

   reg clk;
   reg reset;
   wire rs232_rxd;
   wire rs232_txd;
   reg [15:0] spy_in;
   wire [15:0] spy_out;
   wire dbread;
   wire dbwrite;
   wire [3:0] eadr;

   spy_port spy_port(.sysclk(clk),
		     .clk(clk),
		     .reset(reset),
		     .rs232_rxd(rs232_rxd),
		     .rs232_txd(rs232_txd),
		     .spy_in(spy_in),
		     .spy_out(spy_out),
		     .dbread(dbread),
		     .dbwrite(dbwrite),
		     .eadr(eadr));

   // send rs232 data by wiggling rs232 input
   //
   // 50,000,000Mhz clock = 20ns cycle
   // 9600 baud is 1 bit every 1/9600 = 1.04e-4 = .000104 = 104us
   // 104ns = 104166ns
`define bitdelay 104166

   reg 	rx;
   assign rs232_rxd = rx;
   
   task send_tt_rx;
      input [7:0] data;
      begin
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

   initial
     begin
	$timeformat(-9, 0, "ns", 7);

	$dumpfile("run-spy.vcd");
	$dumpvars(0, run_spy);
     end

   initial
     begin
	clk = 0;
	reset = 0;
	rx = 1;
	spy_in = 16'o1234;

	#1 reset = 1;
	#50 reset = 0;

`ifndef fake_uart
	send_tt_rx(8'h80);
	#1000000;
	send_tt_rx(8'h81);
	#1000000;
	send_tt_rx(8'h31);
	#1000000;
	send_tt_rx(8'h42);
	#1000000;
	send_tt_rx(8'h53);
	#1000000;
	send_tt_rx(8'h64);
	#1000000;
	send_tt_rx(8'h92);
	#1000000;
	send_tt_rx(8'h60);
	#1000000;
	send_tt_rx(8'h93);
	#1000000;
	$finish;
`endif

	#1000000;
	#1000000;
	#1000000;
	#1000000;
	
     end

  always
    /* 50MHz clock */
    begin
      #10 clk = 0;
      #10 clk = 1;
    end

endmodule // run_spy
