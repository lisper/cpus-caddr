/*
 * caddr
 *
 * major cleanup:
 * 11/2009 brad parker brad@heeltoe.com
 * 
 * sync version:
 * 4/2008 brad parker brad@heeltoe.com
 *
 * original version:
 * 10/2005 brad parker brad@heeltoe.com
 */

/*
 * The original set of clocks:
 *
 *   +++++++++++++++++++++++++++                    +--------
 *   |                         |                    |
 *   |                         |                    |  tpclk
 * --+                         +--------------------+
 *
 *                                    ++++++++
 *                                    |      |
 *                                    |      |         tpwp
 * -----------------------------------+      +---------------
 *
 *   ^                         ^
 *   |                         |
 *   |                      latch A&M memory output
 *  latch IR
 *
 * ===============================================================
 * 
 * New states & clock:
 *
 *  ++++  ++++  ++++  ++++  ++++  ++++  ++++  ++++  ++++  ++++  
 *  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |
 * -+  +--+  +--+  +--+  +--+  +--+  +--+  +--+  +--+  +--+  +--
 *
 *  +++++++
 *  |     |
 * -+     +---------------
 *   decode
 *        +++++++
 *        |     |
 * -------+     +---------------
 *         execute
 *              +++++++
 *              |     |
 * -------------+     +---------------
 *               write
 *                    +++++++
 *                    |     |
 * -------------------+     +---------------
 *                     fetch
 * boot
 * reset
 * 
 * ===================================
 * decode
 *	transparent latch a
 *	a = ffff
 *	aadr = ir[41:32]
 *
 * execute
 *  	transparent latch a
 *	a = ffff
 *	aadr = ir[41:32]
 * 
 * write
 *	a = a_latch
 *	aadr = wadr
 *
 * fetch
 * 	a = a_latch
 *	aadr = ir[41:32]
 *	update pc
 *	latch md <- mds
 * 
 * latch wadr <- ir[]
 * latch destd <- dest
 * latch destmd <- destm
 *	latch ir
 */

