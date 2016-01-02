/*
 * test disk controller
 */

`define debug
`define debug_state
`define debug_detail
`define debug_detail_delay
`define debug_disk
`define DBG_DLY #1

//`define use_ide
`define use_mmc

//`define use_pli_mmc
`define use_vlog_mmc
  
`include "../rtl/busint.v"
`include "../rtl/xbus-sram.v"
`include "../rtl/xbus-disk.v"
`include "../rtl/xbus-tv.v"
`include "../rtl/xbus-io.v"
`include "../rtl/xbus-unibus.v"
`include "../rtl/xbus-spy.v"
`include "../rtl/ide_block_dev.v"
`include "../rtl/mmc_block_dev.v"
`include "../rtl/ide.v"
`include "../rtl/mmc.v"

`ifdef use_vlog_mmc
 `include "../niox/verif/mmc_model.v"
`endif

`timescale 1ns / 1ns

module test_busint;
   reg clk;
   reg reset;

   reg [21:0] addr;
   reg [31:0] busin;
   wire [31:0] busout;
   wire [15:0]  spyin;
   wire [15:0]  spyout;
   reg 	       req;
   wire        ack;
   reg 	       write;
   wire        load;
   wire        interrupt;

   wire [1:0] 	bd_cmd;	/* generic block device interface */
   wire 	bd_start;
   wire 	bd_bsy;
   wire 	bd_rdy;
   wire 	bd_err;
   wire [23:0] 	bd_addr;
   wire [15:0] 	bd_data_in;
   wire [15:0] 	bd_data_out;
   wire 	bd_rd;
   wire 	bd_wr;
   wire 	bd_iordy;
   wire [11:0] 	bd_state;

   wire [21:0] 	sdram_addr;
   wire [31:0] 	sdram_data_out;
   wire [31:0] 	sdram_data_in;
   wire 	sdram_req;
   wire 	sdram_ready;
   wire 	sdram_write;
   wire 	sdram_done;

   integer 	success;
   
   busint busint(.mclk(clk),
		 .reset(reset),
		 .addr(addr),
		 .busin(busin),
		 .busout(busout),
		 .spyin(spyin),
		 .spyout(spyout),
		 .spyreg(),
		 .spyrd(),
		 .spywr(),
		 .req(req),
		 .ack(ack),
		 .write(write), 
		 .load(load),
		 .interrupt(interrupt),

		 .sdram_addr(sdram_addr),
		 .sdram_data_in(sdram_data_in),
		 .sdram_data_out(sdram_data_out),
		 .sdram_req(sdram_req),
		 .sdram_ready(sdram_ready),
		 .sdram_write(sdram_write),
		 .sdram_done(sdram_done),
		 
		 .vram_addr(), .vram_data_in(), .vram_data_out(),
		 .vram_req(), .vram_ready(), .vram_write(), .vram_done(),

		 .bd_cmd(bd_cmd),
		 .bd_start(bd_start),
		 .bd_bsy(bd_bsy),
		 .bd_rdy(bd_rdy),
		 .bd_err(bd_err),
		 .bd_addr(bd_addr),
		 .bd_data_in(bd_data_out),
		 .bd_data_out(bd_data_in),
		 .bd_rd(bd_rd),
		 .bd_wr(bd_wr),
		 .bd_iordy(bd_iordy),
		 .bd_state_in(bd_state),

		 .kb_data(), .kb_ready(),
		 .ms_x(), .ms_y(), .ms_button(), .ms_ready(),

		 .promdisable(), .disk_state(), .bus_state()
		 );


   task wait_for_bi_done;
      begin
	 while (ack == 1'b0) @(posedge clk);
//	 @(posedge clk);
      end

   endtask

   task bus_read;
      input [21:0] a;
      output [31:0] out;
      begin
	 @(posedge clk);
	 write = 0;
 	 req = 1;
	 addr = a;
	 wait_for_bi_done;
	 if (0) $display("read: addr %o in %x out %x, %t",
			 addr, busin, busout, $time);
	 out = busout;
	 req = 0;
	 @(posedge clk);
      end
   endtask

   task bus_write;
      input [21:0] a;
      input [31:0] data;

      begin
	 @(posedge clk);
	 write = 1;
	 addr = a;
	 busin = data;
 	 req = 1;
	 $display("write: addr %o in %x out %x, %t",
		  addr, busin, busout, $time);
	 wait_for_bi_done;
	 req = 0;
	 @(posedge clk);
      end
   endtask

   task wait_for_disk_idle;
      reg [31:0]   status;
      begin
	 status = 0;
	 while ((status & 1) == 0)
	   begin
	      bus_read(22'o17377774, status);
	      @(posedge clk);
	   end
	 $display("wait-for-disk: status %x", status);
      end
   endtask
   
   task wait_for_disk_busy;
      reg [31:0]   status;
      begin
	 status = 0;
	 while ((status & 1) == 1)
	   begin
	      bus_read(22'o17377774, status);
	      @(posedge clk);
	   end
	 $display("wait-for-disk: status %x", status);
      end
   endtask
   
   task disk_read;
      input [31:0] da;
      begin
	 // write dram - command list
	 bus_write(22'o22, 32'o1000);

//	 bus_write(22'o22, 32'o1001);
//	 #100
//	   bus_write(22'o23, 32'o4000);

	 // program disk controller
	 wait_for_disk_idle;
	 bus_write(22'o17377776, da);		// load disk address
	 bus_write(22'o17377775, 32'o22);	// load clp
	 bus_write(22'o17377774, 32'o0);	// load cmd
	 bus_write(22'o17377777, 32'o0);	// start read
	 wait_for_disk_busy;
 	 wait_for_disk_idle;
      end
   endtask

   task zero_ram;
      integer i;
      begin
	 for (i = 0; i < 256; i = i + 1)
      	   test_busint.busint.dram.ram[i] = 0;
      end
   endtask	     

   task fill_ram;
      begin
      	 test_busint.busint.dram.ram['o1000] = 'h11112222;
	 test_busint.busint.dram.ram['o1001] = 'h33334444;
     	 test_busint.busint.dram.ram['o1002] = 'h55556666;
     	 test_busint.busint.dram.ram['o1003] = 'h12345678;
     	 test_busint.busint.dram.ram['o1004] = 'h87654321;
     	 test_busint.busint.dram.ram['o1005] = 'h00000000;
	 test_busint.busint.dram.ram['o1006] = 'h00000000;
//     	 test_busint.busint.dram.ram['o1002] = 'h12345678;
//     	 test_busint.busint.dram.ram['o1003] = 'h87654321;
//     	 test_busint.busint.dram.ram['o1004] = 'h11223344;
//     	 test_busint.busint.dram.ram['o1005] = 'h55667788;
      end
   endtask	     

   task disk_write;
      input [31:0] da;
      begin
	 // write dram - command list
	 bus_write(22'o22, 32'o1000);

//	 bus_write(22'o22, 32'o1001);
//	 #100
//	   bus_write(22'o23, 32'o4000);

	 // program disk controller
	 wait_for_disk_idle;
	 bus_write(22'o17377776, da);		// load disk address
	 bus_write(22'o17377775, 32'o22);	// load clp
	 bus_write(22'o17377774, 32'o11);	// load cmd
	 bus_write(22'o17377777, 32'o0);	// start write
	 wait_for_disk_busy;
	 wait_for_disk_idle;
      end
   endtask

   task check_rd_byte;
      input [31:0] index;
      input [7:0]  v;
      begin
	 if (mmc_card.block0[index] != v) begin
	    success = 0;
	    $display("rd_data[%d] got %x wanted %x", index, mmc_card.block0[index], v);
	 end
      end
   endtask
   
   task check_wr_byte;
      input [31:0] index;
      input [7:0]  v;
      begin
	 if (mmc_card.block2[index] != v) begin
	    success = 0;
	    $display("wr_data[%d] got %x wanted %x", index, mmc_card.block2[index], v);
	 end
      end
   endtask
   
   task check_read;
      begin
	 check_rd_byte(0, 8'h00);
	 check_rd_byte(1, 8'h01);
	 check_rd_byte(2, 8'h02);
	 check_rd_byte(3, 8'h03);
	 check_rd_byte(4, 8'h04);
	 check_rd_byte(5, 8'h05);
	 check_rd_byte(6, 8'h06);
	 check_rd_byte(7, 8'h07);
      end
   endtask	     

   task check_write;
      begin
	 check_wr_byte(0, 8'h22);
	 check_wr_byte(1, 8'h22);
	 check_wr_byte(2, 8'h11);
	 check_wr_byte(3, 8'h11);
	 check_wr_byte(4, 8'h44);
	 check_wr_byte(5, 8'h44);
	 check_wr_byte(6, 8'h33);
	 check_wr_byte(7, 8'h33);
      end
   endtask	     

   initial
     begin
	$timeformat(-9, 0, "ns", 7);
	$dumpfile("run-disk.vcd");
	$dumpvars(0, test_busint);
     end

   initial
     begin
	success = 1;
	
	#1;
	//test_busint.busint.debug_xbus = 1;
	//test_busint.busint.debug_bus = 1;
	//test_busint.busint.debug_detail = 1;

	test_busint.busint.disk.debug = 1;
	test_busint.busint.disk.debug_state = 1;

	test_busint.busint.dram.debug = 1;
	test_busint.busint.dram.debug_decode = 1;

	test_busint.mmc_bd.debug = 1;
	test_busint.mmc_bd.debug_state = 1;

	//test_busint.mmc_bd.mmc.debug = 1;

	clk = 0;
	reset = 0;
	req = 0;
	write = 0;

	#1 reset = 1;
	#500 reset = 0;

	if (0) begin
	   zero_ram;
	   disk_read(32'o0);
	   check_read;
	end

	if (1) begin
	   zero_ram;
	   fill_ram;
	   disk_write(32'o1);
	   check_write;
	end

	$display("TEST DONE");
	
	if (success)
	  $display("** PASSED **");
	else
	  $display("** FAILED! **");
	  
	$finish;
     end

   always
     begin
	#20 clk = 0;
	#20 clk = 1;
     end

`ifdef use_ide
   // ide
   wire [15:0] 	ide_data_bus;
   wire [15:0] 	ide_data_in;
   wire [15:0] 	ide_data_out;
   wire 	ide_dior;
   wire 	ide_diow;
   wire [1:0] 	ide_cs;
   wire [2:0] 	ide_da;

   ide_block_dev ide_bd(
			.clk(clk),
			.reset(reset),
   			.bd_cmd(bd_cmd),
			.bd_start(bd_start),
			.bd_bsy(bd_bsy),
			.bd_rdy(bd_rdy),
			.bd_err(bd_err),
			.bd_addr(bd_addr),
			.bd_data_in(bd_data_in),
			.bd_data_out(bd_data_out),
			.bd_rd(bd_rd),
			.bd_wr(bd_wr),
			.bd_iordy(bd_iordy),
			.bd_state(bd_state),
			
			.ide_data_in(ide_data_in),
			.ide_data_out(ide_data_out),
			.ide_dior(ide_dior),
			.ide_diow(ide_diow),
			.ide_cs(ide_cs),
			.ide_da(ide_da)
			);

   assign ide_data_bus = ~ide_diow ? ide_data_out : 16'bz;

   assign ide_data_in = ide_data_bus;
     
   always @(posedge clk)
     begin
	$pli_ide(ide_data_bus, ide_dior, ide_diow, ide_cs, ide_da);
     end
`endif

`ifdef use_mmc
   // mmc
   wire mmc_cs;
   wire mmc_di;
   wire mmc_do;
   wire mmc_sclk;

   mmc_block_dev mmc_bd(
			.clk(clk),
			.reset(reset),
   			.bd_cmd(bd_cmd),
			.bd_start(bd_start),
			.bd_bsy(bd_bsy),
			.bd_rdy(bd_rdy),
			.bd_err(bd_err),
			.bd_addr(bd_addr),
			.bd_data_in(bd_data_in),
			.bd_data_out(bd_data_out),
			.bd_rd(bd_rd),
			.bd_wr(bd_wr),
			.bd_iordy(bd_iordy),
			.bd_state(bd_state),

			.mmc_cs(mmc_cs),
			.mmc_di(mmc_di),
			.mmc_do(mmc_do),
			.mmc_sclk(mmc_sclk)
			);

`ifdef use_pli_mmc
   always @(posedge clk)
     begin
	$pli_mmc(mmc_cs, mmc_sclk, mmc_di, mmc_do);
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
   
`endif //  `ifdef use_mmc

`ifdef never
   // monitor
   assign sdram_data_in = 0;
   assign sdram_ready = 1;
   assign sdram_done = 1;
   
   always @(posedge clk)
     if (reset)
       begin
       end
     else
       begin
	  if (sdram_req) begin
	     $display("run-disk: sdram read  addr=0x%x data=0x%x", sdram_addr, sdram_data_in);
	  end
	  if (sdram_write) begin
	     $display("run-disk: sdram write addr=0x%x data=0x%x", sdram_addr, sdram_data_out);
	  end
       end
`endif
   
endmodule // test
