/*
 * test disk controller
 */

`define debug
`define debug_state
`define debug_detail
`define debug_detail_delay
`define DBG_DLY #1

//`define use_ide
`define use_mmc
  
`include "../rtl/busint.v"
`include "../rtl/xbus-sram.v"
`include "../rtl/xbus-disk.v"
`include "../rtl/xbus-tv.v"
`include "../rtl/xbus-io.v"
`include "../rtl/xbus-unibus.v"
`include "../rtl/ide_block_dev.v"
`include "../rtl/mmc_block_dev.v"
`include "../rtl/ide.v"
`include "../rtl/mmc.v"

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

   busint busint(.mclk(clk),
		 .reset(reset),
		 .addr(addr),
		 .busin(busin),
		 .busout(busout),
		 .spyin(spyin),
		 .spyout(spyout), 
		 .req(req),
		 .ack(ack),
		 .write(write), 
		 .load(load),
		 .interrupt(interrupt),

		 .sdram_addr(), .sdram_data_in(), .sdram_data_out(),
		 .sdram_req(), .sdram_ready(), .sdram_write(), .sdram_done(),
		 
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

		 .kb_data(), .kb_ready(),
		 .ms_x(), .ms_y(), .ms_button(), .ms_ready(),
		 .promdisable(), .disk_state(), .bus_state()
		 );


   task wait_for_bi_done;
      begin
	 while (ack == 1'b0) @(posedge clk);
	 @(posedge clk);
      end

   endtask

   task bus_read;
      input [21:0] a;

      begin
	 @(posedge clk);
	 write = 0;
 	 req = 1;
	 addr = a;
	 wait_for_bi_done;
	 $display("read: addr %o in %x out %x, %t",
		  addr, busin, busout, $time);
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

   initial
     begin
	$timeformat(-9, 0, "ns", 7);
	$dumpfile("run-disk.vcd");
	$dumpvars(0, test_busint);
     end

   initial
     begin
	test_busint.busint.disk.debug = 1;
	test_busint.busint.dram.debug = 1;
	
	clk = 0;
	reset = 0;
	req = 0;
	write = 0;

	#1 reset = 1;
	#500 reset = 0;

	// write dram - command list
	bus_write(22'o22, 32'o1001);
	#100
	bus_write(22'o23, 32'o4000);

	// program disk controller
	bus_read(22'o17377774);
	bus_read(22'o17377774);
	bus_read(22'o17377774);
	bus_write(22'o17377775, 32'o22);	// load clp
	bus_write(22'o17377777, 32'o0);		// start read

	#9000000 $finish;
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

			.mmc_cs(mmc_cs),
			.mmc_di(mmc_di),
			.mmc_do(mmc_do),
			.mmc_sclk(mmc_sclk)
			);

   always @(posedge clk)
     begin
	$pli_mmc(mmc_cs, mmc_sclk, mmc_di, mmc_do);
     end
`endif

   
endmodule // test