module caddr ( clk, ext_int, ext_reset, ext_boot, ext_halt,

	       spy_in, spy_out, dbread, dbwrite, eadr,

	       prefetch_out, fetch_out,

	       mcr_addr, mcr_data_out, mcr_data_in,
	       mcr_ready, mcr_write, mcr_done,

	       sdram_addr, sdram_data_in, sdram_data_out,
	       sdram_req, sdram_ready, sdram_write, sdram_done,

	       vram_addr, vram_data_in, vram_data_out,
	       vram_req, vram_ready, vram_write, vram_done,

	       ide_data_in, ide_data_out, ide_dior, ide_diow, ide_cs, ide_da );

   input clk;
   input ext_int;
   input ext_reset;
   input ext_boot;
   input ext_halt;

   input [15:0] spy_in;
   output [15:0] spy_out;
   input 	dbread;
   input 	dbwrite;
   input [3:0] 	eadr;

   output 	 prefetch_out;
   output 	 fetch_out;
   output [13:0] mcr_addr;
   output [48:0] mcr_data_out;
   input [48:0]  mcr_data_in;
   input 	 mcr_ready;
   output 	 mcr_write;
   input 	 mcr_done;

   output [21:0]  sdram_addr;
   output [31:0] sdram_data_out;
   input [31:0]  sdram_data_in;
   output 	 sdram_req;
   input 	 sdram_ready;
   output 	 sdram_write;
   input 	 sdram_done;

   output [14:0] vram_addr;
   output [31:0] vram_data_out;
   input [31:0]  vram_data_in;
   output 	 vram_req;
   input 	 vram_ready;
   output 	 vram_write;
   input 	 vram_done;
   
   input [15:0]  ide_data_in;
   output [15:0] ide_data_out;
   output 	 ide_dior;
   output 	 ide_diow;
   output [1:0]  ide_cs;
   output [2:0]  ide_da;

   // ------------------------------------------------------------
   
   wire [13:0] 	npc;
   wire [13:0] 	dpc;
   wire [13:0] 	ipc;
   wire [18:0] 	spc;

   reg [48:0] 	ir;

   wire [31:0] 	a;
   reg [31:0] 	a_latch;

   reg [9:0] 	wadr;
   reg 		destd, destmd;

   wire 	apass;
   wire 	amemenb, apassenb;
   wire 	awp;

   wire [9:0] 	aadr;

   wire [7:0] 	aeqm_bits;
   wire 	aeqm;
   wire [32:0] 	alu;

   wire 	divposlasttime, divsubcond, divaddcond;
   wire 	aluadd, alusub, mulnop;
   wire 	mul, div, specalu;

   wire [1:0] 	osel;

   wire [3:0] 	aluf;
   wire 	alumode;
   wire 	cin0;

   wire [31:0] 	amem;

   wire 	dfall, dispenb, ignpopj, jfalse, jcalf, jretf, jret, iwrite;
   wire 	ipopj, popj, srcspcpopreal;
   wire 	spop, spush;

   wire 	spcwpass, spcpass;
   wire 	swp, spcenb, spcdrive, spcnt;

   reg 		inop, spushd, iwrited; 
   wire 	n, pcs1, pcs0;

   wire 	nopa, nop;

   // page DRAM0-2
   wire [10:0] 	dadr;
   wire 	dr, dp, dn;
   wire 	daddr0;
   wire [6:0] 	dmask;
   wire 	dwe;

   // page DSPCTL
   wire 	dmapbenb, dispwr;
   reg [9:0] 	dc;
   wire [11:0] 	prompc;

   // page FLAG
   wire 	statbit, ilong, aluneg;
   wire 	pgf_or_int, pgf_or_int_or_sb, sint;

   wire [2:0] 	conds;
   wire 	jcond;
   reg 		lc_byte_mode, prog_unibus_reset, int_enable, sequence_break;

   // page IOR
   wire [47:0] 	iob;
   wire [31:0] 	ob;

   // page IPAR
   wire 	iparity, iparok;

   // page LC
   reg [25:0] 	lc;
   wire [3:0] 	lca;
   wire 	lcry3;

   wire 	lcdrive;
   wire 	sh4, sh3;

   wire [31:0] 	mf;

   wire 	lc0b, next_instr, newlc_in;
   wire 	have_wrong_word, last_byte_in_word;
   wire 	needfetch, ifetch, spcmung, spc1a;
   wire 	lcinc;

   reg 		newlc, sintr, next_instrd;

   wire 	lc_modifies_mrot;
   wire 	inst_in_left_half;
   wire 	inst_in_2nd_or_4th_quarter;

   wire [13:0] 	wpc;

   // page MCTL
   wire 	mpass, mpassl, mpassm;
   wire 	srcm;
   wire 	mwp;
   wire [4:0] 	madr;

   // page MD
   reg [31:0] 	md;
   wire 	mddrive;	/* drive md on to mf bus */
   wire 	mdclk;		/* enable - clock md in? */
   wire 	loadmd;		/* data available from busint */

   reg 		mdhaspar, mdpar;
   wire 	mdgetspar;
   wire 	mempar_in;

   wire 	ignpar;

   // page MDS
   wire [31:0] 	mds;
   wire [31:0] 	mem;
   wire [31:0] 	busint_bus;
   wire [15:0] 	busint_spyout;
   wire 	mempar_out;

   wire 	bus_int;
   

   // page MF
   wire 	mfenb;
   wire 	mfdrive;

   // page MLATCH
   reg [31:0] 	mmem_latched;

   wire [31:0] 	m;

   // page MMEM
   wire [31:0] 	mmem;

   wire [31:0] 	mo;

   wire [31:0] 	msk_right_out, msk_left_out, msk;

   wire 	dcdrive, opcdrive;

   // page PDL
   wire [31:0] 	pdl;

   // page PDLCTL
   wire [9:0] 	pdla;
   wire 	pdlp, pdlwrite;
   wire 	pwp, pdlenb, pdldrive, pdlcnt;
   reg 		pdlwrited, pwidx, imodd, destspcd;

   // page PDLPTR
   wire 	pidrive, ppdrive;
   reg [9:0] 	pdlidx;

   // page Q
   reg [31:0] 	q;
   wire 	qs1, qs0, qdrive;

   // page SHIFT0-1
   wire [31:0] 	sa;
   wire [31:0] 	r;

   // page SMCTL
   wire 	mr, sr;
   wire [4:0] 	mskr;
   wire [4:0] 	mskl;

   wire 	s4, s3, s2, s1, s0;

   // page SOURCE
   wire 	irbyte, irdisp, irjump, iralu;

   wire [3:0] 	funct;

   wire 	srcq;
   wire 	srcopc;
   wire 	srcpdltop;	/* ir<30-26> src PDL buffer, ptr */
   wire 	srcpdlpop;	/* ir<30-26> src PDL buffer, ptr, pop */
   wire 	srcpdlidx;
   wire 	srcpdlptr;
   wire 	srcspc;		/* ir<30-26> src spc ptr */
   wire 	srcdc;		/* ir<30-26> src dispatch constant */
   wire 	srcspcpop, srclc, srcmd, srcmap, srcvma;

   wire 	imod;

   wire 	dest;
   wire 	destm;		/* fuctional destination */

   wire 	destmem;	/* ir<25-14> dest VMA or MD */

   wire 	destvma;	/* ir<25-14> dest VMA register */
   wire 	destmdr;	/* ir<25-14> dest MD register */

   wire 	destintctl;	/* ir<25-14> dest interrupt control */
   wire 	destlc;		/* ir<25-14> dest lc */
   wire 	destimod1;	/* ir<25-14> dest oa register <47-26> */
   wire 	destimod0;	/* ir<25-14> dest oa register <25-0> */
   wire 	destspc;	/* ir<25-14> dest spc data, push*/
   wire 	destpdlp;	/* ir<25-14> dest pdl ptr */
   wire		destpdlx;	/* ir<25-14> dest pdl index */
   wire 	destpdl_x;	/* ir<25-14> dest pdl (addressed by index)  */
   wire 	destpdl_p;	/* ir<25-14> dest pdl (addressed by ptr), push*/
   wire 	destpdltop;	/* ir<25-14> dest pdl (addressed by ptr) */


   // page SPC

   reg [4:0] 	spcptr;

   wire [18:0] 	spcw;
   wire [18:0] 	spco;

   // page SPCPAR

   wire 	mdparerr, parerr, memparok;
   wire 	trap;
   reg 		boot_trap;


   // page VCTRL1

   reg 		memstart, mbusy_sync;
   wire 	memop, memprepare;

   reg 		rdcyc, wmapd, mbusy;
   wire 	memrq;
   reg 		wrcyc;

   wire 	pfw;			/* vma permissions */
   wire 	pfr;
   reg 		vmaok;			/* vma access ok */

   reg 		last_pfr;		/* result of last mem op */
   reg 		last_pfw;
	
   wire 	mfinish;

   wire 	memack;

   reg 		mfinishd;
   wire 	waiting;
   
   // page VCTRL2

   wire 	mapwr0d, mapwr1d, vm0wp, vm1wp;
   wire 	vmaenb, vmasel;
   wire 	memdrive, mdsel, use_md;
   wire 	wmap, memwr, memrd;

   wire 	lm_drive_enb;

   // page VMA

   reg [31:0] 	vma;
   wire 	vmadrive;

   // page VMAS

   wire [31:0] 	vmas;

   //       22221111111111
   // mapi  32109876543210
   //       1
   // vmem0 09876543210
   //
   wire [23:8] 	mapi;

   wire [4:0] 	vmap;

   // page VMEM0 - virtual memory map stage 0

   wire 	use_map;

   wire [23:0] 	vmo;

   wire 	mapdrive;

   wire [48:0] 	i;
   wire [48:0] 	iprom;
   wire [48:0] 	iram;
   reg [47:0] 	spy_ir;

   wire 	ramdisable;

   reg 		opcinh, opcclk, lpc_hold;

   reg 		ldstat, idebug, nop11, step;

   reg 		run;

   wire 	machrun, stat_ovf, stathalt;

   wire 	lowerhighok, highok;
   wire 	prog_reset, reset;
   wire 	err, errhalt;
   wire 	bus_reset;
   wire 	prog_boot, boot;

   wire 	prog_bus_reset;

   wire 	opcclka;

   // page VMEM1&2

   wire [9:0] 	vmem1_adr;
   wire 	vmem1_we;

   // page PCTL
   wire 	promenable, promce, bottom_1k;

   reg [31:0] 	pdl_latch;

   // page SPCLCH
   reg [18:0] 	spco_latched;

   // page OLORD1 
   reg 		promdisable;
   reg 		trapenb;
   reg 		stathenb;
   reg 		errstop;

   reg 		srun, sstep, ssdone, promdisabled;

   // page OLORD2

   reg 		ape, mpe, pdlpe, dpe, ipe, spe, higherr, mempe;
   reg 		v0pe, v1pe, statstop, halted;

   // page L
   reg [31:0] 	l;

   // page NPC
   reg [13:0] 	pc;

   // page OPCS
   reg [13:0] 	opc;

   // page PDLPTR
   reg [9:0] 	pdlptr;

   // page SPCW
   reg [13:0] 	reta;

   // page IWR
   reg [48:0] 	iwr;

   reg [13:0] 	lpc;

   reg 		lvmo_23;
   reg 		lvmo_22;
   reg [21:8] 	pma;


   // SPY 0

   wire   spy_obh, spy_obl, spy_pc, spy_opc,
	  spy_nc, spy_irh, spy_irm, spy_irl;

   wire   spy_sth, spy_stl, spy_ah, spy_al,
	  spy_mh, spy_ml, spy_flag2, spy_flag1;

   wire   ldmode, ldopc, ldclk, lddbirh, lddbirm, lddbirl;
   wire   set_promdisable;
   

   // *******************************************************************

   // main cpu state machine
   
   parameter STATE_S0 =	5'b00000,
	       STATE_S1 = 5'b00001,
	       STATE_S2 = 5'b00010,
	       STATE_S3 = 5'b00100,
	       STATE_S4 = 5'b01000,
	       STATE_S5 = 5'b10000;

   reg [4:0] state;

   wire [4:0] next_state;
   wire       state_decode, state_execute, state_write, state_fetch;
   wire       state_wait;
   wire       phase0;
   wire       phase1;

   always @(posedge clk)
     if (reset)
       state <= STATE_S0;
     else
       state <= next_state;

   assign next_state = 
		       state == STATE_S0 ? STATE_S1 :
		       (state == STATE_S1 && machrun) ? STATE_S2 :
		       (state == STATE_S1 && ~machrun) ? STATE_S1 :
		       state == STATE_S2 ? STATE_S3 :
		       state == STATE_S3 ? STATE_S4 :
		       state == STATE_S4 ? STATE_S1 :
		       state == STATE_S5 ? STATE_S4 :
		       STATE_S4;

   assign state_decode = state[0];
   assign state_execute = state[1];
   assign state_write = state[2];
   assign state_fetch = state[3];
   assign state_wait = state[4];

   assign phase0 = state_decode | state_execute;
   assign phase1 = state_write | state_fetch;

   // page actl

   always @(posedge clk)
     if (reset)
       begin
	  wadr <= 0;
	  destd <= 0;
	  destmd <= 0;
       end
     else
       if (state_fetch)
	 begin
	    // wadr 9  8  7  6  5  4  3  2  1  0
	    //      0  0  0  0  0  18 17 16 15 14
	    // ir   23 22 21 20 19 18 17 16 15 14
	    wadr <= destm ? { 5'b0, ir[18:14] } : { ir[23:14] };
	    destd <= dest;
	    destmd <= destm;
	 end

   assign apass = destd & ( ir[41:32] == wadr[9:0] ? 1'b1 : 1'b0 );

   // should remove the phase1...
   assign apassenb = apass & phase1;
   assign amemenb = ~apass & phase1;

   assign awp = destd & state_write;

   // use wadr during state_write
   assign aadr = ~state_write ? { ir[41:32] } : wadr;

   // page ALATCH

   // AML
   // transparent latch w/async reset
   always @(phase0 or amem or reset)
     if (reset)
       a_latch = 0;
     else
       if (phase0)
	 a_latch = amem;

   assign a = amemenb ? a_latch :
	      apassenb ? l :
	      32'hffffffff;

   // page ALU0-1

   // 74181 pulls down AEB if not equal
   // aeqm is the simulated open collector
   assign aeqm = aeqm_bits == { 8'b11111111 } ? 1'b1 : 1'b0;

   wire[2:0] nc_alu;
   wire      cin32_n, cin28_n, cin24_n, cin20_n;
   wire      cin16_n, cin12_n, cin8_n, cin4_n;

   wire      xx0, xx1;
   wire      yy0, yy1;

   wire      xout3, xout7, xout11, xout15, xout19, xout23, xout27, xout31;
   wire      yout3, yout7, yout11, yout15, yout19, yout23, yout27, yout31;
   
   ic_74S181  i_ALU1_2A03 (
			   .B({3'b0,a[31]}),
			   .A({3'b0,m[31]}),
			   .S(aluf[3:0]),
			   .CIN_N(cin32_n),
			   .M(alumode),
			   .F({nc_alu,alu[32]}),
			   .X(),
			   .Y(),
			   .COUT_N(),
			   .AEB()
			   );

   ic_74S181  i_ALU1_2A08 (
			   .B(a[31:28]),
			   .A(m[31:28]),
			   .S(aluf[3:0]),
			   .CIN_N(cin28_n),
			   .M(alumode),
			   .F(alu[31:28]),
			   .AEB(aeqm_bits[7]),
			   .X(xout31),
			   .Y(yout31),
			   .COUT_N()
			   );

   ic_74S181  i_ALU1_2B08 (
			   .B(a[27:24]),
			   .A(m[27:24]),
			   .S(aluf[3:0]),
			   .CIN_N(cin24_n),
			   .M(alumode),
			   .F(alu[27:24]),
			   .AEB(aeqm_bits[6]),
			   .X(xout27),
			   .Y(yout27),
			   .COUT_N()
			   );

   ic_74S181  i_ALU1_2A13 (
			   .B(a[23:20]),
			   .A(m[23:20]),
			   .S(aluf[3:0]),
			   .CIN_N(cin20_n),
			   .M(alumode),
			   .F(alu[23:20]),
			   .AEB(aeqm_bits[5]),
			   .X(xout23),
			   .Y(yout23),
			   .COUT_N()
			   );

   ic_74S181  i_ALU1_2B13 (
			   .B(a[19:16]),
			   .A(m[19:16]),
			   .S(aluf[3:0]),
			   .CIN_N(cin16_n),
			   .M(alumode),
			   .F(alu[19:16]),
			   .AEB(aeqm_bits[4]),
			   .X(xout19),
			   .Y(yout19),
			   .COUT_N()
			   );

   ic_74S181  i_ALU0_2A23 (
			   .A(m[15:12]),
			   .B(a[15:12]),
			   .S(aluf[3:0]),
			   .CIN_N(cin12_n),
			   .M(alumode),
			   .F({alu[15:12]}),
			   .AEB(aeqm_bits[3]),
			   .X(xout15),
			   .Y(yout15),
			   .COUT_N()
			   );

   ic_74S181  i_ALU0_2B23 (
			   .A(m[11:8]),
			   .B(a[11:8]),
			   .S(aluf[3:0]),
			   .CIN_N(cin8_n),
			   .M(alumode),
			   .F(alu[11:8]),
			   .AEB(aeqm_bits[2]),
			   .X(xout11),
			   .Y(yout11),
			   .COUT_N()
			   );

   ic_74S181  i_ALU0_2A28 (
			   .A(m[7:4]),
			   .B(a[7:4]),
			   .S(aluf[3:0]),
			   .CIN_N(cin4_n),
			   .M(alumode),
			   .F(alu[7:4]),
			   .AEB(aeqm_bits[1]),
			   .X(xout7),
			   .Y(yout7),
			   .COUT_N()
			   );

   ic_74S181  i_ALU0_2B28 (
			   .A(m[3:0]),
			   .B(a[3:0]),
			   .S(aluf[3:0]),
			   .CIN_N(~cin0),
			   .M(alumode),
			   .F(alu[3:0]),
			   .AEB(aeqm_bits[0]),
			   .X(xout3),
			   .Y(yout3),
			   .COUT_N()
			   );

   // page ALUC4

   ic_74S182  i_ALUC4_2A20 (
			    .Y( { yout15,yout11,yout7,yout3 } ),
			    .X( { xout15,xout11,xout7,xout3 } ),
			    .COUT2_N(cin12_n),
			    .COUT1_N(cin8_n),
			    .COUT0_N(cin4_n),
			    .CIN_N(~cin0),
			    .XOUT(xx0),
			    .YOUT(yy0)
			    );

   ic_74S182  i_ALUC4_2A19 (
			    .Y( { yout31,yout27,yout23,yout19 } ),
			    .X( { xout31,xout27,xout23,xout19 } ),
			    .COUT2_N(cin28_n),
			    .COUT1_N(cin24_n),
			    .COUT0_N(cin20_n),
			    .CIN_N(cin16_n),
			    .XOUT(xx1),
			    .YOUT(yy1)
			    );

   ic_74S182  i_ALUC4_2A18 (
			    .Y( { 2'b00, yy1,yy0 } ),
			    .X( { 2'b00, xx1,xx0 } ),
			    .COUT1_N(cin32_n),
			    .COUT0_N(cin16_n),
			    .CIN_N(~cin0),
			    .COUT2_N(),
			    .XOUT(),
			    .YOUT()
			    );


   assign    divposlasttime  = q[0] | ir[6];

   assign    divsubcond = div & divposlasttime;

   assign    divaddcond = div & (ir[5] | ~divposlasttime);

   assign    mulnop = mul & ~q[0];

   assign    aluadd = (divaddcond & ~a[31]) |
		      (divsubcond & a[31]) |
		      mul;

   assign    alusub = mulnop |
		      (divsubcond & ~a[31]) |
	              (divaddcond & a[31]) |
		      irjump;

   assign osel[1] = ir[13] & iralu;
   assign osel[0] = ir[12] & iralu;

   assign aluf =
		  {alusub,aluadd} == 2'b00 ? { ir[3], ir[4], ~ir[6], ~ir[5] } :
		  {alusub,aluadd} == 2'b01 ? { 1'b1,   1'b0,   1'b0,  1'b1 } :
		  {alusub,aluadd} == 2'b10 ? { 1'b0,   1'b1,   1'b1,  1'b0 } :
	          { 1'b1,   1'b1,   1'b1,  1'b1 };

   assign alumode =
		     {alusub,aluadd} == 2'b00 ? ~ir[7] :
		     {alusub,aluadd} == 2'b01 ? 1'b0 :
		     {alusub,aluadd} == 2'b10 ? 1'b0 :
	             1'b1;

   assign cin0 =
		  {alusub,aluadd} == 2'b00 ? ir[2] :
		  {alusub,aluadd} == 2'b01 ? 1'b0 :
		  {alusub,aluadd} == 2'b10 ? ~irjump :
                  1'b1;


   // page AMEM0-1

//xxx was sync
   part_1kx32ram_a i_AMEM(
			  .clk_a(clk),
			  .reset(reset),
			  .address_a(aadr),
			  .q_a(amem),
			  .data_a(l),
			  .wren_a(awp),
			  .rden_a(1'b1)
			  );

   
   // page CONTRL

   assign dfall  = dr & dp;			/* push-pop fall through */

   assign dispenb = irdisp & ~funct[2];

   assign ignpopj  = irdisp & ~dr;

   assign jfalse = irjump & ir[6];		/* jump and inverted-sense */

   assign jcalf = jfalse & ir[8];		/* call and inverted-sense */

   assign jret = irjump & ~ir[8] & ir[9];	/* return */

   assign jretf = jret & ir[6];			/* return and inverted-sense */

   assign iwrite = irjump & ir[8] & ir[9];	/* microcode write */

   assign ipopj = ir[42] & ~nop;

   assign popj = ipopj | iwrited;

   assign srcspcpopreal  = srcspcpop & ~nop;

   assign spop =
		((srcspcpopreal | popj) & ~ignpopj) |
		(dispenb & dr & ~dp) |
		(jret & ~ir[6] & jcond) |
		(jretf & ~jcond);

   assign spush = 
		  destspc |
		  (jcalf & ~jcond) |
		  (dispenb & dp & ~dr) |
		  (irjump & ~ir[6] & ir[8] & jcond);
   

   assign spcwpass = spushd & state_fetch;
   assign spcpass = ~spushd & state_fetch;

   assign swp = spushd & state_write;
   assign spcenb = srcspc | srcspcpop;
   assign spcdrive = spcenb & phase1;
   assign spcnt = spush | spop;

   always @(posedge clk)
     if (reset)
       begin
	  spushd <= 0;
	  iwrited <= 0;
       end
     else
       if (state_fetch)
	 begin
	    spushd <= spush;
	    iwrited <= iwrite;
	 end

   /*
    * select new pc
    * {pcs1,pcs0}
    * 00 0 spc
    * 01 1 ir
    * 10 2 dpc
    * 11 3 ipc
    */

   assign pcs1 =
	!(
	  (popj & ~ignpopj) |		/* popj & !ignore */
	  (jfalse & ~jcond) |		/* jump & invert & cond-not-satisfied */
	  (irjump & ~ir[6] & jcond) |	/* jump & !invert & cond-satisfied */
	  (dispenb & dr & ~dp)		/* dispatch + return & !push */
	  );

   assign pcs0 =
	!(
	  (popj) |
	  (dispenb & ~dfall) |
	  (jretf & ~jcond) |
	  (jret & ~ir[6] & jcond)
	  );

   /*
    * N set if:
    *  trap 						or
    *  iwrite (microcode write) 			or
    *  dispatch & disp-N 				or
    *  jump & invert-jump-selse & cond-false & !next	or
    *  jump & !invert-jump-sense & cond-true & !next
    */
   assign n =
	     trap |
	     iwrited |
	     (dispenb & dn) |
	     (jfalse & ~jcond & ir[7]) |
	     (irjump & ~ir[6] & jcond & ir[7]);

   assign nopa = inop | nop11;

   assign nop = trap | nopa;

   always @(posedge clk)
     if (reset)
       inop <= 0;
     else
       if (state_fetch)
	 inop <= n;
   
   // page DRAM0-2

   // dadr  10 9  8  7  6  5  4  3  2  1  0
   // -------------------------------------
   // ir    22 21 20 19 18 17 16 15 14 13 d
   // dmask x  x  x  x  6  5  4  3  2  1  x
   // r     x  x  x  x  6  5  4  3  2  1  x

   assign daddr0 = 
		   (ir[8] & vmo[18]) |
		   (ir[9] & vmo[19]) |
//note: the hardware shows bit 0 replaced, 
// 	but usim or's it instead.
		   (/*~dmapbenb &*/ dmask[0] & r[0]) |
		   (ir[12]);

   assign dadr =
		{ ir[22:13], daddr0 } |
		({ 4'b0000, dmask[6:1], 1'b0 } &
		 { 4'b0000, r[6:1],     1'b0 });
   
   assign dwe = dispwr & state_write;

//xxx was async
   part_2kx17ram i_DRAM(
			.clk_a(clk),
			.reset(reset),
			.address_a(dadr),
			.q_a({dr,dp,dn,dpc}),
			.data_a(a[16:0]),
			.wren_a(dwe),
			.rden_a(1'b1)
			);

   // page DSPCTL

   assign dmapbenb  = ir[8] | ir[9];

   assign dispwr = irdisp & funct[2];

   always @(posedge clk)
     if (reset)
       dc <= 0;
     else
       if (state_fetch && irdisp)
	 dc <= ir[41:32];

   wire   nc_dmask;
   
   part_32x8prom i_DMASK(
			 .clk(~clk),
			 .addr( {1'b0, 1'b0, ir[7], ir[6], ir[5]} ),
			 .q( {nc_dmask, dmask[6:0]} )
			 );

   // page FLAG

   assign statbit = ~nopa & ir[46];
   assign ilong  = ~nopa & ir[45];
   
   assign aluneg = ~aeqm & alu[32];

   assign sint = sintr & int_enable;
   
   assign pgf_or_int = ~vmaok | sint;
   assign pgf_or_int_or_sb = ~vmaok | sint | sequence_break;

   assign conds = ir[2:0] & {ir[5],ir[5],ir[5]};

   assign jcond = 
		  conds == 3'b000 ? r[0] :
		  conds == 3'b001 ? aluneg :
		  conds == 3'b010 ? alu[32] :
		  conds == 3'b011 ? aeqm :
		  conds == 3'b100 ? ~vmaok :
		  conds == 3'b101 ? pgf_or_int :
		  conds == 3'b110 ? pgf_or_int_or_sb :
	          1'b1;

   always @(posedge clk)
     if (reset)
       begin
	  lc_byte_mode <= 0;
	  prog_unibus_reset <= 0;
	  int_enable <= 0;
	  sequence_break <= 0;
       end
     else
       if (state_fetch && destintctl)
	 begin
`ifdef debug
	    $display("destintctl: ob %o (%b %b %b %b)",
		     ob, ob[29], ob[28], ob[27], ob[26]);
`endif
            lc_byte_mode <= ob[29];
            prog_unibus_reset <= ob[28];
            int_enable <= ob[27];
            sequence_break <= ob[26];
	 end

   // page IOR

   // iob 47 46 45 44 43 42 41 40 39 38 37 36 35 34 33 32 31 30 29 28 27 26
   // i   47 46 45 44 43 42 41 40 39 38 37 36 35 34 33 32 31 30 29 28 27 26
   // ob  21 20 19 18 17 16 15 14 13 12 11 10 9  8  7  6  5  4  3  2  1  0  

   // iob 25 24 ... 1  0
   // i   25 24 ... 1  0
   // ob  25 24 ... 1  0

   assign iob = i[47:0] | { ob[21:0], ob[25:0] };


   // page IPAR

   assign iparity = 0;
   assign iparok = imodd | iparity;

   
   // page IREG

   always @(posedge clk)
     if (reset)
       ir <= 49'b0;
     else
       if (state_fetch)
	 begin
	    ir[47:26] <= ~destimod1 ? i[47:26] : iob[47:26]; 
	    ir[25:0] <= ~destimod0 ? i[25:0] : iob[25:0];
`ifdef debug_iram
	    if (~destimod0 && ~destimod0 && ~promenable)
	      $display("iram: [%o] -> %o; %t", pc, iram, $time);
`endif
`ifdef debug_detail
	    if (destimod1)
	      $display("destimod1: lpc %o ob %o ir %o",
		       lpc, ob[21:0], { iob[47:26], i[25:0] });
`endif
	 end


   // page IWR

   always @(posedge clk)
     if (reset)
       iwr <= 0;
     else
       if (state_fetch)
	 begin
	    iwr[48] <= 0;
	    iwr[47:32] <= a[15:0];
	    iwr[31:0] <= m[31:0];
	 end


   // page L

   always @(posedge clk)
     if (reset)
       l <= 0;
     else
//xxx
       // vma is latched during write, so this must be too
//       if (state_fetch)
       if ((vmaenb && state_write) || (~vmaenb && state_fetch))
	 l <= ob;


   // page LC

   always @(posedge clk)
     if (reset)
       lc <= 0;

     else
       if (state_fetch)
	 begin
	    if (destlc)
              lc <= { ob[25:4], ob[3:0] };
	    else
              lc <= { lc[25:4] + { 21'b0, lcry3 }, lca[3:0] };
	 end

   assign {lcry3, lca[3:0]} =
			     lc[3:0] +
			     { 3'b0, lcinc & ~lc_byte_mode } +
			     { 3'b0, lcinc };

   assign lcdrive  = srclc & phase1;

   // xxx
   // I think the above is really
   // 
   // always @(posedge clk)
   //   begin
   //     if (destlc_n == 0)
   //       lc <= ob;
   //     else
   //       lc <= lc + 
   //             !(lcinc_n | lc_byte_mode) ? 1 : 0 +
   //             lcinc ? 1 : 0;
   //   end
   //

   // mux MF
   assign mf =
        lcdrive ?
	      { needfetch, 1'b0, lc_byte_mode, prog_unibus_reset,
		int_enable, sequence_break, lc[25:1], lc0b } :
        opcdrive ?
	      { 16'b0, 2'b0, opc[13:0] } :
        dcdrive ?
	      { 16'b0, 4'b0, 2'b0, dc[9:0] } :
	ppdrive ?
	      { 16'b0, 4'b0, 2'b0, pdlptr[9:0] } :
	pidrive ?
	      { 16'b0, 4'b0, 2'b0, pdlidx[9:0] } :
	qdrive ?
	      q :
	mddrive ?
	      md :
	mpassl ?
	      l :
	vmadrive ?
	      vma :
	mapdrive ?
//	      { ~pfw, ~pfr, 1'b1, vmap[4:0], vmo[23:0] } :
	      { ~last_pfw, ~last_pfr, 1'b0, vmap[4:0], vmo[23:0] } :
	      32'b0;


   // page LCC

   assign lc0b = lc[0] & lc_byte_mode;
   assign next_instr  = spop & (~srcspcpopreal & spc[14]);
  
   assign newlc_in  = have_wrong_word & ~lcinc;
   assign have_wrong_word = newlc | destlc;
   assign last_byte_in_word  = ~lc[1] & ~lc0b;
   assign needfetch = have_wrong_word | last_byte_in_word;

   assign ifetch  = needfetch & lcinc;
   assign spcmung = spc[14] & ~needfetch;
   assign spc1a = spcmung | spc[1];

   assign lcinc = next_instrd | (irdisp & ir[24]);

   always @(posedge clk)
     if (reset)
       begin
	  newlc <= 0;
	  sintr <= 0;
	  next_instrd <= 0;
       end
     else
       if (state_fetch)
	 begin
	    newlc <= newlc_in;
	    sintr <= (ext_int | bus_int);
	    next_instrd <= next_instr;
	 end

   // mustn't depend on nop

   assign lc_modifies_mrot  = ir[10] & ir[11];
   
   assign inst_in_left_half = !((lc[1] ^ lc0b) | ~lc_modifies_mrot);

   assign sh4  = ~(inst_in_left_half ^ ~ir[4]);

   // LC<1:0>
   // +---------------+
   // | 0 | 3 | 2 | 1 |
   // +---------------+
   // |   0   |   2   |
   // +---------------+

   assign inst_in_2nd_or_4th_quarter =
	      !(lc[0] | ~lc_modifies_mrot) & lc_byte_mode;

   assign sh3  = ~(~ir[3] ^ inst_in_2nd_or_4th_quarter);


   //page LPC

   always @(posedge clk)
     if (reset)
       lpc <= 0;
     else
       if (state_fetch)
	 begin
	    if (~lpc_hold)
	      lpc <= pc;
	 end

   /* dispatch and instruction as N set */
   assign wpc = (irdisp & ir[25]) ? lpc : pc;


   // page MCTL

   assign mpass = { 1'b1, ir[30:26] } == { destmd, wadr[4:0] };

   assign mpassl = mpass & phase1 & ~ir[31];
   assign mpassm  = ~mpass & phase1 & ~ir[31];

   assign srcm = ~ir[31] & ~mpass;	/* srcm = m-src is m-memory */

   assign mwp = destmd & state_write;

   // use wadr during state_write
   assign madr = ~state_write ? ir[30:26] : wadr[4:0];

   // page MD

//   always @(posedge mdclk)
   always @(posedge clk) 
     if (reset)
       begin
	  md <= 32'b0;
	  mdhaspar <= 1'b0;
	  mdpar <= 1'b0;
       end
     else
//really this is loadmd during decode or write; destmdr during phase 1
//       if ((state_write && mdclk) || (state_decode && loadmd))
       if (((phase0||state_write) && loadmd) || (state_fetch && destmdr))
//       if (loadmd || (state_fetch && destmdr))
	 begin
`ifdef debug
	    if (state_fetch && destmdr)
	      $display("load md <- %o; D mdsel%b osel %b alu %o mo %o; lpc %o",
		       mds, mdsel, osel, alu, mo, lpc);
	    else
	      $display("load md <- %o; L lpc %o; %t", mds, lpc, $time);
`endif
	    md <= mds;
	    mdhaspar <= mdgetspar;
	    mdpar <= mempar_in;
	 end

`ifdef debug
   always @(posedge clk) 
     if (loadmd && (state_fetch && destmdr))
       begin
	  $display("XXXX loadmd and destmdr conflict, lpc %o; %t", lpc, $time);
	  $finish;
       end
`endif
   
   assign mddrive = srcmd & phase1;

   assign mdgetspar = ~destmdr & ~ignpar;
   assign ignpar = 1'b0;

//see above
//   assign mdclk = loadmd | ((state_write|state_fetch) & destmdr);
      assign mdclk = loadmd | destmdr;
   
   // page MDS

   assign mds = mdsel ? ob : mem;

   assign mempar_out = 1'b1;

   // mux MEM
   assign mem =
	       memdrive ? md :
	       loadmd ? busint_bus :
	       32'b0;


   // page MF

   assign mfenb = ~srcm & !(spcenb | pdlenb);
   assign mfdrive = mfenb & phase1;

   // page MLATCH

   // transparent latch w/async reset
   always @(phase0 or mmem or reset)
     if (reset)
       begin
	  mmem_latched = 0;
       end
     else
       if (phase0)
	 mmem_latched = mmem;

`ifdef debug_with_usim
   // tell disk controller when each fetch passes to force sync with usim
   always @(posedge clk)
	if (state_fetch)
	  busint.disk.fetch = 1;
	else
	  busint.disk.fetch = 0;
`endif
       
   // mux M
   assign m = 
	      mpassm ? mmem_latched :
	      pdldrive ? pdl_latch :
	      spcdrive ? {3'b0, spcptr, 5'b0, spco_latched} :
	      mfdrive ? mf :
              32'b0;


   // page MMEM

//xxx was sync
   part_32x32ram i_MMEM(
			.clk_a(clk),
			.reset(reset),
			.address_a(madr),
			.data_a(l),
			.q_a(mmem),
			.wren_a(mwp),
			.rden_a(1'b1)
			);

   // page MO

   //for (i = 0; i < 31; i++)
   //  assign mo[i] =
   //	osel == 2'b00 ? (msk[i] ? r[i] : a[i]) : a[i];

   // msk r  a       (msk&r)|(~msk&a)
   //  0  0  0   0      0 0  0
   //  0  0  1   1      0 1  1
   //  0  1  0   0      0 0  0
   //  0  1  1   1      0 1  1
   //  1  0  0   0      0 0  0 
   //  1  0  1   0      0 0  0
   //  1  1  0   1      1 0  1 
   //  1  1  1   1      1 0  1

   // masker output 
   assign mo = (msk & r) | (~msk & a);

   assign ob =
	      osel == 2'b00 ? mo :
	      osel == 2'b01 ? alu[31:0] :
	      osel == 2'b10 ? alu[32:1] :
	      /*2'b11*/ {alu[30:0],q[31]};


   // page MSKG4

   part_32x32prom_maskleft i_MSKR(
				  .clk(~clk),
				  .q(msk_left_out),
				  .addr(mskl)
				  );

   part_32x32prom_maskright i_MSKL(
				   .clk(~clk),
				   .q(msk_right_out),
				   .addr(mskr)
				   );

   assign msk = msk_right_out & msk_left_out;


   // page NPC

   assign npc = 
		trap ? 14'b0 :
		{pcs1,pcs0} == 2'b00 ? { spc[13:2], spc1a, spc[0] } :
		{pcs1,pcs0} == 2'b01 ? { ir[25:12] } :
		{pcs1,pcs0} == 2'b10 ? dpc :
                 /*2'b11*/ ipc;

   always @(posedge clk)
     if (reset)
       pc <= 0;
     else
       if (state_fetch)
	 pc <= npc;

   assign ipc = pc + 14'd1;

`ifdef debug_dispatch
   always @(posedge clk)
     if (state_fetch && irdisp/*({pcs1,pcs0} == 2'b10)*/)
       begin
	  $display("dispatch: dadr=%o %b%b%b %o; dmask %o r %o ir %b vmo %b md %o; mapi %o vmap %o vmem1_adr %o vmo %o",
		   dadr, dr, dp, dn, dpc, dmask, r[11:0],
		   {ir[8], ir[9]}, {vmo[19],vmo[18]}, md,
		   mapi[23:13], vmap, vmem1_adr, vmo);
       end
`endif
   
`ifdef debug_detail
   always @(posedge clk)
     if (~reset)
       begin
	  $display("; npc %o ipc %o, spc %o, pc %o pcs %b%b state %b",
		   npc, ipc, spc, pc, pcs1, pcs0, state);
	  $display("; spcpass=%b, spcwpass=%b, spco_latched %o, spcw %o",
	  	   spcpass, spcwpass, spco_latched, spcw);
	  $display("; %b %b %b %b (%b %b)", 
		   (popj & ~ignpopj),
		   (jfalse & ~jcond),
		   (irjump & ~ir[6] & jcond),
		   (dispenb & dr & ~dp),
		   popj, ignpopj);
	  $display("; conds=%b,  aeqm=%b, aeqm_bits=%b",
		   conds, aeqm, aeqm_bits);
	  $display("; trap=%b,  parerr_n=%b, trapenb=%b boot_trap=%b",
		   trap, parerr, trapenb, boot_trap);
	  $display("; nopa %b, inop %b, nop11 %b",
		   nopa, inop, nop11);
       end
`endif

   // page OPCD

   assign dcdrive = srcdc & phase1; 	/* dispatch constant */

   assign opcdrive  = srcopc & phase1;


   // page PDL

//xxx was sync
   part_1kx32ram_p i_PDL(
			 .clk_a(clk),
			 .reset(reset),
			 .address_a(pdla),
			 .q_a(pdl),
			 .data_a(l),
			 .wren_a(pwp),
			 .rden_a(1'b1)
			 );
   
   // page PDLCTL

   /* m-src = pdl buffer, or index based write */
   assign pdlp = (phase0 & ir[30]) | (~phase0 & ~pwidx);

   assign pdla = pdlp ? pdlptr : pdlidx;

   assign pdlwrite = destpdltop | destpdl_x | destpdl_p;

   always @(posedge clk)
     if (reset)
       begin
	  pdlwrited <= 0;
	  pwidx <= 0;
	  imodd <= 0;
	  destspcd <= 0;
       end
     else
       if (phase1)
	 begin
	    pdlwrited <= pdlwrite;
	    pwidx <= destpdl_x;
	    imodd <= imod;
	    destspcd <= destspc;
	 end

   assign pwp = pdlwrited & state_write;

   assign pdlenb = srcpdlpop | srcpdltop;

   assign pdldrive = pdlenb & phase1;
   
   assign pdlcnt = (~nop & srcpdlpop) | destpdl_p;

   
   // page PDLPTR

   assign pidrive = phase1 & srcpdlidx;

   assign ppdrive  = phase1 & srcpdlptr;

   always @(posedge clk)
     if (reset)
       pdlidx <= 0;
     else
       if (state_write && destpdlx)
	 pdlidx <= ob[9:0];

   always @(posedge clk)
     if (reset)
       pdlptr <= 0;
     else
       if (state_fetch)
	 begin
	    if (destpdlp)
	      pdlptr <= ob[9:0];
	    else
	      if (pdlcnt)
		begin
		   if (srcpdlpop)
		     pdlptr <= pdlptr - 10'd1;
		   else
		     pdlptr <= pdlptr + 10'd1;
		end
	 end

   // page PLATCH

   // transparent latch w/async reset
   always @(reset or phase0 or pdl)
     if (reset)
       begin
	  pdl_latch = 0;
       end
     else
       if (phase0)
	 pdl_latch = pdl;


   // page Q

   assign qs1 = ir[1] & iralu;
   assign qs0 = ir[0] & iralu;

   assign qdrive = srcq & phase1;

   always @(posedge clk)
     if (reset)
       q <= 0;
     else
       if (state_fetch && (qs1 | qs0))
	 begin
            case ( {qs1,qs0} )
              2'b00: q <= q;
	      2'b01: q <= { q[30:0], ~alu[31] };
              2'b10: q <= { alu[0], q[31:1] };
              2'b11: q <= alu[31:0];
            endcase
	 end


   // page SHIFT0-1

   assign sa =
	      {s1,s0} == 2'b00 ? m :
	      {s1,s0} == 2'b01 ? { m[30:0], m[31] } : 
	      {s1,s0} == 2'b10 ? { m[29:0], m[31], m[30] } : 
	      { m[28:0], m[31], m[30], m[29] };

   assign {r[12],r[8],r[4],r[0]} =
		{s4,s3,s2} == 3'b000 ? { sa[12],sa[8], sa[4], sa[0] } :
		{s4,s3,s2} == 3'b001 ? { sa[8], sa[4], sa[0], sa[28] } :
		{s4,s3,s2} == 3'b010 ? { sa[4], sa[0], sa[28],sa[24] } :
		{s4,s3,s2} == 3'b011 ? { sa[0], sa[28],sa[24],sa[20] } :
		{s4,s3,s2} == 3'b100 ? { sa[28],sa[24],sa[20],sa[16] } :
		{s4,s3,s2} == 3'b101 ? { sa[24],sa[20],sa[16],sa[12] } :
		{s4,s3,s2} == 3'b110 ? { sa[20],sa[16],sa[12],sa[8] } :
		{ sa[16],sa[12],sa[8], sa[4] };

   assign {r[13],r[9],r[5],r[1]} =
		{s4,s3,s2} == 3'b000 ? { sa[13],sa[9], sa[5], sa[1] } :
		{s4,s3,s2} == 3'b001 ? { sa[9], sa[5], sa[1], sa[29] } :
		{s4,s3,s2} == 3'b010 ? { sa[5], sa[1], sa[29],sa[25] } :
		{s4,s3,s2} == 3'b011 ? { sa[1], sa[29],sa[25],sa[21] } :
		{s4,s3,s2} == 3'b100 ? { sa[29],sa[25],sa[21],sa[17] } :
		{s4,s3,s2} == 3'b101 ? { sa[25],sa[21],sa[17],sa[13] } :
		{s4,s3,s2} == 3'b110 ? { sa[21],sa[17],sa[13],sa[9] } :
		{ sa[17],sa[13],sa[9], sa[5] };

   assign {r[14],r[10],r[6],r[2]} =
		{s4,s3,s2} == 3'b000 ? { sa[14],sa[10],sa[6], sa[2] } :
		{s4,s3,s2} == 3'b001 ? { sa[10],sa[6], sa[2], sa[30] } :
		{s4,s3,s2} == 3'b010 ? { sa[6], sa[2], sa[30],sa[26] } :
		{s4,s3,s2} == 3'b011 ? { sa[2], sa[30],sa[26],sa[22] } :
		{s4,s3,s2} == 3'b100 ? { sa[30],sa[26],sa[22],sa[18] } :
		{s4,s3,s2} == 3'b101 ? { sa[26],sa[22],sa[18],sa[14] } :
		{s4,s3,s2} == 3'b110 ? { sa[22],sa[18],sa[14],sa[10] } :
		{ sa[18],sa[14],sa[10], sa[6] };

   assign {r[15],r[11],r[7],r[3]} =
		{s4,s3,s2} == 3'b000 ? { sa[15],sa[11],sa[7], sa[3] } :
		{s4,s3,s2} == 3'b001 ? { sa[11],sa[7], sa[3], sa[31] } :
		{s4,s3,s2} == 3'b010 ? { sa[7], sa[3], sa[31],sa[27] } :
		{s4,s3,s2} == 3'b011 ? { sa[3], sa[31],sa[27],sa[23] } :
		{s4,s3,s2} == 3'b100 ? { sa[31],sa[27],sa[23],sa[19] } :
		{s4,s3,s2} == 3'b101 ? { sa[27],sa[23],sa[19],sa[15] } :
		{s4,s3,s2} == 3'b110 ? { sa[23],sa[19],sa[15],sa[11] } :
		{ sa[19],sa[15],sa[11], sa[7] };

   //

   assign {r[28],r[24],r[20],r[16]} =
		{s4,s3,s2} == 3'b000 ? { sa[28],sa[24],sa[20],sa[16] } :
		{s4,s3,s2} == 3'b001 ? { sa[24],sa[20],sa[16],sa[12] } :
		{s4,s3,s2} == 3'b010 ? { sa[20],sa[16],sa[12],sa[8] } :
		{s4,s3,s2} == 3'b011 ? { sa[16],sa[12],sa[8], sa[4] } :
		{s4,s3,s2} == 3'b100 ? { sa[12],sa[8],sa[4], sa[0] } :
		{s4,s3,s2} == 3'b101 ? { sa[8], sa[4],sa[0], sa[28] } :
		{s4,s3,s2} == 3'b110 ? { sa[4], sa[0],sa[28],sa[24] } :
		{ sa[0],sa[28],sa[24],sa[20] };

   assign {r[29],r[25],r[21],r[17]} =
		{s4,s3,s2} == 3'b000 ? { sa[29],sa[25],sa[21],sa[17] } :
		{s4,s3,s2} == 3'b001 ? { sa[25],sa[21],sa[17],sa[13] } :
		{s4,s3,s2} == 3'b010 ? { sa[21],sa[17],sa[13],sa[9] } :
		{s4,s3,s2} == 3'b011 ? { sa[17],sa[13],sa[9], sa[5] } :
		{s4,s3,s2} == 3'b100 ? { sa[13],sa[9],sa[5], sa[1] } :
		{s4,s3,s2} == 3'b101 ? { sa[9], sa[5],sa[1], sa[29] } :
		{s4,s3,s2} == 3'b110 ? { sa[5], sa[1],sa[29],sa[25] } :
		{ sa[1],sa[29],sa[25],sa[21] };

   assign {r[30],r[26],r[22],r[18]} =
		{s4,s3,s2} == 3'b000 ? { sa[30],sa[26],sa[22],sa[18] } :
		{s4,s3,s2} == 3'b001 ? { sa[26],sa[22],sa[18],sa[14] } :
		{s4,s3,s2} == 3'b010 ? { sa[22],sa[18],sa[14],sa[10] } :
		{s4,s3,s2} == 3'b011 ? { sa[18],sa[14],sa[10], sa[6] } :
		{s4,s3,s2} == 3'b100 ? { sa[14],sa[10],sa[6], sa[2] } :
		{s4,s3,s2} == 3'b101 ? { sa[10],sa[6], sa[2], sa[30] } :
		{s4,s3,s2} == 3'b110 ? { sa[6], sa[2], sa[30],sa[26] } :
		                       { sa[2], sa[30],sa[26],sa[22] };
	
   assign {r[31],r[27],r[23],r[19]} =
		{s4,s3,s2} == 3'b000 ? { sa[31],sa[27],sa[23],sa[19] } :
		{s4,s3,s2} == 3'b001 ? { sa[27],sa[23],sa[19],sa[15] } :
		{s4,s3,s2} == 3'b010 ? { sa[23],sa[19],sa[15],sa[11] } :
		{s4,s3,s2} == 3'b011 ? { sa[19],sa[15],sa[11],sa[7] } :
		{s4,s3,s2} == 3'b100 ? { sa[15],sa[11],sa[7], sa[3] } :
		{s4,s3,s2} == 3'b101 ? { sa[11],sa[7], sa[3], sa[31] } :
		{s4,s3,s2} == 3'b110 ? { sa[7], sa[3], sa[31],sa[27] } :
		                       { sa[3], sa[31],sa[27],sa[23] };


   // page SMCTL

   assign mr = ~irbyte | ir[13];
   assign sr = ~irbyte | ir[12];

   assign mskr[4] = mr & sh4;
   assign mskr[3] = mr & sh3;
   assign mskr[2] = mr & ir[2];
   assign mskr[1] = mr & ir[1];
   assign mskr[0] = mr & ir[0];

   assign s4 = sr & sh4;
   assign s3 = sr & sh3;
   assign s2 = sr & ir[2];
   assign s1 = sr & ir[1];
   assign s0 = sr & ir[0];

   assign mskl = mskr + ir[9:5];


   // page SOURCE

   assign {irbyte,irdisp,irjump,iralu} =
	  nop ? 4'b0000 :
		({ir[44],ir[43]} == 2'b00) ? 4'b0001 :
		({ir[44],ir[43]} == 2'b01) ? 4'b0010 :
		({ir[44],ir[43]} == 2'b10) ? 4'b0100 :
	                                     4'b1000 ;

   assign funct = 
	  nop ? 4'b0000 :
		({ir[11],ir[10]} == 2'b00) ? 4'b0001 :
		({ir[11],ir[10]} == 2'b01) ? 4'b0010 :
		({ir[11],ir[10]} == 2'b10) ? 4'b0100 :
	                                     4'b1000 ;

   assign specalu  = ir[8] & iralu;

   assign {div,mul} =
		     ~specalu ? 2'b00 :
   		     ({ir[4],ir[3]} == 2'b00) ? 2'b01 : 2'b10;

   assign {srcq,srcopc,srcpdltop,srcpdlpop,
	   srcpdlidx,srcpdlptr,srcspc,srcdc} =
	  (~ir[31] | ir[29]) ? 8'b00000000 :
		({ir[28],ir[27],ir[26]} == 3'b000) ? 8'b00000001 :
		({ir[28],ir[27],ir[26]} == 3'b001) ? 8'b00000010 :
		({ir[28],ir[27],ir[26]} == 3'b010) ? 8'b00000100 :
		({ir[28],ir[27],ir[26]} == 3'b011) ? 8'b00001000 :
		({ir[28],ir[27],ir[26]} == 3'b100) ? 8'b00010000 :
		({ir[28],ir[27],ir[26]} == 3'b101) ? 8'b00100000 :
		({ir[28],ir[27],ir[26]} == 3'b110) ? 8'b01000000 :
		                                     8'b10000000;

   assign {srcspcpop,srclc,srcmd,srcmap,srcvma} =
	  (~ir[31] | ~ir[29]) ? 5'b00000 :
		({ir[28],ir[27],ir[26]} == 3'b000) ? 5'b00001 :
		({ir[28],ir[27],ir[26]} == 3'b001) ? 5'b00010 :
		({ir[28],ir[27],ir[26]} == 3'b010) ? 5'b00100 :
		({ir[28],ir[27],ir[26]} == 3'b011) ? 5'b01000 :
		({ir[28],ir[27],ir[26]} == 3'b100) ? 5'b10000 :
		                                     5'b00000 ;

   assign imod = destimod0 | destimod1 | iwrited | idebug;

   assign destmem = destm & ir[23];
   assign destvma = destmem & ~ir[22];
   assign destmdr = destmem & ir[22];

   assign dest = iralu | irbyte;	/* destination field is valid */
   assign destm = dest & ~ir[25];	/* functional destination */

   assign {destintctl,destlc} =
	  !(destm & ~ir[23] & ~ir[22]) ? 2'b00 :
		({ir[21],ir[20],ir[19]} == 3'b001) ? 2'b01 :
		({ir[21],ir[20],ir[19]} == 3'b010) ? 2'b10 :
		                                     2'b00 ;

   assign {destimod1,destimod0,destspc,destpdlp,
	   destpdlx,destpdl_x,destpdl_p,destpdltop} =
	  !(destm & ~ir[23] & ir[22]) ? 8'b00000000 :
		({ir[21],ir[20],ir[19]} == 3'b000) ? 8'b00000001 :
		({ir[21],ir[20],ir[19]} == 3'b001) ? 8'b00000010 :
		({ir[21],ir[20],ir[19]} == 3'b010) ? 8'b00000100 :
		({ir[21],ir[20],ir[19]} == 3'b011) ? 8'b00001000 :
		({ir[21],ir[20],ir[19]} == 3'b100) ? 8'b00010000 :
		({ir[21],ir[20],ir[19]} == 3'b101) ? 8'b00100000 :
		({ir[21],ir[20],ir[19]} == 3'b110) ? 8'b01000000 :
		({ir[21],ir[20],ir[19]} == 3'b111) ? 8'b10000000 :
		                                     8'b00000000;

    // page SPC

//xxx was sync
   part_32x19ram i_SPC(
		       .clk_a(clk),
		       .reset(reset),
		       .address_a(spcptr),
		       .data_a(spcw),
		       .q_a(spco),
		       .wren_a(swp),
		       .rden_a(1'b1)
		       );
   
   always @(posedge clk)
     if (reset)
       spcptr <= 0;
     else
       if (state_fetch)
	 begin
	    if (spcnt)
	      begin
		 if (spush)
		   spcptr <= spcptr + 5'd1;
		 else
		   spcptr <= spcptr - 5'd1;
	      end
	 end

   
   // page SPCLCH

   // mux SPC
   assign spc = 
		spcpass ? spco_latched :
		spcwpass ? spcw :
	        19'b0;

   // transparent latch w/async reset
   always @(phase0 or spco or reset)
     if (reset)
       spco_latched = 0;
     else
       if (phase0)
         spco_latched = spco;


   // page SPCPAR

   
   // page SPCW

   assign spcw = destspcd ? l[18:0] : { 5'b0, reta };

   always @(posedge clk)
     if (reset)
       reta <= 0;
     else
       if (state_fetch)
	 reta <= n ? wpc : ipc;


   // page SPY1-2

   wire[15:0] spy_mux;

   assign spy_out = dbread ? spy_mux : 16'b1111111111111111;

   assign spy_mux =
	spy_irh ? ir[47:32] :
	spy_irm ? ir[31:16] :
	spy_irl ? ir[15:0] :
	spy_obh ? ob[31:16] :
	spy_obl ? ob[15:0] :
	spy_ah  ? a[31:16] :
	spy_al  ? a[15:0] :
	spy_mh  ? m[31:16] :
	spy_ml  ? m[15:0] :
	spy_flag2 ?
			{ 2'b0,wmapd,destspcd,iwrited,imodd,pdlwrited,spushd,
			  2'b0,ir[48],nop,vmaok,jcond,pcs1,pcs0 } :
	spy_opc ?
			{ 2'b0,opc } :
	spy_flag1 ?
			{ waiting, v1pe, v0pe, promdisable,
			  stathalt, err, ssdone, srun,
			  higherr, mempe, ipe, dpe,
			  spe, pdlpe, mpe, ape } :
	spy_pc ?
			{ 2'b0,pc } :
        16'b1111111111111111;



   // page TRAP

   assign mdparerr = 1'b0;

   assign parerr = mdparerr & mdhaspar & use_md & ~waiting;

   assign memparok = ~parerr | trapenb;

   assign trap = (parerr & trapenb) | boot_trap;


   // page VCTRL1

   assign memop  = memrd | memwr | ifetch;
   assign memprepare = memop;

   always @(posedge clk)
     if (reset)
       begin
	  memstart <= 0;
	  mbusy_sync <= 0;
       end
     else
       if (phase1)
	 begin
	    memstart <= memprepare;
	    mbusy_sync <= memrq;
	 end

   assign pfw = (lvmo_23 & lvmo_22) & wrcyc;	/* write permission */
   assign pfr = lvmo_23 & ~wrcyc;		/* read permission */

   always @(posedge clk)
     if (reset) 
       vmaok <= 1'b0;
     else
       if (memprepare)
	 begin
	    last_pfr <= pfr;
	    last_pfw <= wrcyc ? pfw : 1'b1; /* wrong, but matches usim */
	    vmaok <= pfr | pfw;
	 end
    
   always @(posedge clk)
     if (reset)
	  wmapd <= 0;
     else
       if (state_write)
	 wmapd <= wmap;
   
   always @(posedge clk)
     if (reset)
       begin
	  rdcyc <= 0;
	  wrcyc <= 0;
       end
     else
       if (state_write && memprepare)
	 begin
	    if (memwr)
	      begin
		 rdcyc <= 0;
		 wrcyc <= 1;
	      end
	    else
	      begin
		 rdcyc <= 1;
		 wrcyc <= 0;
	      end
	 end
       else
	 if (~memrq && ~memprepare && ~memstart)
	   begin
	      rdcyc <= 0;
	      wrcyc <= 0;
	   end

   assign memrq = mbusy | (memstart & (pfr | pfw));

`ifdef debug_xbus
   always @(posedge clk)
     begin
	if (memstart & ~vmaok)
	  $display("xbus: access fault, l1[%o]=%o, l2[%o]= %b%b %o; %t",
		   mapi[23:13], vmap,
		   vmem1_adr, vmo[23], vmo[22], vmo[21:0],
		   $time);
	if (memstart & vmaok)
	  $display("xbus: start l1[%o]=%o, l2[%o]= %b%b %o",
		   mapi[23:13], vmap,
		   vmem1_adr, vmo[23], vmo[22], vmo[21:0]);
     end
`endif
   
   always @(posedge clk)
     if (reset)
       mbusy <= 0;
     else
       if (mfinishd)
	 mbusy <= 1'b0;
       else
	 mbusy <= memrq;

   //------

   assign mfinish = memack | reset;

   always @(posedge clk)
     if (reset)
       mfinishd <= 1'b0;
     else
       mfinishd <= mfinish;
   
   assign waiting =
		(destmem & mbusy/*_sync*/) |
		(use_md & mbusy /*& ~memgrant*/) |	/* hang loses */
		(lcinc & needfetch & mbusy/*_sync*/);	/* ifetch */

   // page VCTRL2

   assign mapwr0d = wmapd & vma[26];
   assign mapwr1d = wmapd & vma[25];

   assign vm0wp = mapwr0d & state_write;
   assign vm1wp = mapwr1d & state_write;

   assign vmaenb = destvma | ifetch;
   assign vmasel = ~ifetch;

   // external?
   assign lm_drive_enb = 0;

   assign memdrive = wrcyc & lm_drive_enb;

   assign mdsel = destmdr & ~loadmd/*& ~state_write*/;

   assign use_md  = srcmd & ~nopa;

   assign {wmap,memwr,memrd} =
			      ~destmem ? 3'b000 :
			      (ir[20:19] == 2'b01) ? 3'b001 :
			      (ir[20:19] == 2'b10) ? 3'b010 :
			      (ir[20:19] == 2'b11) ? 3'b100 :
	                      3'b000 ;

   // page VMA

   always @(posedge clk)
     if (reset)
       vma <= 0;
     else
       if (state_write && vmaenb)
	 vma <= vmas;

   assign vmadrive = srcvma & phase1;


   // page VMAS

   assign vmas = vmasel ? ob : { 8'b0, lc[25:2] };

   assign mapi = ~memstart ? md[23:8] : vma[23:8];


   // page VMEM0 - virtual memory map stage 0

//xxx was async
   part_2kx5ram i_VMEM0(
			.clk_a(clk),
			.reset(reset),
			.address_a(mapi[23:13]),
			.q_a(vmap),
			.data_a(vma[31:27]),
			.wren_a(vm0wp),
			.rden_a(1'b1)
			);

`ifdef debug
   always @(vm0wp or mapwr0d or state_write)
     if (vm0wp)
       $display("vm0wp %b, a=%o, di=%o; %t",
		vm0wp, mapi[23:13], vma[31:27], $time);

   always @(vm1wp or mapwr1d or state_write)
     if (vm1wp)
       $display("vm1wp %b, a=%o, di=%o; %t",
		vm1wp, vmem1_adr, vma[23:0], $time);
`endif
   
   assign use_map = srcmap | memstart;

   // page VMEM1&2

   assign vmem1_adr = {vmap[4:0], mapi[12:8]};

   assign vmem1_we = vm1wp & ~clk;
   
//xxx was async
   part_1kx24ram i_VMEM1(
			 .clk_a(clk),
			 .reset(reset),
			 .address_a(vmem1_adr),
			 .q_a(vmo),
			 .data_a(vma[23:0]),
			 .wren_a(vmem1_we),
			 .rden_a(1'b1)
			 );

   // page VMEMDR - map output drive

   // transparent latch
   always @(memprepare or memstart or vmo or reset or clk)
     if (reset)
       begin
	  lvmo_23 = 0;
	  lvmo_22 = 0;
	  pma = 0;
       end
     else
       if (memprepare && memstart)
	 begin
	    lvmo_23 = vmo[23];
	    lvmo_22 = vmo[22];
	    pma = vmo[13:0];
	 end

   assign mapdrive = srcmap & phase1;

   
`ifdef debug_vmem
   always @(memprepare or memstart or mapi or vmo or vmap or clk)
     if (memprepare && memstart)
       begin
	  $display("%t prep vmem0_adr %o, vmap=%o",
		   $time, mapi[23:13], vmap);
	  $display("%t prep vmem1_adr %o, vma=%o, vmo[23:22]=%b%b, vmo=%o",
		   $time, vmem1_adr, vma, vmo[23], vmo[22], vmo[21:0]);
       end
   
   always @(memrq)
     if (memrq)
       begin
	  $display("%t req vmem0_adr %o, vmap=%o",
		   $time, mapi[23:13], vmap);
	  $display("%t req vmem1_adr %o, vma=%o, vmo[23:22]=%b, vmo[21:0]=%o",
		   $time, vmem1_adr, vma, {vmo[23], vmo[22]}, vmo[21:0]);
	  $display("%t req lvmo_23,22 %b%b, pma=%o",
		   $time, lvmo_23, lvmo_22, pma);
       end
`endif
  
   // page DEBUG

   always @(posedge lddbirh or posedge reset)
     if (reset)
       spy_ir[47:32] <= 16'b0;
     else
       spy_ir[47:32] <= spy_in;

   always @(posedge lddbirm or posedge reset)
     if (reset)
       spy_ir[31:16] <= 16'b0;
     else
       spy_ir[31:16] <= spy_in;

   always @(posedge lddbirl or posedge reset)
     if (reset)
       spy_ir[15:0] <= 16'b0;
     else
       spy_ir[15:0] <= spy_in;

   // put latched value on I bus when idebug asserted
   assign i =
	     idebug ? {1'b0, spy_ir} :
	     promenable ? iprom :
	     iram;

   
   // page ICTL - I RAM control

   assign ramdisable = idebug | ~(promdisabled | iwrited);

   // see clocks below
   wire   iwe;
   assign iwe = state_write & iwrited;


   // page OLORD1 

   always @(posedge clk)
     if (reset)
       begin
	  promdisable <= 0;
	  trapenb <= 0;
	  stathenb <= 0;
	  errstop <= 0;
       end
     else
       if (ldmode)
	 begin
	    promdisable <= spy_in[5];
	    trapenb <= spy_in[4];
	    stathenb <= spy_in[3];
	    errstop <= spy_in[2];
	    //speed1 <= spy_in[1];
	    //speed0 <= spy_in[0];
	 end
       else
	 if (set_promdisable)
	   promdisable <= 1;
	   
   always @(posedge clk)
     if (reset)
       begin
	  opcinh <= 0;
	  opcclk <= 0;
	  lpc_hold <= 0;
       end
     else
       if (ldopc)
	 begin
	    opcinh <= spy_in[2];
	    opcclk <= spy_in[1];
	    lpc_hold <= spy_in[0];
	 end

   always @(posedge clk)
     if (reset)
       begin
	  ldstat <= 0;
	  idebug <= 0;
	  nop11 <= 0;
	  step <= 0;
       end
     else
       if (ldclk)
	 begin
	    ldstat <= spy_in[4];
	    idebug <= spy_in[3];
	    nop11 <= spy_in[2];
	    step <= spy_in[1];
	 end

   always @(posedge clk)
     if (reset)
       run <= 1'b0;
     else
       if (boot)
	 run <= 1'b1;
       else
	 if (ldclk)
	   run <= spy_in[0];

   always @(posedge clk)
     if (reset)
       begin
	  srun <= 1'b0;
	  sstep <= 1'b0;
	  ssdone <= 1'b0;
	  promdisabled <= 1'b0;
       end
     else
       begin
	  srun <= run;
	  sstep <= step;
	  ssdone <= sstep;
	  promdisabled <= promdisable;
`ifdef debug
	  if (promdisable == 1 && promdisabled == 0)
	    $display("prom: disabled");
`endif
       end

   assign machrun = (sstep & ~ssdone) |
		    (srun & ~errhalt & ~waiting & ~stathalt);

   assign stat_ovf = 1'b0;
   assign stathalt = statstop & stathenb;


   // page OLORD2

   always @(posedge clk)
     if (reset)
       begin
	  halted <= 0;
	  statstop <= 0;
       end
     else
       begin
	  halted <= ext_halt;
	  statstop <= stat_ovf;
       end
   
   always @(posedge clk)
     if (reset)
       begin
	  ape <= 0;
	  mpe <= 0;
	  pdlpe <= 0;
	  dpe <= 0;
	  ipe <= 0;
	  spe <= 0;
	  higherr <= 0;
	  mempe <= 0;

	  v0pe <= 0;
	  v1pe <= 0;
       end
     else
       begin
	  ape <= 1'b0;
	  mpe <= 1'b0;
	  pdlpe <= 1'b0;
	  dpe <= 1'b0;
	  ipe <= ~iparok;
	  spe <= 1'b0;
	  higherr <= ~highok;
	  mempe <= ~memparok;

	  v0pe <= 1'b0;
	  v1pe <= 1'b0;
       end

   assign lowerhighok = 1'b1;
   assign highok = 1'b1;

   assign prog_reset = ldmode & spy_in[6];

   assign reset = ext_reset | prog_reset;

   assign err = ape | mpe | pdlpe | dpe |
		ipe | spe | higherr | mempe |
		v0pe | v1pe | halted;

   assign errhalt = errstop & err;

   // external
   assign prog_bus_reset = 0;

   assign bus_reset  = prog_bus_reset | ext_reset;

   // external

   assign prog_boot = ldmode & spy_in[7];

   assign boot  = ext_boot | prog_boot;

   always @(posedge clk)
     if (reset)
       boot_trap <= 0;
     else
       if (boot)
	 boot_trap <= 1'b1;
       else
	 if (srun)
           boot_trap <= 1'b0;


   // page OPCS

   assign opcclka = (state_fetch | opcclk) & ~opcinh;

   always @(posedge clk)
     if (reset)
       opc <= 0;
     else
       if (opcclka)
	 opc <= pc;

   // With the machine stopped, taking OPCCLK high then low will
   // generate a clock to just the OPCS.
   // Setting OPCINH high will prevent the OPCS from clocking when
   // the machine runs.  Only change OPCINH when CLK is high 
   // (e.g. machine stopped).


   // page PCTL

   assign bottom_1k = ~(pc[13] | pc[12] | pc[11] | pc[10]);
   assign promenable = bottom_1k & ~idebug & ~promdisabled & ~iwrited;

   assign promce = promenable & ~pc[9];

   assign prompc = pc[11:0];


   // page PROM0

   part_512x49prom i_PROM(
			  .clk(~clk),
			  .addr(~prompc[8:0]),
			  .q(iprom)
			  );


   // page IRAM
`ifdef use_ucode_ram
   part_16kx49ram i_IRAM(
			 .clk_a(clk),
			 .reset(reset),
			 .address_a(pc),
			 .q_a(iram),
			 .data_a(iwr),
			 .wren_a(iwe),
			 .rden_a(1'b1/*ice*/)
			 );
`else
   // use top level ram controller
   assign mcr_addr = pc;
   assign iram = mcr_data_in;
   assign mcr_data_out = iwr;
   assign mcr_write = iwe;
`endif

   // for externals
   assign fetch_out = state_fetch;
   assign prefetch_out = state_write;


   // page SPY0

   /* read registers */
   assign {spy_obh, spy_obl, spy_pc, spy_opc,
	   spy_nc, spy_irh, spy_irm, spy_irl} =
	  (eadr[3] & ~dbread) ? 8'b0000000 :
		({eadr[2],eadr[1],eadr[0]} == 3'b000) ? 8'b00000001 :
		({eadr[2],eadr[1],eadr[0]} == 3'b001) ? 8'b00000010 :
		({eadr[2],eadr[1],eadr[0]} == 3'b010) ? 8'b00000100 :
		({eadr[2],eadr[1],eadr[0]} == 3'b011) ? 8'b00001000 :
		({eadr[2],eadr[1],eadr[0]} == 3'b100) ? 8'b00010000 :
		({eadr[2],eadr[1],eadr[0]} == 3'b101) ? 8'b00100000 :
		({eadr[2],eadr[1],eadr[0]} == 3'b110) ? 8'b01000000 :
		                                        8'b00000000;

   /* read registers */
   assign {spy_sth, spy_stl, spy_ah, spy_al,
	   spy_mh, spy_ml, spy_flag2, spy_flag1} =
	  (~eadr[3] & ~dbread) ? 8'b00000000 :
		({eadr[2],eadr[1],eadr[0]} == 3'b000) ? 8'b00000001 :
		({eadr[2],eadr[1],eadr[0]} == 3'b001) ? 8'b00000010 :
		({eadr[2],eadr[1],eadr[0]} == 3'b010) ? 8'b00000100 :
		({eadr[2],eadr[1],eadr[0]} == 3'b011) ? 8'b00001000 :
		({eadr[2],eadr[1],eadr[0]} == 3'b100) ? 8'b00010000 :
		({eadr[2],eadr[1],eadr[0]} == 3'b101) ? 8'b00100000 :
		({eadr[2],eadr[1],eadr[0]} == 3'b110) ? 8'b01000000 :
		                                        8'b00000000;

   /* load registers */
   assign {ldmode, ldopc, ldclk, lddbirh, lddbirm, lddbirl} =
	  (~dbwrite) ? 6'b000000 :
		({eadr[2],eadr[1],eadr[0]} == 3'b000) ? 6'b000001 :
		({eadr[2],eadr[1],eadr[0]} == 3'b001) ? 6'b000010 :
		({eadr[2],eadr[1],eadr[0]} == 3'b010) ? 6'b000100 :
		({eadr[2],eadr[1],eadr[0]} == 3'b011) ? 6'b001000 :
		({eadr[2],eadr[1],eadr[0]} == 3'b100) ? 6'b010000 :
		({eadr[2],eadr[1],eadr[0]} == 3'b101) ? 6'b100000 :
		                                        6'b000000;

   // *******
   // Resets!
   // *******

// traditional CADR signals to xbus
// mem[31:0]
// mempar_in
// adrpar_n
// {pma[21:0],vma[7:0]}
// memrq_n
// memack_n
// loadmd_n
// ignpar_n
// memgrant_n
// wrcyc
// int
// mempar_out

   busint busint(
		 .mclk(clk),
		 .reset(reset),
		 .addr({pma,vma[7:0]}),
		 .busin(md),
		 .busout(busint_bus),
		 .spyin(spy_in),
		 .spyout(busint_spyout),

		 .req(memrq),
		 .ack(memack),
		 .write(wrcyc),
		 .load(loadmd),
		 
		 .interrupt(bus_int),

		 .sdram_addr(sdram_addr),
		 .sdram_data_in(sdram_data_in),
		 .sdram_data_out(sdram_data_out),
		 .sdram_req(sdram_req),
		 .sdram_ready(sdram_ready),
		 .sdram_write(sdram_write),
		 .sdram_done(sdram_done),
      
		 .vram_addr(vram_addr),
		 .vram_data_in(vram_data_in),
		 .vram_data_out(vram_data_out),
		 .vram_req(vram_req),
		 .vram_ready(vram_ready),
		 .vram_write(vram_write),
		 .vram_done(vram_done),
		 
		 .ide_data_in(ide_data_in),
		 .ide_data_out(ide_data_out),
		 .ide_dior(ide_dior),
		 .ide_diow(ide_diow),
		 .ide_cs(ide_cs),
		 .ide_da(ide_da),

		 .promdisable(set_promdisable)
		 );

endmodule

