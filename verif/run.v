/*
 */

//`define patch_rw_test // test rw
`define debug_vcd
`define debug
//`define DBG_DLY #1
`define DBG_DLY #0

`define debug_xbus
//`define debug_vmem

`include "rtl.v"

`include "ram_s3board.v"
  
`timescale 1ns / 1ns

module test;
   reg clk;
   reg clk2x;
   reg reset;
   reg interrupt;

   // controlled by rc circuit at power up
   reg boot;

   reg [15:0] spyin;
   wire [15:0] spyout;
   wire        dbread, dbwrite;
   wire [3:0]  eadr;

   wire [15:0] 	ide_data_bus;
   wire [15:0] 	ide_data_in;
   wire [15:0] 	ide_data_out;
   wire 	ide_dior;
   wire 	ide_diow;
   wire [1:0] 	ide_cs;
   wire [2:0] 	ide_da;

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

   wire 	 prefetch;
   wire 	 fetch;
   
   wire [17:0] 	 sram_a;
   wire 	 sram_oe_n, sram_we_n;
   /* verilator lint_off UNOPTFLAT */
   wire [15:0] 	 sram1_io;
   wire [15:0] 	 sram2_io;
   /* verilator lint_on UNOPTFLAT */
   wire 	 sram1_ce_n, sram1_ub_n, sram1_lb_n;
   wire 	 sram2_ce_n, sram2_ub_n, sram2_lb_n;

   caddr cpu (.clk(clk),
	      .ext_int(interrupt),
	      .ext_reset(reset),
	      .ext_boot(boot),
	      .ext_halt(halt),
	      .spy_in(spyin),
	      .spy_out(spyout),
	      .dbread(dbread),
	      .dbwrite(dbwrite),
	      .eadr(eadr),

	      .prefetch_out(prefetch),
	      .fetch_out(fetch),
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

	      .ide_data_in(ide_data_in),
	      .ide_data_out(ide_data_out),
	      .ide_dior(ide_dior),
	      .ide_diow(ide_diow),
	      .ide_cs(ide_cs),
	      .ide_da(ide_da));

   /*debug_*/ram_controller rc
		     (.clk(clk),
		      .clk2x(clk2x),
		      .reset(reset),
		      .prefetch(prefetch),
		      .fetch(fetch),
		      
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
		      .vram_vga_data_out(vram_vga_data_in),
		      .vram_vga_req(vram_vga_req),
		      .vram_vga_ready(vram_vga_ready),
      
		      .sram_a(sram_a),
		      .sram_oe_n(sram_oe_n),
		      .sram_we_n(sram_we_n),
		      .sram1_io(sram1_io),
		      .sram1_ce_n(sram1_ce_n),
		      .sram1_ub_n(sram1_ub_n),
		      .sram1_lb_n(sram1_lb_n),
		      .sram2_io(sram2_io),
		      .sram2_ce_n(sram2_ce_n),
		      .sram2_ub_n(sram2_ub_n),
		      .sram2_lb_n(sram2_lb_n)
		      );

   assign vram_vga_addr = 0;
   
   ram_s3board ram(.ram_a(sram_a),
		   .ram_oe_n(sram_oe_n),
		   .ram_we_n(sram_we_n),
		   .ram1_io(sram1_io),
		   .ram1_ce_n(sram1_ce_n),
		   .ram1_ub_n(sram1_ub_n),
		   .ram1_lb_n(sram1_lb_n),
		   .ram2_io(sram2_io),
		   .ram2_ce_n(sram2_ce_n),
		   .ram2_ub_n(sram2_ub_n),
		   .ram2_lb_n(sram2_lb_n));
		   
   integer     addr;
   integer     debug_level;
   integer     dumping;
   integer     cycles;
   integer     max_cycles;
     
   assign      eadr = 4'b0;
   assign      dbread = 0;
   assign      dbwrite = 0;

   reg [1023:0] arg;
   integer 	n;

   initial
     begin
	$timeformat(-9, 0, "ns", 7);

`ifdef debug_log
`else
`ifdef __CVER__
	$nolog;
`endif
`endif

	debug_level = 1;
	dumping = 0;
	cycles = 0;
	max_cycles = 0;

`ifdef debug_vcd
	$dumpfile("caddr.vcd");
	$dumpvars(0, test);
	dumping = 1;
`endif

