
`include "../rtl/mmc.v"

`timescale 1ns / 1ns

module test_mmc;

   reg clk;
   reg reset;
   reg mmc_speed;
   reg mmc_wr;
   reg mmc_rd;
   reg mmc_init;
   reg mmc_send;
   reg [47:0] mmc_cmd;
   wire       mmc_done;
   reg [7:0]  mmc_data_in;
   wire [7:0] mmc_data_out;
   wire       mmc_cs;
   reg 	      mmc_di;
   wire       mmc_do;
   wire       mmc_sclk;
   reg [7:0]  data;
	
   mmc mmc(.clk(clk), .reset(reset), .speed(mmc_speed),
	   .wr(mmc_wr), .rd(mmc_rd), .init(mmc_init), .send(mmc_send),
	   .cmd(mmc_cmd), .data_in(mmc_data_in), .data_out(mmc_data_out), .done(mmc_done),
	   .mmc_cs(mmc_cs), .mmc_di(mmc_di), .mmc_do(mmc_do), .mmc_sclk(mmc_sclk));

   task wait_for_mmc_busy;
      begin
	 @(posedge clk);
	 while (mmc_done == 1'b1) @(posedge clk);
      end
   endtask // wait_for_mmc_done
   
   task wait_for_mmc_done;
      begin
	 while (mmc_done == 1'b0) @(posedge clk);
      end
   endtask // wait_for_mmc_done
   
   task do_mmc_init;
      begin
	 @(negedge clk);
	 mmc_init = 1;
 	 wait_for_mmc_busy;
	 mmc_init = 0;
	 wait_for_mmc_done;
      end
   endtask // mmc_write
   
   task do_mmc_send;
      input [47:0] cmd;
      begin
	 mmc_cmd = cmd;
	 @(negedge clk);
	 mmc_send = 1;
 	 wait_for_mmc_busy;
	 mmc_send = 0;
	 wait_for_mmc_done;
	 @(posedge clk);
      end
   endtask // mmc_write
   
   task do_mmc_write;
      input [7:0] data;
      begin
	 mmc_data_in = data;
	 @(negedge clk);
	 mmc_wr = 1;
 	 wait_for_mmc_busy;
	 mmc_wr = 0;
	 wait_for_mmc_done;
	 @(posedge clk);
      end
   endtask // mmc_write
   
   task do_mmc_read;
      output [7:0] data;
      begin
	 @(negedge clk);
	 mmc_rd = 1;
 	 wait_for_mmc_busy;
	 mmc_rd = 0;
	 wait_for_mmc_done;
	 data = mmc_data_out;
	 @(posedge clk);
      end
   endtask // mmc_read
   
   initial
     begin
	$timeformat(-9, 0, "ns", 7);
	$dumpfile("run-mmc.vcd");
	$dumpvars(0, test_mmc);
     end

   initial
     begin
	clk = 0;
	reset = 1;
	mmc_speed = 0;
	mmc_wr = 0;
	mmc_rd = 0;
	mmc_init = 0;
	mmc_send = 0;
	mmc_cmd = 0;
	mmc_di = 0;
       
	#5000 reset = 0;
	#50 ;
	
	do_mmc_init;
	do_mmc_send(48'h410000000095);
	do_mmc_read(data);
	do_mmc_read(data);
	do_mmc_read(data);
	do_mmc_read(data);

	mmc_speed = 1;
	do_mmc_send(48'h580000000095);
	do_mmc_read(data);
	do_mmc_read(data);
	do_mmc_read(data);
	do_mmc_read(data);
	do_mmc_read(data);
	do_mmc_read(data);

	do_mmc_write(data);
	do_mmc_write(data);

	#5000 $finish;
     end

   always
     begin
	#5 clk = 0;
	#5 clk = 1;
     end

   always
     begin
	#10 $pli_mmc(mmc_cs, mmc_sclk, mmc_di, mmc_do);
     end

endmodule // test_mmc
