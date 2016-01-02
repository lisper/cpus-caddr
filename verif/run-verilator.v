/*
 */

//`define debug_bus


//`define debug_vcd
`define debug
`define DBG_DLY

//`define build_debug_s3
`define build_debug_lx45
//`define debug_patch_disk_copy
`define debug_vmem
  
//`include "defs.v"
`include "rtl.v"

`timescale 1ns / 1ns

`ifdef use_ide
 `include "wrap_ide.v"
`endif

`ifdef use_mmc
 `include "wrap_mmc.v"
`endif

module test;
   reg ext_osc;
   reg sysclk;
   reg reset/* verilator public_flat_rw @(clk1x) */;
   reg interrupt;

   // controlled by rc circuit at power up
   reg boot/* verilator public_flat_rw @(clk1x) */;

   reg [15:0]  spyin;
   wire [15:0] spyout;
   wire        dbread, dbwrite;
   wire [3:0]  eadr;

   wire [15:0] 	ide_data_bd2ide;
   wire [15:0] 	ide_data_ide2bd;
   wire 	ide_dior;
   wire 	ide_diow;
   wire [1:0] 	ide_cs;
   wire [2:0] 	ide_da;

   wire 	halt;

   wire [13:0] 	 mcr_addr;
   wire [48:0] 	 mcr_data_out;
   wire [48:0] 	 mcr_data_in;
   wire 	 mcr_ready;
   wire 	 mcr_write;
   wire 	 mcr_done;

   wire [21:0] 	 sdram_addr;
   wire [31:0] 	 sdram_data_out;
   wire [31:0] 	 sdram_data_in;
   wire 	 sdram_ready;
   wire 	 sdram_req;
   wire 	 sdram_write;
   wire 	 sdram_done;

   wire [14:0] 	 vram_cpu_addr;
   wire [31:0] 	 vram_cpu_data_out;
   wire [31:0] 	 vram_cpu_data_in;
   wire 	 vram_cpu_req;
   wire 	 vram_cpu_ready;
   wire 	 vram_cpu_write;
   wire 	 vram_cpu_done;

   wire [14:0] 	 vram_vga_addr;
   wire [31:0] 	 vram_vga_data_out;
   wire 	 vram_vga_req;
   wire 	 vram_vga_ready;

   wire [1:0] 	 bd_cmd;	/* generic block device interface */
   wire 	 bd_start;
   wire 	 bd_bsy;
   wire 	 bd_rdy;
   wire 	 bd_err;
   wire [23:0] 	 bd_addr;
   wire [15:0] 	 bd_data_cpu2bd;
   wire [15:0] 	 bd_data_bd2cpu;
   wire 	 bd_rd;
   wire 	 bd_wr;
   wire 	 bd_iordy;

   wire [13:0] 	 pc;
   wire [5:0] 	 state;
   wire 	 machrun;
   wire 	 prefetch;
   wire 	 fetch;
   wire [4:0] 	 disk_state;
   wire [3:0] 	 bus_state;
   wire [3:0] 	 rc_state;

   wire [17:0] 	 sram_a;
   wire 	 sram_oe_n, sram_we_n;
   wire [15:0] 	 sram1_in;
   wire [15:0] 	 sram1_out;
   wire [15:0] 	 sram2_in;
   wire [15:0] 	 sram2_out;
   wire 	 sram1_ce_n, sram1_ub_n, sram1_lb_n;
   wire 	 sram2_ce_n, sram2_ub_n, sram2_lb_n;

   wire [15:0] 	 kb_data;
   wire 	 kb_ready;
   
   wire [11:0] 	 ms_x, ms_y;
   wire [2:0] 	 ms_button;
   wire 	 ms_ready;

//
   reg [1:0] slow_ctr;
   wire      clk1x/* verilator public_flat_rw @(clk50) */;
   wire      clk50/* verilator public_flat_rw @(clk100) */;
   wire      clk100/* verilator public_flat_rw @(pixclk) */;
   wire      pixclk/* verilator public_flat_rw @(clk100) */;
   
   initial
     slow_ctr = 2'b0;