`ifdef __ICARUS__
       n = $value$plusargs("cycles=%d", arg);
	if (n > 0)
	  begin
	     max_cycles = arg;
	     $display("arg cycles %d", max_cycles);
	  end
`endif       
`ifdef __CVER__
       n = $scan$plusargs("cycles=", arg);
	if (n > 0)
	  begin
	     n = $sscanf(arg, "%d", max_cycles);
	     $display("arg cycles %d", max_cycles);
	  end
`endif
     end

   initial
     begin
	clk = 0;
	clk2x = 0;
	interrupt = 0;
	reset = 0;
	spyin = 0;

	#1 begin
	   reset = 1;
	   boot = 0;

        end

//`define patch_vram_test
`ifdef patch_vram_test
	cpu.i_AMEM.ram[10'o65] = 32'o77051763;
	cpu.i_AMEM.ram[10'o66] = 32'o77051764;

	cpu.i_MMEM.ram[10'o02] = 32'o01234567;
	cpu.i_MMEM.ram[10'o03] = 32'hffffffff;

	cpu.i_VMEM0.ram[11'o3742] = 5'o00;
	cpu.i_VMEM1.ram[10'o0023] = 24'o60036123;
`endif

`define patch_rw_test	
`ifdef patch_rw_test

	cpu.i_AMEM.ram[10'o2] = 32'o400000;
	cpu.i_AMEM.ram[10'o4] = 32'o401000;
	cpu.i_AMEM.ram[10'o6] = 32'o402000;
	cpu.i_AMEM.ram[10'o10] = 32'o403000;
	cpu.i_AMEM.ram[10'o436] = 32'o403447;

	cpu.i_MMEM.ram[10'o2] = 32'o400000;
	cpu.i_MMEM.ram[10'o4] = 32'o401000;
	cpu.i_MMEM.ram[10'o6] = 32'o402000;
	cpu.i_MMEM.ram[10'o10] = 32'o403000;
	cpu.i_MMEM.ram[10'o436] = 32'o403447;

	cpu.i_AMEM.ram[10'o20] = 32'o00000001;
	cpu.i_MMEM.ram[10'o20] = 32'o00000001;
	
	cpu.i_AMEM.ram[10'o21] = 32'o01234567;
	cpu.i_MMEM.ram[10'o21] = 32'o01234567;
	
	cpu.i_AMEM.ram[10'o22] = 32'hffffffff;
	cpu.i_MMEM.ram[10'o22] = 32'hffffffff;

	cpu.i_VMEM0.ram[11'o20] = 5'o31;
	cpu.i_VMEM1.ram[10'o1447] = 24'o63200254;

	cpu.i_VMEM1.ram[10'o1440] = 24'o03200254;
	cpu.i_VMEM1.ram[10'o1442] = 24'o23200254;
	cpu.i_VMEM1.ram[10'o1444] = 24'o43200254;
	cpu.i_VMEM1.ram[10'o1446] = 24'o63200254;
`endif

	ram.ram1.ram_h[0] = 0;
	ram.ram2.ram_l[0] = 0;
		
	#240 boot = 1;

	#10 reset = 0;
	#10 boot = 0;
     end

   // 100mhz clock
   always
     begin
	#5 clk2x = 0;
	#5 clk2x = 1;
     end

   // 50mhz clock
//   always @(posedge clk2x)
//     clk <= ~clk;
   always
     begin
	#10 clk = 0;
	#10 clk = 1;
     end

   always @(posedge cpu.clk)
     begin
	if (cpu.state == 5'b00001)
	  cycles = cycles + 1;

	case (cpu.state)
  5'b00000: $display("%0o %o reset  lc=%o; %t",cpu.lpc,cpu.ir,cpu.lc,$time);
  5'b00001: $display("%0o %o decode lc=%o; %t",cpu.lpc,cpu.ir,cpu.lc,$time);
  5'b00010: $display("%0o %o exec   lc=%o; %t",cpu.lpc,cpu.ir,cpu.lc,$time);
  5'b00100: $display("%0o %o write  lc=%o; %t",cpu.lpc,cpu.ir,cpu.lc,$time);
  5'b01000: $display("%0o %o fetch  lc=%o; %t",cpu.lpc,cpu.ir,cpu.lc,$time);
  5'b10000: $display("%0o %o wait   lc=%o; %t",cpu.lpc,cpu.ir,cpu.lc,$time);
	endcase

`ifdef xxx
	if (cycles > 25 && (cpu.lpc > 7 && cpu.lpc < 14'o50) &&
	    (cpu.npc < 14'o50) && cpu.promdisable == 0)
	  begin
	     $display("in microcode error routine; lpc %o", cpu.lpc);
	     $finish;
	  end
`endif

	if (max_cycles > 0 && cycles >= max_cycles)
	  begin
	     $display("maximum cycles count (%0d) exceeded", max_cycles);
	     $finish;
	  end
     end

   always @(posedge cpu.clk)
     #1 if (debug_level == 1 && cpu.state == 5'b00100)
       begin
	  $display("%0o %o A=%x M=%x N%b R=%x LC=%x",
		   cpu.lpc, cpu.ir,
		   cpu.a, cpu.m, cpu.n, cpu.r, cpu.lc);
	  $display("vma: vma %0o ob %0o alu %0o",
		   cpu.vma, cpu.ob, cpu.alu);

//	  if (dumping)
//	    begin
//	       $dumpoff;
//	       dumping = 0;
//	       $display("dumping: off");
//	    end

//	  if (cpu.promdisable == 1 && cpu.npc == 14'o23664/*21116*/)
//	    begin
//	       debug_level = 3;
////	       cycles = 0;
////	       max_cycles = 10000;
//	    end
     end 
   
   always @(posedge cpu.clk)
     #1 if (debug_level == 2 && cpu.state == 5'b00001)
       begin
	if (cpu.state == 5'b00001) $display("-----");

	$display("LPC=%o PC=%o NPC=%o PCS=%b%b IR=%o",
		 cpu.lpc, cpu.pc, cpu.npc, cpu.pcs1, cpu.pcs0, cpu.ir);
	$display("     A=%x M=%x N=%b Q=%x R=%x L=%x",
		 cpu.a, cpu.m, cpu.n, cpu.q, cpu.r, cpu.l);
     end 
   
   always @(posedge cpu.clk)
     #1 if (debug_level == 3)
       begin
`ifdef debug_vcd
	  if (dumping == 0)
	    begin
	       dumping = 1;
	       $dumpon;
	       $dumpall;
	       $display("dumping: on");
	    end
`endif

	  if (1)
	    begin
	       cpu.i_AMEM.debug = 1;
	       cpu.i_MMEM.debug = 1;
	    end

//if (cpu.lc == 26'o077677030) $finish;
	      
	if (cpu.state == 5'b00001) $display("-----");

	case (cpu.state)
  5'b00000: $display("%0o %o reset  lc=%o; %t",cpu.lpc,cpu.ir,cpu.lc,$time);
  5'b00001: $display("%0o %o decode lc=%o; %t",cpu.lpc,cpu.ir,cpu.lc,$time);
  5'b00010: $display("%0o %o exec   lc=%o; %t",cpu.lpc,cpu.ir,cpu.lc,$time);
  5'b00100: $display("%0o %o write  lc=%o; %t",cpu.lpc,cpu.ir,cpu.lc,$time);
  5'b01000: $display("%0o %o fetch  lc=%o; %t",cpu.lpc,cpu.ir,cpu.lc,$time);
  5'b10000: $display("%0o %o wait   lc=%o; %t",cpu.lpc,cpu.ir,cpu.lc,$time);
	endcase
	  
//	$display("     A=%x M=%x, N=%x, Q=%x s=%b%b%b%b%b R=%x, L=%x",
//		 cpu.a, cpu.m, cpu.n, cpu.q,
//		 cpu.s4, cpu.s3, cpu.s2, cpu.s1, cpu.s0, cpu.r, cpu.l);

	$display("     A=%o M=%o, N=%x, Q=%o s=%b%b%b%b%b",
		 cpu.a, cpu.m, cpu.n, cpu.q,
		 cpu.s4, cpu.s3, cpu.s2, cpu.s1, cpu.s0);

	$display("     conds=%b, jcond=%b, jfalse=%b (%b), npc %o pcs=%b",
		 cpu.conds, cpu.jcond, cpu.jfalse, cpu.jfalse & ~cpu.jcond,
		 cpu.npc, {cpu.pcs1, cpu.pcs0});

	$display("     a_latch=%o m.latched=%o, aeqm %b %b",
		 cpu.a_latch, cpu.mmem_latched, cpu.aeqm, cpu.aeqm_bits);
	  
//	$display("     vmaok %b, pfr %b, pfw %b; vmaenb %b",
//		 cpu.vmaok, cpu.pfr, cpu.pfw, cpu.vmaenb);

//	$display("     apass=%b, apassenb=%b, amemenb=%b",
//		 cpu.apass, cpu.amemenb, cpu.apassenb);

//	$display("     wadr %o, dest %o, destd %o, ir[41:32] %o",
//		 cpu.wadr, cpu.dest, cpu.destd, cpu.ir[41:32]);

//	$display("     mpass=%b, mpassl=%b, mpassm=%b",
//		 cpu.mpass, cpu.mpassl, cpu.mpassm);

	$display("     mdrive: mp%b pdl%b spc%b mf%b destmdr%b; adrive amemenb%b apassenb%b",
		 cpu.mpassm, cpu.pdldrive, cpu.spcdrive, cpu.mfdrive,
		 cpu.destmdr,
		 cpu.amemenb, cpu.apassenb);

	$display("     mfdrive: lc%b ipc%b dc%b pp%b pi%b q%b md%b mp%b vma%b map%b",
		 cpu.lcdrive, cpu.opcdrive, cpu.dcdrive, cpu.ppdrive,
		 cpu.pidrive, cpu.qdrive, cpu.mddrive, cpu.mpassl,
		 cpu.vmadrive, cpu.mapdrive);
	  
	$display("     vma %o, vmas %o, md %o, mds %o",
		 cpu.vma, cpu.vmas, cpu.md, cpu.mds);

	$display("     mapi %o (%o), vmap %o, vmem1_adr %o, vmo %o",
		 cpu.mapi, cpu.mapi[23:13], cpu.vmap, cpu.vmem1_adr, cpu.vmo);

//		 cpu.pdldrive, cpu.spcdrive, cpu.mfdrive);

//	$display("     md=%x, mds=%x, loadmd=%b, busint_bus=%o",
//		 cpu.md, cpu.mds, cpu.mdsel, cpu.mdclk, cpu.loadmd, cpu.busint_bus);

//	$display("     mf=%x, mfenb=%b, srcm=%b, srcq=%b",
//		 cpu.mf, cpu.mfenb, cpu.srcm, cpu.srcq);

//	$display("     popj %b, nop %b, jret %b, jretf %b, jcond %b, spop %b",
//		 cpu.popj, cpu.nop, cpu.jret, cpu.jretf, cpu.jcond, cpu.spop);


	$display("     aluf=%o, alu=%x, qs=%b%b, ob=%o, osel=%b",
		 cpu.aluf, cpu.alu, cpu.qs1, cpu.qs0, cpu.ob, cpu.osel);

	$display("     mem=%o, busint_bus=%o, l-b-i-w %b, n-f %b ifetch=%b",
		 cpu.mem, cpu.busint_bus,
		 cpu.last_byte_in_word, cpu.needfetch, cpu.ifetch);

	$display("     l-b-i-w %b n-f %b lcinc %b newlc_in %b h-w-w %b lb0b %b n-i %b n-i-d %b",
		 cpu.last_byte_in_word, cpu.needfetch, cpu.lcinc,
		 cpu.newlc_in, cpu.have_wrong_word, cpu.lc0b,
		 cpu.next_instr, cpu.next_instrd);

	$display("     spcptr=%o, spc=%o, spco=%o, spco_latched=%o, jret=%b",
		 cpu.spcptr, cpu.spc, cpu.spco, cpu.spco_latched, cpu.jret);

//        $display("     spop%b, spush%b, spcnt%b",
//		 cpu.spop, cpu.spush, cpu.spcnt);

// ---------------------------------------------------------------

//	$display("     destimod %b%b, iob %o, ob %o",
//		 cpu.destimod0, cpu.destimod1, cpu.iob, cpu.ob, cpu.mo, cpu.msk);

//	$display("     mo %o, msk %o, s %b, sr %b mr %b",
//		 cpu.mo, cpu.msk,
//		 { cpu.s4, cpu.s3, cpu.s2, cpu.s1, cpu.s0 }, cpu.sr, cpu.mr);

//	$display("     destpdlx %b, pdlidx %o, pdlptr %o",
//		 cpu.destpdlx, cpu.pdlidx, cpu.pdlptr);

//	$display("     destm %b, destpdlx %b, ir[23:22] %b, ir[21:19]",
//		 cpu.destm, cpu.destpdlx, cpu.ir[23:22], cpu.ir[21:19]);

//        $display("     div %b, mul %b, divposlastime %b, divsubcond %d, divaddcond %b",
//		 cpu.div, cpu.mul,
//		 cpu.divposlasttime, cpu.divsubcond, cpu.divaddcond);

`ifdef xxx	  
	$display("     wmap %b, wmapd %b, wmapwr0d %b, wmapwr1d %b, vma %o, vmas %o",
		 cpu.wmap, cpu.wmapd, cpu.mapwr0d, cpu.mapwr1d,
		 cpu.vma, cpu.vmas);

//	$display("     trap=%x dispenb=%x dn=%x jfalse=%x jcond=%b, popj=%b",
//		 cpu.trap, cpu.dispenb, cpu.dn,
//		 cpu.jfalse, cpu.jcond, cpu.popj);

//	$display("     vma0wp=%b, vma1wp=%b, mapwr0d=%b, mapwr1=%b, wmapd=%b",
//		 cpu.vm0wp, cpu.vm1wp, cpu.mapwr0d, cpu.mapwr1d, cpu.wmapd);
		 
	$display("     mwp=%x madr=%o awp=%x aadr=%o, aeqm %b %b",
		 cpu.mwp, cpu.madr, cpu.awp, cpu.aadr, cpu.aeqm, cpu.aeqm_bits);

	$display("     mf=%x, mfenb=%b, srcm=%b, srcq=%b, spcenb=%b, pdlenb=%b",
		 cpu.mf, cpu.mfenb, cpu.srcm, cpu.srcq, cpu.spcenb, cpu.pdlenb);

	$display("     mddrive=%b, m-src %b, src %b%b%b%b%b, mmem_latched=%x",
		 cpu.mddrive, cpu.ir[31:26],
		 cpu.srcspcpop,cpu.srclc,cpu.srcmd,cpu.srcmap,cpu.srcvma,
		 cpu.mmem_latched);
	  
	$display("     amemenb=%b, apassenb=%b, a_latch=%x",
		 cpu.amemenb, cpu.apassenb, cpu.a_latch);

//	$display("     mpassm=%b, pdldrive=%b, spcdrive=%b, mfdrive=%b",
//		 cpu.mpassm, cpu.pdldrive, cpu.spcdrive, cpu.mfdrive);
	  
//	$display("     nop=%x inop=%x", cpu.nop, cpu.inop);
//	$display("     dest=%x ir[25]=%x", cpu.dest, cpu.ir[25]);

//	$display("     iwrite=%x, iwrited=%x, destm=%x, destmd=%x",
//		 cpu.iwrite, cpu.iwrited, cpu.destm, cpu.destmd);

	$display("     trap=%x dispenb=%x dn=%x jfalse=%x jcond=%b, popj=%b",
		 cpu.trap, cpu.dispenb, cpu.dn,
		 cpu.jfalse, cpu.jcond, cpu.popj);

	$display("     osel=%b, alusub=%b, aluadd=%b, aluf=%o, alu=%x, qs=%b%b",
		 cpu.osel, cpu.alusub, cpu.aluadd, cpu.aluf, cpu.alu,
		 cpu.qs1, cpu.qs0);

        $display("     conds=%b, jcond=%b, jfalse=%b (%b)",
		 cpu.conds, cpu.jcond, cpu.jfalse, cpu.jfalse & ~cpu.jcond);

	$display("     md=%x, mds=%x, mdsel=%b, mdclk=%b, loadmd=%b, busint_bus=%o",
		 cpu.md, cpu.mds, cpu.mdsel, cpu.mdclk, cpu.loadmd, cpu.busint_bus);

//	$display("     ir-dst=%o, destm=%b, destmem=%b, destvma=%b, destmdr=%b",
//		 cpu.ir[25:19], cpu.destm,
//		 cpu.destmem, cpu.destvma, cpu.destmdr);
		 
	$display("     destspc=%b, destpdl_p=%b, spush=%b, spop=%b",
		 cpu.destspc, cpu.destpdl_p, cpu.spush, cpu.spop);
		 
	$display("     ob=%x, mem=%x, vma=%x, vmas=%x",
		 cpu.ob, cpu.mem, cpu.vma, cpu.vmas);
		 
	$display("     spcnt=%b, spcptr=%o, pdlcnt=%b, pdlptr=%o",
		 cpu.spcnt, cpu.spcptr, cpu.pdlcnt, cpu.pdlptr);
		 
	$display("     pwp=%b, pdlwrite=%o, pdlwrited=%b, pldp=%b, pdla=%o",
		 cpu.pwp, cpu.pdlwrite, cpu.pdlwrited,
		 cpu.pdlp, cpu.pdla);

	$display("     pdl=%x, pdl_latch=%x",
		 cpu.pdl, cpu.pdl_latch);
	  
//	$display("     iwrite=%b, iwrited=%b, popj=%b, imod=%b, ramdisable=%b",
//		 cpu.iwrite, cpu.iwrited, cpu.popj, cpu.imod, cpu.ramdisable);
	  
//	$display("     iralu=%x irjump=%x irdisp=%x irbyte=%x",
//		 cpu.iralu, cpu.irjump, cpu.irdisp, cpu.irbyte);
`endif
	  
     end 

   assign ide_data_bus = ~ide_diow ? ide_data_out : 16'bz;

   assign ide_data_in = ide_data_bus;
     
   always @(posedge clk)
     begin
	$pli_ide(ide_data_bus, ide_dior, ide_diow, ide_cs, ide_da);
     end
   
endmodule
