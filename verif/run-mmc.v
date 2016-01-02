
//`define use_pli_mmc
`define use_vlog_mmc

`include "../rtl/mmc.v"

`ifdef use_vlog_mmc
 `include "../niox/verif/mmc_model.v"
`endif

`timescale 1ns / 1ns

module test_mmc;

   reg clk;
   reg reset;
   reg mmc_speed;
   reg mmc_wr;
   reg mmc_rd;
   reg mmc_init;
   reg mmc_send;
   reg mmc_stop;
   reg [47:0] mmc_cmd;
   wire       mmc_done;
   reg [7:0]  mmc_data_in;
   wire [7:0] mmc_data_out;
   wire       mmc_cs;
   wire       mmc_di;
   wire       mmc_do;
   wire       mmc_sclk;
   reg [7:0]  data;
	
   mmc mmc(.clk(clk), .reset(reset), .speed(mmc_speed),
	   .wr(mmc_wr), .rd(mmc_rd), .init(mmc_init), .send(mmc_send), .stop(mmc_stop),
	   .cmd(mmc_cmd), .data_in(mmc_data_in), .data_out(mmc_data_out), .done(mmc_done),
	   .mmc_cs(mmc_cs), .mmc_di(mmc_di), .mmc_do(mmc_do), .mmc_sclk(mmc_sclk));

   task wait_for_mmc_busy;
      integer loops;
      begin
	 @(posedge clk);
	 while (mmc_done == 1'b1)
	   begin 
	      loops = loops + 1;
	      if (loops > 100000)
		begin
		   $display("TIMEOUT: wait_for_mmc_busy");
		   $finish;
		end
	      @(posedge clk);
	   end
      end
   endtask // wait_for_mmc_done
   
   task wait_for_mmc_done;
      integer loops;
      begin
	 loops = 0;
	 while (mmc_done == 1'b0)
	   begin 
	      loops = loops + 1;
	      if (loops > 100000)
		begin
		   $display("TIMEOUT: wait_for_mmc_done");
		   $finish;
		end
	      @(posedge clk);
	 end
      end
   endtask // wait_for_mmc_done

   task wait_for_data;
      input [7:0] want;
      integer loops;
      begin
	 loops = 0;
	 do_mmc_read(data);
	 $display("-> %x", data);
	 while (data != want)
	   begin
	      loops = loops + 1;
	      if (loops > 1000)
		begin
		   $display("TIMEOUT: wait_for_data");
		   $finish;
		end
	      //$display("-> %x", data);
	      do_mmc_read(data);
	   end
	 $display("-> %x (good)", data);
      end
   endtask // wait_for_data
   
   task get_block;
      input [31:0] size;
      integer 	   i;
      begin
	 for (i = 0; i < size; i = i + 1) begin
	    do_mmc_read(data); 
	    $display("[%d] %x", i, data);
	 end
      end
   endtask
   
   task do_mmc_init;
      begin
	 @(posedge clk);
	 mmc_init = 1;
	 @(negedge clk);
 	 wait_for_mmc_busy;
	 mmc_init = 0;
	 wait_for_mmc_done;
      end
   endtask // mmc_write
   
   task do_mmc_send;
      input [47:0] cmd;
      begin
	 mmc_cmd = cmd;
	 @(posedge clk);
	 mmc_send = 1;
	 @(negedge clk);
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
	 @(posedge clk);
	 mmc_wr = 1;
	 @(negedge clk);
 	 wait_for_mmc_busy;
	 mmc_wr = 0;
	 wait_for_mmc_done;
	 @(posedge clk);
      end
   endtask // mmc_write
   
   task do_mmc_read;
      output [7:0] data;
      begin
	 @(posedge clk);
	 mmc_rd = 1;
	 @(negedge clk);
 	 wait_for_mmc_busy;
	 mmc_rd = 0;
	 //$display("do_mmc_read; waiting done");
	 wait_for_mmc_done;
	 //$display("do_mmc_read; got done, data=%x", mmc_data_out);
	 data = mmc_data_out;
	 @(posedge clk);
      end
   endtask // mmc_read

   task do_mmc_done;
      begin
	 @(posedge clk);
	 mmc_stop = 1;
	 @(negedge clk);
	 wait_for_mmc_done;
	 mmc_stop = 0;
      end
   endtask // do_mmc_done
   
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
//	mmc_di = 0;
	mmc_stop = 0;
	mmc_data_in = 0;

	#5000 reset = 0;
	#50 ;
	
	do_mmc_init;
	do_mmc_send(48'h400000000095);
	wait_for_data(8'h01);
	do_mmc_done;
	
	do_mmc_send(48'h410000000095);
	wait_for_data(8'h00);
	do_mmc_done;
	
	mmc_speed = 1;
	do_mmc_send(48'h580000000095);
	wait_for_data(8'h00);
	get_block(512);
	
	data = 8'h12;
	do_mmc_write(data);

	data = 8'h11;
	do_mmc_write(data);
	do_mmc_done;

	#50000 $finish;
     end

   always
     begin
	#5 clk = 0;
	#5 clk = 1;
     end

`ifdef use_pli_mmc
   always
     begin
	#10 $pli_mmc(mmc_cs, mmc_sclk, mmc_di, mmc_do);
     end
`endif

`ifdef use_vlog_mmc
   mmc_model mmc_card(
		      .spiClk(mmc_sclk),
		      .spiDataIn(mmc_do),
		      .spiDataOut(mmc_di),
		      .spiCS_n(mmc_cs)
		      );
`endif
   
endmodule // test_mmc
