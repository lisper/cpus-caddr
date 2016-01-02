//
//
//

//`define mmc_pli
`define mmc_model
`define lpddr_model
`define sim_ps
//`define sim_ns
//`define waves
//`define debug_pc

module top_niox_tb;

   reg 	  sysclk;
   reg 	  switch;

   wire   usb_txd;
   wire   usb_rxd;
   wire [4:0] led;
   reg       ps2_clk;
   reg       ps2_data;
   wire       ms_ps2_clk;
   wire       ms_ps2_data;
   wire       vga_hsync;
   wire       vga_vsync;
   wire       vga_r;
   wire       vga_g;
   wire       vga_b;
   wire       mmc_cs;
   wire       mmc_di;
   wire       mmc_do;
   wire       mmc_sclk;
   wire [15:0] mcb3_dram_dq;
   wire [12:0] mcb3_dram_a;
   wire [1:0]  mcb3_dram_ba;
   wire        mcb3_dram_cke;
   wire        mcb3_dram_ras_n;
   wire        mcb3_dram_cas_n;
   wire        mcb3_dram_we_n;
   wire        mcb3_dram_dm;
   wire        mcb3_dram_udqs;
   wire        mcb3_rzq;
   wire        mcb3_dram_udm;
   wire        mcb3_dram_dqs;
   wire        mcb3_dram_ck;
   wire        mcb3_dram_ck_n;
   wire [3:0]  tmds;
   wire [3:0]  tmdsb;
   

   top_niox top(
		.usb_txd(usb_txd),
		.usb_rxd(usb_rxd),
		.sysclk(sysclk),
		.led(led),
		.ps2_clk(ps2_clk),
		.ps2_data(ps2_data),
		.ms_ps2_clk(ms_ps2_clk),
		.ms_ps2_data(ms_ps2_data),
		.vga_hsync(vga_hsync),
		.vga_vsync(vga_vsync),
		.vga_r(vga_r),
		.vga_g(vga_g),
		.vga_b(vga_b),
		.mmc_cs(mmc_cs),
		.mmc_di(mmc_di),
		.mmc_do(mmc_do),
		.mmc_sclk(mmc_sclk),
		.switch(switch),
		.mcb3_dram_dq(mcb3_dram_dq),
		.mcb3_dram_a(mcb3_dram_a),
		.mcb3_dram_ba(mcb3_dram_ba),
		.mcb3_dram_cke(mcb3_dram_cke),
		.mcb3_dram_ras_n(mcb3_dram_ras_n),
		.mcb3_dram_cas_n(mcb3_dram_cas_n),
		.mcb3_dram_we_n(mcb3_dram_we_n),
		.mcb3_dram_dm(mcb3_dram_dm),
		.mcb3_dram_udqs(mcb3_dram_udqs),
		.mcb3_rzq(mcb3_rzq),
		.mcb3_dram_udm(mcb3_dram_udm),
		.mcb3_dram_dqs(mcb3_dram_dqs),
		.mcb3_dram_ck(mcb3_dram_ck),
		.mcb3_dram_ck_n(mcb3_dram_ck_n),
		.tmds(tmds),
		.tmdsb(tmdsb)
		);

`ifdef lpddr_model
   lpddr_model_c3 u_mem3(
      .Dq    (mcb3_dram_dq),
      .Dqs   ({mcb3_dram_udqs,mcb3_dram_dqs}),
      .Addr  (mcb3_dram_a),
      .Ba    (mcb3_dram_ba),
      .Clk   (mcb3_dram_ck),
      .Clk_n (mcb3_dram_ck_n),
      .Cke   (mcb3_dram_cke),
      .Cs_n  (1'b0),
      .Ras_n (mcb3_dram_ras_n),
      .Cas_n (mcb3_dram_cas_n),
      .We_n  (mcb3_dram_we_n),
      .Dm    ({mcb3_dram_udm,mcb3_dram_dm})
      );

   PULLDOWN rzq_pulldown (.O(mcb3_rzq));
`endif

`ifdef sim_ps
   always
     begin
	#10000; sysclk = 0; // ps
	#10000; sysclk = 1;
     end
`endif

`ifdef sim_ns
   always
     begin
	#10; sysclk = 0; // ns
	#10; sysclk = 1;
     end
`endif

`ifdef debug_pc
   always @(posedge top.cpu.clk)
     begin
	if (top.reset)
	  begin
//	     $display("reset %t", $time);
	  end
	else
	  if (top.cpu.cpu.pc_en)
	    begin
	       $display("\npc %x %t", top.cpu.cpu.pc, $time);

	       if (top.cpu.cpu.is_cmpgeui)
		 begin
		    $display("is_cmpgeui %b, cmp_ge %b alu_op_cmp %b alu_op_signed %b",
			     top.cpu.cpu.is_cmpgeui,
			     top.cpu.cpu.cmp_ge,
			     top.cpu.cpu.alu_op_cmp,
		    	     top.cpu.cpu.alu_op_signed);
		    $display("is_imm %b alu_operi %x is_ophi %b IMM16 %x",
			     top.cpu.cpu.is_imm,
			     top.cpu.cpu.alu_operi,
			     top.cpu.cpu.is_ophi,
		    	     top.cpu.cpu.IMM16);
		    $display("alu: opera %x operb %x result %x result_zero %b result_lt %b",
			     top.cpu.cpu.alu_opera,
			     top.cpu.cpu.alu_operb, 
			     top.cpu.cpu.alu_result,
			     top.cpu.cpu.alu_result_zero,
			     top.cpu.cpu.alu_result_lt);
		 end
	    end
     end
`endif
   
   initial
     begin
//	$timeformat(-9, 0, "ns", 7);
	$display("start...");
	sysclk = 0;
	switch = 0;

//	#1;
//	top_niox_tb.top.mmc_bd.debug = 2;
//	top_niox_tb.top.cpu.bus.disk.debug = 2;
	
//	#50000000;
//	#10000000;
//	#75000;
//	$finish;
     end

`ifdef waves
   integer dumping, start_waves, stop_waves;
   
   initial
     begin
	$dumpfile("top_niox_tb.vcd");
	$dumpvars(0, top_niox_tb);

	//start_waves = 10641000;
	//start_waves = 666444;
	start_waves = 15833000;
	stop_waves = 17100000;
     end

   always
     begin
	if ($time == 1)
	  begin
	     $dumpoff;
	     dumping = 0;
	     $display("DUMPING OFF");
	  end
	
	if (stop_waves > 0 && $time >= stop_waves && dumping == 1)
	  begin
	     $dumpoff;
	     dumping = 2;
	     $display("DUMPING OFF");
	  end
	
	if (start_waves > 0 && $time >= start_waves && dumping == 0)
	  begin
	     $dumpon;
	     dumping = 1;
	     $display("DUMPING ON");
	  end

	#1;
     end
`endif

`ifdef mmc_pli   
   always @(posedge sysclk)
     begin
	$pli_mmc(mmc_cs, mmc_sclk, mmc_di, mmc_do);
     end
`endif

`ifdef mmc_model
   mmc_model mmc_card(
		      .spiClk(mmc_sclk),
		      .spiDataIn(mmc_do),
		      .spiDataOut(mmc_di),
		      .spiCS_n(mmc_cs)
		      );
`endif
   
endmodule // top_niox_tb