`ifdef use_verilog_clocks
   always @(posedge ext_osc)
     sysclk <= ~sysclk;
   
   always @(posedge sysclk)
       slow_ctr <= slow_ctr + 1;

   assign clk1x = slow_ctr[1];
   assign clk50 = ~slow_ctr[0];
   assign clk100 = sysclk;
//    
`endif
   
//
   integer 	 cycles;

`ifdef use_iologger
   reg [63:0] 	 iologfile;

   task iologger;
      input [31:0] rw;
      input [21:0] addr;
      input [31:0] bus;
      
      begin
	 if (rw == 0)
	   $fdisplay(iologfile, "%0d %d %o P %o %o", cycles, $time, cpu.lpc, addr, bus);
	 if (rw == 0)
	   $fdisplay(iologfile, "-----");
	 if (rw == 1)
	   $fdisplay(iologfile, "%0d %d %o R %o %o", cycles, $time, cpu.lpc, addr, bus);
	 if (rw == 2)
	   $fdisplay(iologfile, "%0d %d %o W %o %o", cycles, $time, cpu.lpc, addr, bus);
	 if (rw == 3)
	   $fdisplay(iologfile, "%0d %d %o I %o %o", cycles, $time, cpu.lpc, addr, bus);
	 if (rw == 4)
	   $fdisplay(iologfile, "%0d %d %o D %o %o", cycles, $time, cpu.lpc, addr, bus);
	 if (rw == 10)
	   $fdisplay(iologfile, "%0d %d %o S %o %o", cycles, $time, cpu.lpc, addr, bus);
	 if (rw == 11 && cpu.state == 6'b001000/*state_write*/)
	   $fdisplay(iologfile, "%0d %d %o T %o %o", cycles, $time, cpu.lpc, addr, bus);
      end
   endtask

   initial
     begin
	iologfile = $fopen("iologfile.txt", "w");
     end
`endif
   
   always @(posedge cpu.clk)
     begin
	if (cpu.state == 6'b100000 && ~cpu.iwrited && ~cpu.inop)
	  begin
 `ifdef use_iologger
	     test.iologger(32'd0, {8'b0, cpu.lpc}, 0);
 `endif
	     cycles = cycles + 1;
	  end
     end


   // cpu
   caddr cpu (.clk(clk1x),
	      .ext_int(interrupt),
	      .ext_reset(reset),
	      .ext_boot(boot),
	      .ext_halt(halt),

	      .spy_in(spyin),
	      .spy_out(spyout),
	      .dbread(dbread),
	      .dbwrite(dbwrite),
	      .eadr(eadr),

	      .pc_out(pc),
	      .state_out(state),
	      .machrun_out(machrun),
	      .prefetch_out(prefetch),
	      .fetch_out(fetch),
	      .disk_state_out(disk_state),
	      .bus_state_out(bus_state),

	      .mcr_addr(mcr_addr),
	      .mcr_data_out(mcr_data_out),
	      .mcr_data_in(mcr_data_in),
	      .mcr_ready(mcr_ready),
	      .mcr_write(mcr_write),
	      .mcr_done(mcr_done),

	      .sdram_addr(sdram_addr),
	      .sdram_data_in(sdram_data_in),
	      .sdram_data_out(sdram_data_out),
	      .sdram_req(sdram_req),
	      .sdram_ready(sdram_ready),
	      .sdram_write(sdram_write),
	      .sdram_done(sdram_done),
      
	      .vram_addr(vram_cpu_addr),
	      .vram_data_in(vram_cpu_data_in),
	      .vram_data_out(vram_cpu_data_out),
	      .vram_req(vram_cpu_req),
	      .vram_ready(vram_cpu_ready),
	      .vram_write(vram_cpu_write),
	      .vram_done(vram_cpu_done),

	      .bd_cmd(bd_cmd),
	      .bd_start(bd_start),
	      .bd_bsy(bd_bsy),
	      .bd_rdy(bd_rdy),
	      .bd_err(bd_err),
	      .bd_addr(bd_addr),
	      .bd_data_in(bd_data_bd2cpu),
	      .bd_data_out(bd_data_cpu2bd),
	      .bd_rd(bd_rd),
	      .bd_wr(bd_wr),
	      .bd_iordy(bd_iordy),
	      
	      .kb_data(kb_data),
	      .kb_ready(kb_ready),
	      .ms_x(ms_x),
	      .ms_y(ms_y),
	      .ms_button(ms_button),
	      .ms_ready(ms_ready));

//   assign vram_cpu_ready = 1'b1;

`ifdef use_ram_controller   
   
`ifdef real_rc
   ram_controller
`endif
`ifdef debug_rc
   debug_ram_controller
`endif
`ifdef fast_rc
   fast_ram_controller
`endif
`ifdef slow_rc
   slow_ram_controller
`endif
`ifdef min_rc
   min_ram_controller
`endif
`ifdef pipe_rc
   pipe_ram_controller
`endif
`ifdef lx45_rc
   lx45_ram_controller
`endif
		  rc
		     (.clk(clk100),
		      .vga_clk(clk50),
		      .cpu_clk(clk1x),
		      .reset(reset),
		      .prefetch(prefetch),
		      .fetch(fetch),
		      .machrun(machrun),
		      .state_out(rc_state),
		      
		      .mcr_addr(mcr_addr),
		      .mcr_data_out(mcr_data_in),
		      .mcr_data_in(mcr_data_out),
		      .mcr_ready(mcr_ready),
		      .mcr_write(mcr_write),
		      .mcr_done(mcr_done),

		      .sdram_addr(sdram_addr),
		      .sdram_data_in(sdram_data_out),
		      .sdram_data_out(sdram_data_in),
		      .sdram_req(sdram_req),
		      .sdram_ready(sdram_ready),
		      .sdram_write(sdram_write),
		      .sdram_done(sdram_done),
      
		      .vram_cpu_addr(vram_cpu_addr),
		      .vram_cpu_data_in(vram_cpu_data_out),
		      .vram_cpu_data_out(vram_cpu_data_in),
		      .vram_cpu_req(vram_cpu_req),
		      .vram_cpu_ready(vram_cpu_ready),
		      .vram_cpu_write(vram_cpu_write),
		      .vram_cpu_done(vram_cpu_done),
      
		      .vram_vga_addr(vram_vga_addr),
		      .vram_vga_data_out(vram_vga_data_out),
		      .vram_vga_req(vram_vga_req),
		      .vram_vga_ready(vram_vga_ready),
      
`ifndef lx45_rc
		      .sram_a(sram_a),
		      .sram_oe_n(sram_oe_n),
		      .sram_we_n(sram_we_n),
		      .sram1_in(sram1_in),
		      .sram1_out(sram1_out),
		      .sram1_ce_n(sram1_ce_n),
		      .sram1_ub_n(sram1_ub_n),
		      .sram1_lb_n(sram1_lb_n),
		      .sram2_in(sram2_in),
		      .sram2_out(sram2_out),
		      .sram2_ce_n(sram2_ce_n),
		      .sram2_ub_n(sram2_ub_n),
		      .sram2_lb_n(sram2_lb_n)
`endif
		      );
`else
   assign mcr_ready = 1;
`endif
   
   wire 	 vga_red, vga_blu, vga_grn, vga_hsync, vga_vsync;

`ifdef use_vga_controller
   vga_display vga (.clk(clk50),
		    .pixclk(pixclk),
		    .reset(reset),

		    .vram_addr(vram_vga_addr),
		    .vram_data(vram_vga_data_out),
		    .vram_req(vram_vga_req),
		    .vram_ready(vram_vga_ready),
      
		    .vga_red(vga_red),
		    .vga_blu(vga_blu),
		    .vga_grn(vga_grn),
		    .vga_hsync(vga_hsync),
		    .vga_vsync(vga_vsync)
		    );
`endif
   
`ifdef show_vga
   import "DPI-C" function void dpi_vga_init(input integer h,
					     input integer v);

   import "DPI-C" function void dpi_vga_display(input integer vsync,
						input integer hsync,
    						input integer pixel);

   wire [31:0] 	 pxd;
   
   initial
     begin 
	dpi_vga_init(1280, 1024);
     end
   
   assign pxd = { 24'b0,
		  vga_red, vga_red, vga_red,
		  vga_blu, vga_blu,
		  vga_grn, vga_grn, vga_grn };
   
   always @(posedge clk50)
     dpi_vga_display({31'b0, vga_vsync}, {31'b0, vga_hsync}, pxd);

`endif
   
   //---------------------------------------------------------------
   
   assign 	halt = 0;
   
   assign      eadr = 4'b0;
   assign      dbread = 0;
   assign      dbwrite = 0;
   assign      spyin = 0;

   assign      kb_ready = 0;
   assign      kb_data = 16'b0;
   
   assign      ms_ready = 0;
   assign      ms_x = 12'b0;
   assign      ms_y = 12'b0;
   assign      ms_button = 3'b0;

`ifdef use_ide
   // ide
   ide_block_dev ide_bd(
			.clk(clk1x),
			.reset(reset),
   			.bd_cmd(bd_cmd),
			.bd_start(bd_start),
			.bd_bsy(bd_bsy),
			.bd_rdy(bd_rdy),
			.bd_err(bd_err),
			.bd_addr(bd_addr),
			.bd_data_in(bd_data_cpu2bd),
			.bd_data_out(bd_data_bd2cpu),
			.bd_rd(bd_rd),
			.bd_wr(bd_wr),
			.bd_iordy(bd_iordy),

			.ide_data_in(ide_data_ide2bd),
			.ide_data_out(ide_data_bd2ide),
			.ide_dior(ide_dior),
			.ide_diow(ide_diow),
			.ide_cs(ide_cs),
			.ide_da(ide_da)
			);

   wrap_ide wrap_ide(.clk(clk1x),
		     .ide_data_in(ide_data_bd2ide),
		     .ide_data_out(ide_data_ide2bd),
		     .ide_dior(ide_dior),
		     .ide_diow(ide_diow),
		     .ide_cs(ide_cs),
		     .ide_da(ide_da));
`endif
   
`ifdef use_mmc
   // mmc
   wire mmc_cs, mmc_di, mmc_do, mmc_sclk;

   mmc_block_dev mmc_bd(
			.clk(clk50),
			.reset(reset),
   			.bd_cmd(bd_cmd),
			.bd_start(bd_start),
			.bd_bsy(bd_bsy),
			.bd_rdy(bd_rdy),
			.bd_err(bd_err),
			.bd_addr(bd_addr),
			.bd_data_in(bd_data_cpu2bd),
			.bd_data_out(bd_data_bd2cpu),
			.bd_rd(bd_rd),
			.bd_wr(bd_wr),
			.bd_iordy(bd_iordy),

			.mmc_cs(mmc_cs),
			.mmc_di(mmc_di),
			.mmc_do(mmc_do),
			.mmc_sclk(mmc_sclk)
			);

   wrap_mmc mmc_wrap(.clk(clk1x),
		     .mmc_cs(mmc_cs),
		     .mmc_di(mmc_do),
		     .mmc_do(mmc_di),
		     .mmc_sclk(mmc_sclk));
`endif
   
`ifdef use_s3board_ram
   ram_s3board ram(.ram_a(sram_a),
		   .ram_oe_n(sram_oe_n),
		   .ram_we_n(sram_we_n),
		   .ram1_in(sram1_out),
		   .ram1_out(sram1_in),
		   .ram1_ce_n(sram1_ce_n),
		   .ram1_ub_n(sram1_ub_n),
		   .ram1_lb_n(sram1_lb_n),
		   .ram2_in(sram2_out),
		   .ram2_out(sram2_in),
		   .ram2_ce_n(sram2_ce_n),
		   .ram2_ub_n(sram2_ub_n),
		   .ram2_lb_n(sram2_lb_n));
`endif

`ifdef use_debug_bd
   debug_block_dev debug_bd(
			    .clk(clk50),
			    .reset(reset),
   			    .bd_cmd(bd_cmd),
			    .bd_start(bd_start),
			    .bd_bsy(bd_bsy),
			    .bd_rdy(bd_rdy),
			    .bd_err(bd_err),
			    .bd_addr(bd_addr),
			    .bd_data_in(bd_data_cpu2bd),
			    .bd_data_out(bd_data_bd2cpu),
			    .bd_rd(bd_rd),
			    .bd_wr(bd_wr),
			    .bd_iordy(bd_iordy)
			    );
`endif
   
endmodule
