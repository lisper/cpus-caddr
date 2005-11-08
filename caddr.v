/*
 * caddr
 * 10/2005 brad parker brad@heeltoe.com
 *
 */

`timescale 1ns / 1ns

`include "74181.v"
`include "74182.v"
`include "memory.v"
`include "rom.v"

`include "busint.v"

/*
 *   +++++++++++++++++++++++++++                    +--------
 *   |                         |                    |
 *   |                         |                    |
 * --+                         +--------------------+
 *
 *   ^                         ^
 *   |                         |
 *   |                      latch A&M memory output
 *  latch IR
 *
 */

module caddr ( osc50mhz, int, power_reset_n, boot1_n, boot2_n,
		spy, dbread_n, dbwrite_n, eadr  ) ;

input osc50mhz;
input int;
input power_reset_n, boot1_n, boot2_n;
inout[15:0] spy;
input dbread_n, dbwrite_n;
input[3:0] eadr;


wire[13:0] npc;
wire[13:0] dpc;
wire[13:0] ipc;
wire[18:0] spc;

reg[48:0] ir;

wire[31:0] a;
reg[31:0] a_latch;


reg[9:0] wadr;
reg destd, destmd;

wire apass, apass_n;
wire amemenb_n, apassenb_n;
wire awp_n;

wire[9:0] aadr;

wire[7:0] aeqm_bits;
wire aeqm;
wire[32:0] alu;

wire divposlasttime_n, divsubcond, divaddcond, aluadd, alusub, mulnop_n;
wire mul_n, div_n, specalu_n;

wire iralu;
wire[1:0] osel;

wire[3:0] aluf, aluf_n;
wire alumode_n, alumode, cin0_n;

wire[31:0] amem;

wire aparok;

wire dfall_n, dispenb, ignpopj_n, jfalse, jcalf, jretf, jret, iwrite;
wire ipopj_n, popj_n, srcspcpopreal_n;
wire spop_n, spush_n;

wire popj;

wire spcwpass_n, spcpass_n;
wire swp_n, spcenb, spcdrive_n, spcnt_n;

reg inop, spushd, iwrited; 
wire inop_n, spushd_n, iwrited_n;
wire n, pcs1, pcs0;

wire nopa_n, nopa, nop, nop_n;

// page DRAM0-2
wire[10:0] dadr_n;
wire dr, dp, dn;
wire daddr0_n;
wire[6:0] dmask;
wire dwe_n;

// page DSPCTL
wire dparh_n, dparl, dpareven, dparok, dmapbenb_n, dispwr;
reg[9:0] dc;
wire[11:0] prompc_n;

// page FLAG
wire statbit_n, ilong_n, aluneg;
wire pgf_or_int, pgf_or_int_or_sb, sint;

wire[2:0] conds;
wire jcond;
reg lc_byte_mode, prog_unibus_reset, int_enable, sequence_break;

// page IOR
wire[47:0] iob;
wire[31:0] ob;

// page IPAR
wire[3:0] ipar;
wire iparity, iparok;

// page L
wire lparl, lparm_n, lparity, lparity_n;

// page LC
reg[25:0] lc;
wire[3:0] lca;
wire lcry3;

wire lcdrive_n;
wire sh4_n, sh3_n;

wire[31:0] mf;

wire lc0b, next_instr, newlc_in_n, have_wrong_word, last_byte_in_word;
wire needfetch, ifetch_n, spcmung, spc1a, lcinc, lcinc_n;
wire newlc_n;

reg newlc, sintr, next_instrd;

wire int;

wire lc_modifies_mrot_n, inst_in_left_half, inst_in_2nd_or_4th_quarter;

wire[13:0] wpc;

// page MCTL
wire mpass, mpass_n, mpassl_n, mpassm_n;
wire srcm, mwp_n;
wire[4:0] madr;

// page MD
reg[31:0] md;
reg mdhaspar, mdpar;
wire mddrive_n, mdgetspar, mdclk;
wire mempar_in;

wire loadmd, ignpar_n;

// page MDS
wire[31:0] mds;
wire[31:0] mem;
wire[31:0] busint_bus;
wire mempar_out;

wire mdparodd;

// page MF
wire mfenb, mfdrive_n;

// page MLATCH
reg[31:0] mmem_latched;
wire mmemparity;

wire mmemparok;
wire[31:0] m;

// page MMEM
wire[31:0] mmem;

wire[31:0] mo;

wire[31:0] msk_right_out, msk_left_out, msk;

wire dcdrive, opcdrive_n, zero16, zero12_drive, zero16_drive, zero16_drive_n;

// page PDL
wire pdlparity;
wire[31:0] pdl;

// page PDLCTL
wire[9:0] pdla;
wire pdlp_n, pdlwrite;
wire pwp_n, pdlenb, pdldrive_n, pdlcnt_n;
wire imodd_n;
wire destspcd;
reg pdlwrited, pwidx_n, imodd, destspcd_n;

// page PDLPTR
wire pidrive, ppdrive_n;
reg[9:0]pdlidx;

// page Q
reg[31:0] q;
wire qs1, qs0, srcq, qdrive;

// page SHIFT0-1
wire[31:0] sa;
wire[31:0] r;

// page SMCTL
wire mr_n, sr_n, s1, s0;
wire[4:0] mskr;

wire s4, s4_n, s3, s2;
wire[4:0] mskl;

// page SOURCE
wire irbyte_n, irdisp_n, irjump_n, iralu_n;
wire irdisp, irjump;

wire[3:0] funct;
wire funct2_n;

wire srcq_n, srcopc_n, srcpdltop_n, srcpdlpop_n,
	srcpdlidx_n, srcpdlptr_n, srcspc_n, srcdc_n;
wire srcspcpop_n, srclc_n, srcmd_n, srcmap_n, srcvma_n;

wire srclc;
wire imod;

wire destmem_n, destvma_n, destmdr_n, dest, destm;
wire destintctl_n, destlc_n;
wire destimod1_n, destimod0_n, destspc_n, destpdlp_n,
	destpdlx_n, destpdl_x_n, destpdl_p_n, destpdltop_n;

wire destspc;

// page SPC
reg[4:0] spcptr;

wire [18:0] spcw;
wire [18:0] spco;

wire spcopar;

// page SPCPAR
wire spcwpar, spcwparl_n, spcwparh, spcparok;


wire halt_n;

wire mdparerr, parerr_n, memparok_n, memparok, trap_n, trap;
reg boot_trap;

wire mdpareven;

// page VCTRL1
reg memstart, mbusy_sync;
wire memop_n, memprepare, memstart_n;

reg wrcyc, wmapd, mbusy;
wire rdcyc, pfw_n, pfr_n, vmaok_n, wmapd_n, memrq;

wire set_rd_in_progess, mfinish_n;
reg rd_in_progress;

wire memack_n, memgrant_n;

wire mfinishd_n, rdfinish_n;
wire wait_n;

// page VCTRL2
wire mapwr0d, mapwr1d, vm0wp_n, vm1wp_n;
wire vmaenb_n, vmasel;
wire memdrive_n, mdsel, use_md;
wire wmap_n, memwr_n, memrd_n;

wire lm_drive_enb;

wire wmap;

// page VMA
reg[31:0] vma;
wire vmadrive_n;

// page VMAS
wire[31:0] vmas;

wire[23:8] mapi;
wire[12:8] mapi_n;

wire[4:0] vmap_n;

// page VMEM0 - virtual memory map stage 0
wire srcmap, use_map_n;
wire vmoparck, v0parok, vm0pari, vmoparodd;

wire vmopar;

wire[23:0] vmo_n, vmo;

wire[4:0] vmap;

wire vm1mpar, vm1lpar;

wire mapdrive_n;
wire vm0par, vm0parm, vm0parl, adrpar_n;

wire[48:0] i;
wire[48:0] iprom;
wire[48:0] iram;
reg[47:0] spy_ir;

wire ramdisable, promdisabled_n;

reg opcinh, opcclk, lpc_hold;
wire opcinh_n, opcclk_n;

reg ldstat, idebug, nop11, step;
wire ldstat_n, idebug_n, nop11_n, step_n;

reg run;

wire machrun, ssdone_n, stat_ovf, stathalt_n;

wire spcoparok, vm0parok, pdlparok;

wire lowerhighok_n, highok, ldmode;
wire prog_reset_n, reset, reset_n;
wire err, errhalt_n;
wire bus_reset_n, bus_power_reset_n;
wire power_reset;
wire clock_reset_n, prog_boot, boot_n;

wire prog_bus_reset;

wire busint_lm_reset_n;

wire opcclka;

// page PCTL
wire promenable_n, promce_n, bottom_1k;

reg mparity;
reg[31:0] pdl_latch;

// page SPCLCH
reg[18:0] spco_latched;
reg spcpar;

// page OLORD1 
reg promdisable;
reg trapenb;
reg stathenb;
reg errstop;
reg speed1, speed0;

reg srun, sstep, ssdone, promdisabled;

reg speed0a, speed1a;
reg sspeed0, sspeed1;

// page OLORD2

reg ape_n, mpe_n, pdlpe_n, dpe_n, ipe_n, spe_n, higherr_n, mempe_n;
reg v0pe_n, v1pe_n, statstop, halted_n;

// page L
reg[31:0] l;

// page NPC
reg[13:0] pc;

// page OPCS
reg[13:0] opc;

// page PDLPTR
reg[9:0] pdlptr;

// page SPCW
reg[13:0] reta;

reg[9:0] mcycle_delay;

// page IWR
reg[48:0] iwr;

reg[13:0] lpc;

reg[23:22] lvmo_n;
reg[21:8] pma;


// SPY 0

wire spy_obh_n, spy_obl_n, spy_pc_n, spy_opc_n,
	spy_nc_n,spy_irh_n, spy_irm_n, spy_irl_n;

wire spy_sth_n, spy_stl_n, spy_ah_n, spy_al_n,
	spy_mh_n, spy_ml_n, spy_flag2_n, spy_flag1_n;

wire ldmode_n, ldopc_n, ldclk_n, lddbirh_n, lddbirm_n, lddbirl_n;

// clocks
wire CLK, MCLK;
//wire clk0_n, mclk0_n;
wire mclk0_n;

//reg osc50mhz;
wire osc0, hifreq1, hifreq2, hf_n , hfdlyd, hftomm;
wire clk_n, tpclk, tpclk_n, lclk, lclk_n, wp, lwp_n;
wire tse, ltse, ltse_n;
wire tpr0_n, tpr0a, tpr0d, tpr0d_n;
wire tpr1a, tpr1d_n;
wire tpwp, sone_n, tprend_n;

reg tpr1, tpr1_n, ff1d;
reg tpr6_n, tpr5, tpr5_n, tpr4, tpr4_n, tpr3, tpr3_n, tpr2, tpr2_n;
reg tpw0, tpw0_n, tpw1, tpw1_n, tpw2, tpw2_n, tpw3, tpw3_n;

wire tpwpor1, tpwpiram;
wire tptse, tptsef, tptsef_n, maskc, ff1, ff1_n;
reg tendly_n, hangs_n, crbs_n;
wire hang_n;
wire iwe_n;

reg sspeed1a, sspeed0a;

// *******************************************************************

// page actl

always @(posedge CLK)
  begin
    // wadr 9  8  7  6  5  4  3  2  1  0
    //      0  0  0  0  0  18 17 16 15 14
    // ir   23 22 21 20 19 18 17 16 15 14
    wadr = destm ? { 5'b0, ir[18:14] } : { ir[23:14] };
    destd <= dest;
    destmd <= destm;
  end

initial
    wadr = 0;

assign apass = destd & ( ir[41:32] == wadr[9:0] ? 1'b1 : 1'b0 );
assign apass_n = !apass;

assign amemenb_n  = !(apass_n & tse);
assign apassenb_n  = !(apass & tse);

assign awp_n = ~(destd & wp);

assign aadr = CLK ? { ir[41:32] } : wadr;

// page ALATCH

// AML
// transparent latch
//always @(CLK or amem or negedge reset_n)
always @(CLK or amem or reset_n)
  if (reset_n == 0)
    a_latch <= 0;
  else
    if (CLK == 1'b1)
      a_latch <= amem;

assign a =
	amemenb_n == 1'b0 ? a_latch :
	apassenb_n == 1'b0 ? l :
	32'hffff;

// page ALU0-1

// 74181 pulls down AEB if not equal
// aeqm is the simulated open collector
assign aeqm = aeqm_bits == { 8'b11111111 } ? 1'b1 : 1'b0;

wire[2:0] nc_alu;

ic_74S181  i_ALU1_2A03 (
  .B({3'b0,a[31]}),
  .A({3'b0,m[31]}),
  .S(aluf[3:0]),
  .CIN_N(cin32_n),
  .M(alumode),
  .F({nc_alu,alu[32]})
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
  .Y(yout31)
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
  .Y(yout27)
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
  .Y(yout23)
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
  .Y(yout19)
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
  .Y(yout15)
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
  .Y(yout11)
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
  .Y(yout7)
);

ic_74S181  i_ALU0_2B28 (
  .A(m[3:0]),
  .B(a[3:0]),
  .S(aluf[3:0]),
  .CIN_N(cin0_n),
  .M(alumode),
  .F(alu[3:0]),
  .AEB(aeqm_bits[0]),
  .X(xout3),
  .Y(yout3)
);

// page ALUC4

ic_74S182  i_ALUC4_2A20 (
  .Y( { yout15,yout11,yout7,yout3 } ),
  .X( { xout15,xout11,xout7,xout3 } ),
  .COUT2_N(cin12_n),
  .COUT1_N(cin8_n),
  .COUT0_N(cin4_n),
  .CIN_N(cin0_n),
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
  .CIN_N(cin0_n)
);


assign divposlasttime_n  = !(q[0] | ir[6]);

assign divsubcond = !(div_n | divposlasttime_n);

assign divaddcond = !(div_n | !(ir[5] | divposlasttime_n));

assign aluadd = !(
		  !(divaddcond & ~a[31]) &
		  !(divsubcond & a[31]) &
		  mul_n
		 );

assign mulnop_n = mul_n | q[0];

assign alusub = !(
		  mulnop_n &
		  !(~a[31] & divsubcond) &
	          !(divaddcond & a[31]) &
		  irjump_n
		 );

assign osel[1] = ! (~ir[13] | iralu_n);
assign osel[0] = ! (~ir[12] | iralu_n);


assign aluf_n =
	{alusub,aluadd} == 2'b00 ? { ~ir[3], ~ir[4], ir[6], ir[5] } :
	{alusub,aluadd} == 2'b01 ? { 1'b0,   1'b1,   1'b1,  1'b0 } :
	{alusub,aluadd} == 2'b10 ? { 1'b1,   1'b0,   1'b0,  1'b1 } :
	                           { 1'b0,   1'b0,   1'b0,  1'b0 };

assign alumode_n =
	{alusub,aluadd} == 2'b00 ? ir[7] :
	{alusub,aluadd} == 2'b01 ? 1'b1 :
	{alusub,aluadd} == 2'b10 ? 1'b1 :
	                           1'b0;

assign cin0_n =
	{alusub,aluadd} == 2'b00 ? ~ir[2] :
	{alusub,aluadd} == 2'b01 ? 1'b1 :
	{alusub,aluadd} == 2'b10 ? irjump :
                                   1'b0;

assign aluf = ~aluf_n;
assign alumode = ~alumode_n;


// page AMEM0-1

part_1kx32ram  i_AMEM (
  .A(aadr),
  .DO(amem),
  .DI(l),
  .WE_N(awp_n),
  .CE_N(1'b0)
);

assign aparok = 1;

// page CONTRL

assign dfall_n  = ! (dr & dp);			/* push-pop fall through */

assign dispenb = irdisp & funct2_n;
assign ignpopj_n  = irdisp_n  | dr;

assign jfalse = irjump & ir[6];			/* jump and inverted-sense */

assign jcalf = jfalse & ir[8];			/* call and inverted-sense */

assign jret = irjump & ~ir[8] & ir[9];		/* return */

assign jretf = jret & ir[6];			/* return and inverted-sense */

assign iwrite = irjump & ir[8] & ir[9];		/* microcode write */

assign ipopj_n  = ! (ir[42] & nop_n );
assign popj_n  = ipopj_n  & iwrited_n ;

assign popj = ~popj_n;

assign srcspcpopreal_n  = srcspcpop_n  | nop;

assign spop_n = ! (
	( !(srcspcpopreal_n & popj_n ) & ignpopj_n ) |
	(dispenb & dr & ~dp) |
	(jret & ~ir[6] & jcond) |
	(jretf & ~jcond)
	);

assign spush_n = ! (
	destspc |
	(jcalf & ~jcond) |
	(dispenb & dp & ~dr) |
	(irjump & ~ir[6] & ir[8] & jcond)
	);

assign spcwpass_n = !(spushd & tse);
assign spcpass_n = !(spushd_n & tse);

assign swp_n = !(spushd & wp);
assign spcenb = !(srcspc_n & srcspcpop_n);
assign spcdrive_n = !(spcenb & tse);
assign spcnt_n = spush_n & spop_n;

assign inop_n = ~inop;
assign spushd_n = ~spushd;
assign iwrited_n = ~iwrited;

always @(posedge CLK or negedge reset_n)
  if (~reset_n)
    begin
      inop <= 0;
      spushd <= 0;
      iwrited <= 0;
    end
  else
    begin
      inop <= n;
      spushd <= ~spush_n;
      iwrited <= iwrite;
    end

initial
  begin
   inop = 0;
   spushd = 0;
   iwrited = 0;
  end

/*
 * select new pc
 * {pcs1,pcs0}
 * 00 0 spc
 * 01 1 ir
 * 10 2 dpc
 * 11 3 ipc
 */

assign pcs1 = !(
	(popj & ignpopj_n) |		/* popj & ignore */
	(jfalse & ~jcond) |		/* jump & invert & cond-not-satisfied */
	(irjump & ~ir[6] & jcond) |	/* jump & !invert & cond-satisfied */
	(dispenb& dr & ~dp)		/* dispatch + return & !push */
	);

assign pcs0 = !(
	(popj) |
	(dispenb & dfall_n) |
	(jretf & ~jcond) |
	(jret & ~ir[6] & jcond)
	);

/*
 * N set if:
 *  iwrite (microcode write)
 *  dispatch & disp-N
 *  jump & invert-jump-selse & cond-false & !next
 *  jump & !invert-jump-sense & cond-true & !next
 */
assign n =
	!(trap_n & 
	  !((iwrited) |
	    (dispenb & dn) |
	    (jfalse & ~jcond & ir[7]) |
	    (irjump & ~ir[6] & jcond & ir[7]))
	 );

assign nopa_n  = inop_n & nop11_n;
assign nopa  = ~nopa_n;

assign nop = !(trap_n & nopa_n);
assign nop_n = ~nop;

// page DRAM0-2

// dadr  10 9  8  7  6  5  4  3  2  1  0
// -------------------------------------
// ir    22 21 20 19 18 17 16 15 14 13 d
// dmask x  x  x  x  6  5  4  3  2  1  x
// r     x  x  x  x  6  5  4  3  2  1  x

assign daddr0_n = !(
	(ir[8] & vmo[18]) |
	(ir[9] & vmo[19]) |
	(dmapbenb_n & dmask[0] & r[0]) |
	(ir[12]));

assign dadr_n =
	~(
	  { ir[22:13], ~daddr0_n } |
	  ({ 4'b0000, dmask[6:1], 1'b0 } &
	   { 4'b0000, r[6:1],     1'b0 })
	);

assign dwe_n = !(dispwr & wp);

part_2kx17ram  i_DRAM (
  .A(dadr_n),
  .DO({dr,dp,dn,dpc}),
  .DI(a[16:0]),
  .WE_N(dwe_n),
  .CE_N(1'b0)
);

// page DSPCTL

assign dparh_n = 1;
assign dparl = 0;
assign dpareven = dparh_n  ^ dparl;
assign dparok = !(dpareven & dispenb);
assign dmapbenb_n  = !(ir[8] | ir[9]);
assign dispwr = !(irdisp_n | funct2_n);

always @(posedge CLK)
  if (irdisp_n == 1'b0)
    dc <= ir[41:32];

initial
  dc = 0;

part_32x8prom  i_DMASK (
  .A( {1'b0, 1'b0, ir[7], ir[6], ir[5]} ),
  .O( {nc_dmask, dmask[6:0]} ),
  .CE_N(1'b0)
);

// page FLAG

assign statbit_n = !(nopa_n & ir[46]);
assign ilong_n  = !(nopa_n & ir[45]);

assign aluneg = !(aeqm | ~alu[32]);

assign sint = sintr & int_enable;

assign pgf_or_int = vmaok_n | sint;
assign pgf_or_int_or_sb = vmaok_n | sint | sequence_break;

assign conds = ir[2:0] & {ir[5],ir[5],ir[5]};

assign jcond = 
	conds == 3'b000 ? r[0] :
	conds == 3'b001 ? aluneg :
	conds == 3'b010 ? alu[32] :
	conds == 3'b011 ? aeqm :
	conds == 3'b100 ? vmaok_n :
	conds == 3'b101 ? pgf_or_int :
	conds == 3'b110 ? pgf_or_int_or_sb :
	                  1'b1;

always @(posedge CLK or negedge reset_n)
  if (~reset_n)
    begin
      lc_byte_mode <= 0;
      prog_unibus_reset <= 0;
      int_enable <= 0;
      sequence_break <= 0;
    end
  else
    if (destintctl_n == 1'b0)
      begin
        lc_byte_mode <= ob[29];
        prog_unibus_reset <= ob[28];
        int_enable <= ob[27];
        sequence_break <= ob[26];
      end

initial
  begin
    lc_byte_mode = 0;
    prog_unibus_reset = 0;
    int_enable = 0;
    sequence_break = 0;
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

assign ipar = 4'b0000;
assign iparity = 0;
assign iparok = imodd | iparity;

// page IREG

always @(posedge CLK or negedge reset_n)
  if (reset_n == 0)
    ir <= 49'b0;
  else
    begin
      ir[47:26] <= destimod1_n ? i[47:26] : iob[47:26]; 
      ir[25:0] <= destimod0_n ? i[25:0] : iob[25:0]; 
    end

initial
  ir = 49'b0;

// page IWR

always @(posedge CLK or negedge reset_n)
  if (reset_n == 0)
    iwr <= 0;
  else
    begin
      iwr[48] <= 0;
      iwr[47:32] <= a[15:0];
      iwr[31:0] <= m[31:0];
    end

initial
  iwr[47:0] = 48'b0;

// page L

always @(posedge CLK or negedge reset_n)
  if (reset_n == 0)
    l <= 0;
  else
    l <= ob;

initial
   l = 0;

assign lparl = 0;
assign lparm_n = 0;
assign lparity = 0;
assign lparity_n = 1;


// page LC

always @(posedge CLK or negedge reset_n)
  if (reset_n == 0)
    lc <= 0;
  else
    begin
      if (destlc_n == 1'b0)
        lc <= { ob[25:4], ob[3:0] };
      else
        lc <= { lc[25:4] + lcry3, lca[3:0] };
    end

assign {lcry3, lca[3:0]} =
	 lc[3:0] + { 3'b0, !(lcinc_n | lc_byte_mode) } + lcinc;

assign lcdrive_n  = !(srclc & tse);

// xxx
// I think the above is really
// 
// always @(posedge CLK)
//   begin
//     if (destlc_n == 0)
//       lc <= ob;
//     else
//       lc <= lc + 
//             !(lcinc_n | lc_byte_mode) ? 1 : 0 +
//             lcinc ? 1 : 0;
//
//   end
//

// mux MF
assign mf =
	~lcdrive_n ?
	  { needfetch, 1'b0, lc_byte_mode, prog_unibus_reset,
	    int_enable, sequence_break, lc[25:1], lc0b } :
        ~opcdrive_n ?
	  { 16'b0, 2'b0, opc[13:0] } :
// zero16_drive drives top 16 bits to zero
// zero12_drive drives top 4 bits of lower 16 to zero
// don't need this since we don't pull up mf bus
//        zero12_drive ?
//	  { 16'b0, 4'b0, 12'b0 } :
        dcdrive ?
	  { 16'b0, 4'b0, 2'b0, dc[9:0] } :
	~ppdrive_n ?
	  { 16'b0, 4'b0, 2'b0, pdlptr[9:0] } :
	pidrive ?
	  { 16'b0, 4'b0, 2'b0, pdlidx[9:0] } :
	qdrive ?
	  q :
	~mddrive_n ?
	  md :
	~mpassl_n ?
	  l :
	~vmadrive_n ?
	  vma :
	~mapdrive_n ?
	  { pfw_n, pfr_n, 1'b1, vmap_n[4:0], vmo[23:0] } :
	32'b0;


// page LCC

assign lc0b = lc[0] & lc_byte_mode;
assign next_instr  = !(spop_n | !(srcspcpopreal_n & spc[14]));

assign newlc_in_n  = !(have_wrong_word & lcinc_n);
assign have_wrong_word = !(newlc_n & destlc_n);
assign last_byte_in_word  = !(lc[1] | lc0b);
assign needfetch = have_wrong_word | last_byte_in_word;

assign ifetch_n  = !(needfetch & lcinc);
assign spcmung = spc[14] & ~needfetch;
assign spc1a = spcmung | spc[1];

assign lcinc = next_instrd | (irdisp & ir[24]);
assign lcinc_n = !(next_instrd | (irdisp & ir[24]));

always @(posedge CLK or negedge reset_n)
  if (reset_n == 0)
    begin
      newlc <= 0;
      sintr <= 0;
      next_instrd <= 0;
    end
  else
    begin
      newlc <= newlc_in_n;
      sintr <= int;
      next_instrd <= next_instr;
    end

assign newlc_n = ~newlc;

initial 
  begin
    newlc = 0;
    sintr = 0;
    next_instrd = 0;
  end

// mustn't depend on nop

assign lc_modifies_mrot_n  = !(ir[10] & ir[11]);

assign inst_in_left_half = !((lc[1] ^ lc0b) | lc_modifies_mrot_n);

assign sh4_n  = inst_in_left_half ^ ~ir[4];

// LC<1:0>
// +---------------+
// | 0 | 3 | 2 | 1 |
// +---------------+
// |   0   |   2   |
// +---------------+

assign inst_in_2nd_or_4th_quarter =
	!(lc[0] | lc_modifies_mrot_n) & lc_byte_mode;

assign sh3_n  = ~ir[3] ^ inst_in_2nd_or_4th_quarter;

//page LPC

always @(posedge CLK)
  begin
    if (lpc_hold == 0)
      lpc <= pc;
  end

initial
  lpc = 0;

/* dispatch and instruction as N set */
assign wpc = (irdisp & ir[25]) ? lpc : pc;

// page MCTL

assign mpass = { 1'b1, ir[30:26] } == { destmd, wadr[4:0] };
assign mpass_n = ~mpass;

assign mpassl_n = !(mpass & tse & ~ir[31]);
assign mpassm_n  = !(mpass_n & tse & ~ir[31]);

assign srcm = ~ir[31] & mpass_n;

assign mwp_n = !(destmd & tpwp);

assign madr = CLK ? ir[30:26] : wadr[4:0];

// page MD

always @(posedge mdclk or negedge reset_n)
  if (reset_n == 0)
    md <= 0;
  else
    begin
      md <= mds;
      mdhaspar <= mdgetspar;
      mdpar <= mempar_in;
    end

initial
  md = 0;

assign mddrive_n = !(~srcmd_n & tse);
assign mdgetspar = ignpar_n  & destmdr_n;
assign mdclk = !(loadmd | (~CLK & ~destmdr_n));

// page MDS

assign mds = mdsel ? ob : mem;

assign mdparodd = 1;

assign mempar_out = mdparodd;

// mux MEM
assign mem =
	~memdrive_n ? md :
	loadmd ? busint_bus :
		32'b0;

// page MF
assign mfenb = ~srcm & !(spcenb | pdlenb);
assign mfdrive_n  = !(mfenb & tse);

// page MLATCH

assign mmemparity = 0;

// transparent latch
always @(CLK or mmem or mmemparity)
  if (CLK == 1'b1)
    begin
      mmem_latched <= mmem;
      mparity <= mmemparity;
    end

assign mmemparok = 1;

// mux M
assign m = 
	~mpassm_n ? mmem_latched :
	~pdldrive_n ? pdl_latch :
	~spcdrive_n ? {3'b0, spcptr, 5'b0, spco_latched} :
	~mfdrive_n ? mf :
                        32'b0;

// page MMEM

part_32x32ram  i_MMEM (
  .A(madr),
  .DI(l),
  .DO(mmem),
  .WCLK_N(mwp_n),
  .WE_N(1'b0),
  .CE(1'b1)
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
	osel == 2'b01 ? alu :
	osel == 2'b10 ? alu[32:1] :
	      /*2'b11*/ {alu[30:0],q[31]};


// page MSKG4

part_32x32prom_maskleft i_MSKR (
  .O(msk_left_out),
  .A(mskl),
  .CE_N(1'b0)
);

part_32x32prom_maskright i_MSKL (
  .O(msk_right_out),
  .A(mskr),
  .CE_N(1'b0)
);

assign msk = msk_right_out & msk_left_out;

// page NPC

assign npc = 
  trap ? 14'b0 :
    {pcs1,pcs0} == 2'b00 ? { spc[13:2], spc1a, spc[0] } :
    {pcs1,pcs0} == 2'b01 ? { ir[25:12] } :
    {pcs1,pcs0} == 2'b10 ? dpc :
                 /*2'b11*/ ipc;

always @(posedge CLK or negedge reset_n)
  if (reset_n == 0)
    pc <= 0;
  else
    pc <= npc;

initial
  pc = 0;

assign ipc = pc + 1'b1;

// page OPCD

assign dcdrive = ~srcdc_n & tse;
assign opcdrive_n  = !(~srcopc_n & tse);

assign zero16 = !(srcopc_n  & srcpdlidx_n  & srcpdlptr_n & srcdc_n);

assign zero12_drive  = zero16 & srcopc_n & tse;
assign zero16_drive  = zero16 & tse;
assign zero16_drive_n  = !(zero16 & tse);

// page PDL

assign pdlparity = 0;

part_1kx32ram i_PDL (
  .A(pdla),
  .DO(pdl),
  .DI(l),
  .WE_N(pwp_n),
  .CE_N(1'b0)
);

// page PDLCTL

assign pdla = pdlp_n ? pdlidx : pdlptr;

assign pdlp_n = !((CLK & ir[30]) | (~CLK & pwidx_n));
assign pdlwrite = !(destpdltop_n & destpdl_x_n & destpdl_p_n);

always @(posedge CLK or negedge reset_n)
  if (reset_n == 0)
    begin
      pdlwrited <= 0;
      pwidx_n <= 0;
      imodd <= 0;
      destspcd_n <= 0;
    end
  else
    begin
      pdlwrited <= pdlwrite;
      pwidx_n <= destpdl_x_n;
      imodd <= imod;
      destspcd_n <= destspc_n;
    end

assign imodd_n = ~imodd;

initial
  begin
    pdlwrited = 0;
    pwidx_n = 0;
    imodd = 0;
    destspcd_n = 0;
  end

assign destspcd = ~destspcd_n;

assign pwp_n  = !(pdlwrited & wp);

assign pdlenb = !(srcpdlpop_n  & srcpdltop_n);
assign pdldrive_n  = !(pdlenb & tse);

assign pdlcnt_n  = (srcpdlpop_n | nop) & destpdl_p_n;

// page PDLPTR

assign pidrive = tse & ~srcpdlidx_n;
assign ppdrive_n  = !(tse & ~srcpdlptr_n);

always @(posedge CLK or negedge reset_n)
  if (reset_n == 0)
    pdlidx <= 0;
  else
    if (destpdlx_n == 1'b0)
      pdlidx <= ob[9:0];

always @(posedge CLK or negedge reset_n)
  if (reset_n == 0)
    pdlptr <= 0;
  else
    begin
     if (destpdlp_n == 1'b0)
       pdlptr <= ob[9:0];
     else
       if (pdlcnt_n == 1'b0)
         begin
           if (srcpdlpop_n)
             pdlptr <= pdlptr - 1'b1;
           else
             pdlptr <= pdlptr + 1'b1;
         end
    end

initial
  begin
    pdlidx = 0;
    pdlptr = 0;
  end


// page PLATCH

// transparent latch
always @(CLK or pdl or pdlparity)
  if (CLK == 1'b1)
    begin
      pdl_latch <= pdl;
      mparity <= pdlparity;
    end

// page Q

assign qs1 = !(~ir[1] | iralu_n);
assign qs0 = !(~ir[0] | iralu_n);

assign srcq = ~srcq_n;
assign qdrive = srcq & tse;

wire QCLK;
//assign #1 QCLK = CLK;
assign QCLK = tpw2;

always @(posedge QCLK or negedge reset_n)
  if (reset_n == 0)
    q <= 0;
  else
    if (qs1 | qs0)
      begin
        case ( {qs1,qs0} )
          2'b01: q <= { q[30:0], ~alu[31] };
          2'b10: q <= { alu[0], q[31:1] };
          2'b11: q <= alu;
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

assign mr_n  = !(irbyte_n | ir[13]);
assign sr_n  = !(irbyte_n | ir[12]);

assign s0 = !(sr_n | ~ir[0]);
assign s1 = !(sr_n | ~ir[1]);


assign mskr[4] = !(mr_n | sh4_n);
assign mskr[3] = !(mr_n | sh3_n);
assign mskr[2] = !(mr_n | ~ir[2]);
assign mskr[1] = !(mr_n | ~ir[1]);
assign mskr[0] = !(mr_n | ~ir[0]);


assign s4 = !(sr_n | sh4_n);
assign s4_n = sr_n | sh4_n;

assign s3 = !(sr_n | sh3_n);
assign s2 = !(sr_n | ~ir[2]);


assign mskl = mskr + ir[9:5];

// page SOURCE

assign irdisp = ~irdisp_n;
assign irjump = ~irjump_n;

assign {irbyte_n,irdisp_n,irjump_n,iralu_n} =
  nop ? 4'b1111 :
	({ir[44],ir[43]} == 2'b00) ? 4'b1110 :
	({ir[44],ir[43]} == 2'b01) ? 4'b1101 :
	({ir[44],ir[43]} == 2'b10) ? 4'b1011 :
                                     4'b0111 ;

assign funct = 
  nop ? 4'b0000 :
	({ir[11],ir[10]} == 2'b00) ? 4'b0001 :
	({ir[11],ir[10]} == 2'b01) ? 4'b0010 :
	({ir[11],ir[10]} == 2'b10) ? 4'b0100 :
                                     4'b1000 ;

assign iralu = ~iralu_n;
assign funct2_n = ~funct[2];

assign specalu_n  = !(ir[8] & iralu);

assign {div_n,mul_n} =
  specalu_n == 1 ? 2'b11 :
	({ir[4],ir[3]} == 2'b00) ? 2'b10 : 2'b01;

//xxx eliminate?
assign srclc = ~srclc_n;

assign {srcq_n,srcopc_n,srcpdltop_n,srcpdlpop_n,
	srcpdlidx_n,srcpdlptr_n,srcspc_n,srcdc_n} =
  (~ir[31] | ir[29]) ? 8'b11111111 :
	({ir[28],ir[27],ir[26]} == 3'b000) ? 8'b11111110 :
	({ir[28],ir[27],ir[26]} == 3'b001) ? 8'b11111101 :
	({ir[28],ir[27],ir[26]} == 3'b010) ? 8'b11111011 :
	({ir[28],ir[27],ir[26]} == 3'b011) ? 8'b11110111 :
	({ir[28],ir[27],ir[26]} == 3'b100) ? 8'b11101111 :
	({ir[28],ir[27],ir[26]} == 3'b101) ? 8'b11011111 :
	({ir[28],ir[27],ir[26]} == 3'b110) ? 8'b10111111 :
	                                     8'b01111111;

assign {srcspcpop_n,srclc_n,srcmd_n,srcmap_n,srcvma_n} =
  (~ir[31] | ~ir[29]) ? 5'b11111 :
	({ir[28],ir[27],ir[26]} == 3'b000) ? 5'b11110 :
	({ir[28],ir[27],ir[26]} == 3'b001) ? 5'b11101 :
	({ir[28],ir[27],ir[26]} == 3'b010) ? 5'b11011 :
	({ir[28],ir[27],ir[26]} == 3'b011) ? 5'b10111 :
	({ir[28],ir[27],ir[26]} == 3'b100) ? 5'b01111 :
	                                     5'b11111 ;

assign imod = !((destimod0_n & iwrited_n) & destimod1_n & idebug_n);

assign destmem_n = !(destm & ir[23]);
assign destvma_n = destmem_n | ir[22];
assign destmdr_n = destmem_n | ~ir[22];

assign dest = !(iralu_n & irbyte_n);
assign destm = dest & ~ir[25];

assign {destintctl_n,destlc_n} =
  !(destm & ~ir[23] & ~ir[22]) ? 2'b11 :
	({ir[21],ir[20],ir[19]} == 3'b001) ? 2'b10 :
	({ir[21],ir[20],ir[19]} == 3'b010) ? 2'b01 :
	                                     2'b11 ;

assign {destimod1_n,destimod0_n,destspc_n,destpdlp_n,
	destpdlx_n,destpdl_x_n,destpdl_p_n,destpdltop_n} =
  !(destm & ~ir[23] & ir[22]) ? 8'b11111111 :
	({ir[21],ir[20],ir[19]} == 3'b000) ? 8'b11111110 :
	({ir[21],ir[20],ir[19]} == 3'b001) ? 8'b11111101 :
	({ir[21],ir[20],ir[19]} == 3'b010) ? 8'b11111011 :
	({ir[21],ir[20],ir[19]} == 3'b011) ? 8'b11110111 :
	({ir[21],ir[20],ir[19]} == 3'b100) ? 8'b11101111 :
	({ir[21],ir[20],ir[19]} == 3'b101) ? 8'b11011111 :
	({ir[21],ir[20],ir[19]} == 3'b110) ? 8'b10111111 :
	                                     8'b01111111;

assign destspc = ~destspc_n;

// page SPC

part_32x19ram  i_SPC (
  .A(spcptr),
  .DI(spcw),
  .DO(spco),
  .WCLK_N(swp_n),
  .WE_N(1'b0),
  .CE(1'b1)
);

//always @(posedge CLK)
always @(posedge QCLK)
  begin
    if (spcnt_n == 1'b0)
      begin
        if (spush_n == 1'b0)
          spcptr <= spcptr + 1'b1;
        else
          spcptr <= spcptr - 1'b1;
      end
  end

initial
  spcptr = 0;

// page SPCLCH

// mux SPC
assign spc = 
  ~spcpass_n ?  spco_latched :
  ~spcwpass_n ? spcw :
	        32'b0;

assign spcopar = 0;

// transparent latch
//always @(CLK or spco or spcopar or negedge reset_n)
always @(CLK or spco or spcopar or reset_n)
  if (reset_n == 0)
    spco_latched <= 0;
  else
    if (CLK == 1'b1)
      begin
        spco_latched <= spco;
        spcpar <= spcopar;
      end


// page SPCPAR

assign spcwpar = 0;
assign spcwparl_n = 1;
assign spcwparh = 0;
assign spcparok = 1;

assign spcwpar = spcwparh ^ spcwparl_n;

// page SPCW

assign spcw = destspcd ? l[18:0] : { 5'b0, reta };

always @(posedge CLK or negedge reset_n)
  if (reset_n == 0)
    reta <= 0;
  else
    reta <= n ? wpc : ipc;

// page SPY1-2

//xxxdebug
//assign spy = 16'b1111111111111111;

assign spy =
	~spy_irh_n ? ir[47:32] :
	~spy_irm_n ? ir[31:16] :
	~spy_irl_n ? ir[15:0] :
	~spy_obh_n ? ob[31:16] :
	~spy_obl_n ? ob[15:0] :
	~spy_ah_n ? a[31:16] :
	~spy_al_n ? a[15:0] :
	~spy_mh_n ? m[31:16] :
	~spy_ml_n ? m[15:0] :
	~spy_flag2_n ?
			{ 2'b0,wmapd,destspcd,iwrited,imodd,pdlwrited,spushd,
			  2'b0,ir[48],nop,vmaok_n,jcond,pcs1,pcs0 } :
	~spy_opc_n ?
			{ 2'b0,opc } :
	~spy_flag1_n ?
			{ wait_n,v1pe_n,v0pe_n,promdisable,
			  stathalt_n, err, ssdone, srun,
			  higherr_n, mempe_n, ipe_n, dpe_n,
			  spe_n, pdlpe_n, mpe_n, ape_n } :
	~spy_pc_n ?
			{ 2'b0,pc } :
	                 16'b1111111111111111;

assign halt_n = 1;

// page TRAP

assign mdpareven = 0;

assign mdparerr = mdpareven ^ mdpar;
assign parerr_n = !(mdparerr & mdhaspar & use_md & wait_n);
assign memparok = !memparok_n;

assign trap_n  = !( !(parerr_n | ~trapenb) | boot_trap );
assign trap = ~trap_n;
assign memparok_n = !(parerr_n | trapenb);

// page VCTRL1

assign memop_n  = memrd_n  & memwr_n  & ifetch_n;
assign memprepare = !(memop_n | CLK);

always @(posedge MCLK or negedge reset_n)
  if (reset_n == 0)
    begin
      memstart <= 0;
      mbusy_sync <= 0;
    end
  else
    begin
      memstart <= memprepare;
      mbusy_sync <= memrq;
    end

assign memstart_n = ~memstart;

initial
  begin
    memstart = 0;
    mbusy_sync = 0;
  end

assign pfw_n  = !(lvmo_n[22] & wrcyc);
assign vmaok_n  = !(pfr_n & pfw_n);

always @(posedge CLK or negedge reset_n)
  if (reset_n == 0)
    begin
      wrcyc <= 0;
      wmapd <= 0;
    end
  else
    begin
      wrcyc <= !((memprepare & memwr_n) | (~memprepare & rdcyc));
      wmapd <= wmap;
    end

initial
  begin
    wrcyc = 0;
    wmapd = 0;
  end

assign rdcyc = ~wrcyc;
assign wmapd_n = ~wmapd;

assign memrq = mbusy | (memstart & pfr_n & pfw_n);

//------
always @(posedge MCLK or negedge mfinishd_n)
  if (mfinishd_n == 0)
    mbusy <= 1'b0;
  else
    mbusy <= memrq;

//always @(posedge MCLK or negedge reset_n)
//  if (reset_n == 0)
//    mbusy <= 1'b0;
//  else
//    mbusy <= memrq;
//
//always @(mfinishd_n)
//  if (mfinishd_n == 1'b0)
//      mbusy <= 1'b0;

//------

assign set_rd_in_progess = rd_in_progress | (memstart & pfr_n & rdcyc);
assign mfinish_n = memack_n & reset_n;

always @(posedge MCLK or negedge rdfinish_n)
  if (rdfinish_n == 1'b0)
    rd_in_progress <= 0;
  else
    rd_in_progress <= set_rd_in_progess;

//XXX delay line
// mfinish_n + 30ns -> mfinishd_n
// mfinish_n + 140ns -> rdfinish_n

always @(posedge osc50mhz or negedge reset_n)
  if (reset_n == 0)
    mcycle_delay <= 10'b1;
  else
    begin
      mcycle_delay[0] <= mfinish_n;
      mcycle_delay[1] <= mcycle_delay[0];
      mcycle_delay[2] <= mcycle_delay[1];
      mcycle_delay[3] <= mcycle_delay[2];
      mcycle_delay[4] <= mcycle_delay[3];
      mcycle_delay[5] <= mcycle_delay[4];
      mcycle_delay[6] <= mcycle_delay[5];
      mcycle_delay[7] <= mcycle_delay[6];
    end

assign mfinishd_n = mcycle_delay[2];
assign rdfinish_n = mcycle_delay[7];

assign wait_n = !(
	(~destmem_n & mbusy_sync) |
	(use_md & mbusy & memgrant_n) |		/* hang loses */
	(lcinc & needfetch & mbusy_sync)	/* ifetch */
	);

assign hang_n = !(rd_in_progress & use_md & ~CLK);

// page VCTRL2

assign mapwr0d = !(wmapd_n | ~vma[26]);
assign mapwr1d = !(wmapd_n | ~vma[25]);

assign vm0wp_n = !(mapwr0d & wp);
assign vm1wp_n = !(mapwr1d & wp);

assign vmaenb_n = destvma_n & ifetch_n;
assign vmasel = ifetch_n & 1'b1;

// external?
assign lm_drive_enb = 0;

assign memdrive_n = !(wrcyc & lm_drive_enb);

assign mdsel = !(destmdr_n | CLK);

assign use_md  = !(srcmd_n | nopa);

assign pfr_n = ~lvmo_n[23];

assign {wmap_n,memwr_n,memrd_n} =
  destmem_n ? 3'b111 :
	({ir[20],ir[19]} == 2'b01) ? 3'b110 :
	({ir[20],ir[19]} == 2'b10) ? 3'b101 :
	({ir[20],ir[19]} == 2'b11) ? 3'b011 :
	                             3'b111 ;

assign wmap = ~wmap_n;

// page VMA

always @(posedge CLK or negedge reset_n)
  if (reset_n == 0)
    vma <= 0;
  else
    if (vmaenb_n == 1'b0)
      vma <= vmas;

assign vmadrive_n = !(~srcvma_n & tse);

initial
  vma = 0;

// page VMAS

assign vmas = vmasel ? ob : { 8'b0,lc[25:2] };

assign mapi = memstart_n ? md[23:8] : vma[23:8];

// page VMEM0 - virtual memory map stage 0

part_2kx5ram i_VMEM0 (
  .A(mapi[23:13]),
  .DO(vmap_n),
  .DI(vma[31:27]),
  .WE_N(vm0wp_n),
  .CE_N(1'b0)
);

assign srcmap = ~srcmap_n;
assign use_map_n = !(srcmap | memstart);
assign vmoparck = use_map_n | vmoparodd;
assign v0parok = use_map_n  | 1'b1;
assign vm0pari = 0;

assign vmopar = 0;

assign vmoparodd = vmopar ^ vmoparck;

// page VMEM1&2

assign mapi_n = ~mapi[12:8];

assign vmo = ~vmo_n;

assign vmap = ~vmap_n;

wire[9:0] vmem1_adr;
assign vmem1_adr = {mapi_n[12:8],vmap[4:0]};

part_1kx24ram  i_VMEM1_2 (
  .A(vmem1_adr),
  .DO(vmo_n),
  .DI(vma[23:0]),
  .WE_N(vm1wp_n),
  .CE_N(1'b0)
);

assign vm1mpar = 0;
assign vm1lpar = 0;
assign vm0par = 0;
assign vm0parm = 0;
assign vm0parl = 0;

// page VMEMDR - map output drive

// transparent latch
always @(memstart or vmo_n)
  if (memstart == 1'b1)
    { lvmo_n[23:22], pma } <= vmo_n;

initial
  begin
    lvmo_n = 0;
    pma = 0;
  end

assign mapdrive_n = !(tse & srcmap);

// page DEBUG

always @(posedge lddbirh_n)
     spy_ir[47:32] <= spy;

always @(posedge lddbirm_n)
     spy_ir[31:16] <= spy;

always @(posedge lddbirl_n)
     spy_ir[15:0] <= spy;

// put latched value on I bus when idebug_n asserted
assign i =
	~idebug_n ? spy_ir :
	~promenable_n ? iprom :
	iram;

initial
  spy_ir = 0;

// page ICTL - I RAM control

assign promdisabled_n = ~promdisabled;

assign ramdisable = idebug | (promdisabled_n & iwrited_n);

// see clocks below
//assign iwe_n  = !(wp5& iwriteda);

// page OLORD1 

always @(posedge ldmode_n or negedge reset_n)
  if (reset_n == 0)
    begin
      promdisable <= 0;
      trapenb <= 0;
      stathenb <= 0;
      errstop <= 0;
      speed1 <= 0;
      speed0 <= 0;
    end
  else
    begin
      promdisable <= spy[5];
      trapenb <= spy[4];
      stathenb <= spy[3];
      errstop <= spy[2];
      speed1 <= spy[1];
      speed0 <= spy[0];
    end

initial
  begin
    promdisable = 0;
    trapenb = 0;
    stathenb = 0;
    errstop = 0;
    speed1 = 0;
    speed0 = 0;
  end

wire ldopc;
assign ldopc = ~ldopc_n;

always @(posedge ldopc or negedge reset_n)
  if (reset_n == 0)
    begin
      opcinh <= 0;
      opcclk <= 0;
      lpc_hold <= 0;
    end
  else
    begin
      opcinh <= spy[2];
      opcclk <= spy[1];
      lpc_hold <= spy[0];
    end

initial
  begin
    opcinh = 0;
    opcclk = 0;
    lpc_hold = 0;
  end

assign opcinh_n = ~opcinh;
assign opcclk_n = ~opcclk;

wire ldclk;
assign ldclk = ~ldclk_n;

always @(posedge ldclk or negedge reset_n)
  if (reset_n == 0)
    begin
      ldstat <= 0;
      idebug <= 0;
      nop11 <= 0;
      step <= 0;
    end
  else
    begin
      ldstat <= spy[4];
      idebug <= spy[3];
      nop11 <= spy[2];
      step <= spy[1];
    end

initial
  begin
    ldstat = 0;
    idebug = 0;
    nop11 = 0;
    step = 0;
  end

assign ldstat_n = ~ldstat;
assign idebug_n = ~idebug;
assign nop11_n = ~nop11;
assign step_n = ~step;

always @(posedge ldclk_n or negedge clock_reset_n or negedge boot_n)
  if (boot_n == 1'b0)
    run <= 1'b1;
  else
    if (clock_reset_n == 1'b0)
      run <= 1'b0;
    else
      run <= spy[0];

always @(posedge MCLK or negedge clock_reset_n)
  if (clock_reset_n == 0)
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
    end

initial
  begin
    srun = 0;
    sstep = 0;
    ssdone = 0;
    promdisabled = 0;
  end

//xxx delay line
//assign speedclk = !(tpr60_n);

//always @(posedge speedclk)
//  begin
//    speed0a <= speed0;
//    speed1a <= speed1;
//    sspeed0 <= speed0a;
//    sspeed1 <= speed1a;
//  end
//
//always @(clock_reset_n)
//  if (clock_reset_n == 0)
//    begin
//      speed0a = 0;
//      speed1a = 0;
//      sspeed0 = 0;
//      sspeed1 = 0;
//    end

initial
    begin
      speed0a = 0;
      speed1a = 0;
      sspeed0 = 0;
      sspeed1 = 0;
    end

assign ssdone_n = ~ssdone;

assign machrun = (sstep & ssdone_n) | (srun & errhalt_n &
		wait_n & stathalt_n);

//assign stat_ovf = ~stc32;
//assign stat_ovf = 0'b0;
assign stathalt_n = !(statstop & stathenb);

// page OLORD2

assign spcoparok = 1;
assign vm0parok = 1;
assign pdlparok = 1;

always @(posedge CLK)
  begin
    ape_n <= aparok;
    mpe_n <= mmemparok;
    pdlpe_n <= pdlparok;
    dpe_n <= dparok;
    ipe_n <= iparok;
    spe_n <= spcparok;
    higherr_n <= highok;
    mempe_n <= memparok;

    v0pe_n <= v0parok;
    v1pe_n <= vm0parok;
    statstop <= stat_ovf;
    halted_n <= halt_n;
  end

assign lowerhighok_n = 0;
assign highok = 1;
assign ldmode = !ldmode_n;

assign prog_reset_n = !(ldmode & spy[6]);

assign reset = !(boot_n & clock_reset_n & prog_reset_n);
assign reset_n = ~reset;

assign err = ~ape_n | ~mpe_n | ~pdlpe_n | ~dpe_n |
	~ipe_n | ~spe_n | ~higherr_n | ~mempe_n |
	~v0pe_n | ~v1pe_n | ~halted_n;

assign errhalt_n = !(errstop & err);

// external
assign prog_bus_reset = 0;

assign bus_reset_n  = !(prog_bus_reset | power_reset);
assign bus_power_reset_n  = ~power_reset;

//external power_reset_n - low by rc, external input
assign power_reset  = ~power_reset_n;

// external
assign busint_lm_reset_n = 1;

assign clock_reset_n = !(power_reset | !busint_lm_reset_n);

assign prog_boot = ldmode & spy[7];

assign boot_n  = !(!boot1_n | (!boot2_n | prog_boot));

always @(posedge CLK or negedge clock_reset_n or negedge boot_n)
  if (clock_reset_n == 0)
    boot_trap <= 0;
  else
    if (boot_n == 1'b0)
      boot_trap <= 1'b1;
    else
      if (srun == 1'b1)
        boot_trap <= 1'b0;

// page OPCS

assign opcclka = !(~CLK | opcclk);

wire opc_inh_or_clka;
assign opc_inh_or_clka = opcinh | opcclka;

always @(posedge opc_inh_or_clka)
  opc <= pc;

initial
  opc = 0;

// With the machine stopped, taking OPCCLK high then low will
// generate a clock to just the OPCS.
// Setting OPCINH high will prevent the OPCS from clocking when
// the machine runs.  Only change OPCINH when CLK is high 
// (e.g. machine stopped).


// page PCTL

assign bottom_1k = !(pc[13] | pc[12] | pc[11] | pc[10]);
assign promenable_n = !(bottom_1k & idebug_n & promdisabled_n & iwrited_n);

assign promce_n = promenable_n | pc[9];

assign prompc_n = ~pc[11:0];

// page PROM0

part_512x49prom  i_PROM0 (
  .A(prompc_n[8:0]),
  .D(iprom),
  .CE_N(promce_n)
);

// page IRAM

part_16kx49ram  i_IRAM (
  .A(pc),
  .DO(iram),
  .DI(iwr),
  .WE_N(iwe_n),
  .CE_N(1'b0/*ice*/)
);

// page SPY0

/* read registers */
assign {spy_obh_n, spy_obl_n, spy_pc_n, spy_opc_n,
	spy_nc_n,spy_irh_n, spy_irm_n, spy_irl_n} =
  (eadr[3] & dbread_n) ? 8'b11111111 :
	({eadr[2],eadr[1],eadr[0]} == 3'b000) ? 8'b11111110 :
	({eadr[2],eadr[1],eadr[0]} == 3'b001) ? 8'b11111101 :
	({eadr[2],eadr[1],eadr[0]} == 3'b010) ? 8'b11111011 :
	({eadr[2],eadr[1],eadr[0]} == 3'b011) ? 8'b11110111 :
	({eadr[2],eadr[1],eadr[0]} == 3'b100) ? 8'b11101111 :
	({eadr[2],eadr[1],eadr[0]} == 3'b101) ? 8'b11011111 :
	({eadr[2],eadr[1],eadr[0]} == 3'b110) ? 8'b10111111 :
	                                        8'b01111111;

/* read registers */
assign {spy_sth_n,spy_stl_n,spy_ah_n,spy_al_n,
	spy_mh_n,spy_ml_n,spy_flag2_n,spy_flag1_n} =
  (~eadr[3] & dbread_n) ? 8'b11111111 :
	({eadr[2],eadr[1],eadr[0]} == 3'b000) ? 8'b11111110 :
	({eadr[2],eadr[1],eadr[0]} == 3'b001) ? 8'b11111101 :
	({eadr[2],eadr[1],eadr[0]} == 3'b010) ? 8'b11111011 :
	({eadr[2],eadr[1],eadr[0]} == 3'b011) ? 8'b11110111 :
	({eadr[2],eadr[1],eadr[0]} == 3'b100) ? 8'b11101111 :
	({eadr[2],eadr[1],eadr[0]} == 3'b101) ? 8'b11011111 :
	({eadr[2],eadr[1],eadr[0]} == 3'b110) ? 8'b10111111 :
	                                        8'b01111111;

/* load registers */
assign {ldmode_n,ldopc_n,ldclk_n, lddbirh_n,lddbirm_n,lddbirl_n} =
  (dbwrite_n) ? 6'b111111 :
	({eadr[2],eadr[1],eadr[0]} == 3'b000) ? 6'b111110 :
	({eadr[2],eadr[1],eadr[0]} == 3'b001) ? 6'b111101 :
	({eadr[2],eadr[1],eadr[0]} == 3'b010) ? 6'b111011 :
	({eadr[2],eadr[1],eadr[0]} == 3'b011) ? 6'b110111 :
	({eadr[2],eadr[1],eadr[0]} == 3'b100) ? 6'b101111 :
	({eadr[2],eadr[1],eadr[0]} == 3'b101) ? 6'b011111 :
	                                        6'b111111;


// *******
// Clocks
// This circuitry is lifted from the LM-2, which replaced the delay
// lines with a clock chain.
// *******

//xxx need to clean these up
assign mclk0_n  = tpclk_n;

assign MCLK = !mclk0_n;
//assign CLK = lclk_n;
assign CLK = lclk;

//assign clk0_n = tpclk_n & machrun;

// LM-2 clocks

// -------

assign clk_n = tpclk_n & machrun;

assign lclk = ! clk_n ;
assign lclk_n = ! lclk ;
assign ltse_n = ! tptse ;
assign tse = ! ltse_n ;
assign lwp_n = ! tpwp ;
assign wp = ! lwp_n ;

assign tpr0a = ! tpr0_n ;
assign tpr0d_n = ! tpr0a;
assign tpr1a = ! tpr1_n ;
assign tpr1d_n = ! tpr1a ;

assign tpwp = tpw1 & crbs_n & machrun;
// ?? tpwpor1
assign tpwpiram = tpwpor1 & crbs_n & machrun;

assign tptsef = ! ( tpr1d_n & crbs_n & tptsef_n );
assign iwe_n = ! ( iwrited & tpwpiram );
assign tpclk_n = ! (tpw0_n & crbs_n & tpclk );

always @(posedge hifreq1)
  begin
    tpr6_n <= tpr5;
    tpw3 <= tpw2;
    tpw3_n <= !tpw2;
    tpw2 <= tpw1;
    tpw2_n <= !tpw1;
    tpw1 <= tpw0;
    tpw1_n <= !tpw0;

    tpr5 <= tpr4;
    tpr5_n <= !tpr4;

    tpr4 <= tpr3;
    tpr4_n <= !tpr3;

    tpr3 <= tpr2;
    tpr3_n <= !tpr2;

    tpr2_n <= sone_n ;
    tpr2 <= !sone_n ;
  end

assign maskc = ! ( tendly_n & tpr1_n );
assign ff1_n = ! ( tpr1_n & ff1 );
assign tpclk = ! ( tpclk_n & tpr0_n );
assign tptsef_n = ! ( tpr0d_n & tptsef );

assign tpwpor1 = !( tpw0_n & tpw1_n );
assign tptse = !(tptsef_n & machrun);

assign osc0 = !osc50mhz;
assign hifreq1 = !osc0;
assign hifreq2 = !osc0;
assign hf_n = !hifreq2;
assign hfdlyd = !hf_n;
assign hftomm = !hfdlyd;

always @(posedge hifreq1)
  begin
    ff1d <= ff1;
    tpr1_n <= tpr0_n ;
    tpr1 <= !tpr0_n ;
  end

assign ff1 = !(tpw2_n & crbs_n & ff1_n);
assign tpr0_n = !(ff1d & hangs_n & crbs_n);
assign sone_n = !(tpr1 & tpr3_n & tpr4_n);

assign tprend_n = ! (
  ( { sspeed1a, sspeed0a, ilong_n } == 3'b000 ) ? tpr6_n :
  ( { sspeed1a, sspeed0a, ilong_n } == 3'b001 ) ? tpr5_n :
  ( { sspeed1a, sspeed0a, ilong_n } == 3'b010 ) ? tpr5_n :
  ( { sspeed1a, sspeed0a, ilong_n } == 3'b011 ) ? tpr4_n :
  ( { sspeed1a, sspeed0a, ilong_n } == 3'b100 ) ? tpr4_n :
  ( { sspeed1a, sspeed0a, ilong_n } == 3'b101 ) ? tpr3_n :
  ( { sspeed1a, sspeed0a, ilong_n } == 3'b110 ) ? tpr4_n :
    tpr2_n );

always @(posedge tpr1 or negedge clock_reset_n)
  if (clock_reset_n == 0)
    begin
      speed1a <= 0;
      speed0a <= 0;
      sspeed1a <= 0;
      sspeed0a <= 0;
    end
  else
    begin
      speed1a <= speed1;
      speed0a <= speed0;
      sspeed1a <= speed1a;
      sspeed0a <= speed0a;
    end

always @(posedge hfdlyd)
  tendly_n <= tprend_n;

always @(posedge hifreq2)
  begin
    tpw0_n <= maskc;
    tpw0 <= !maskc;

    hangs_n <= hang_n;
    crbs_n <= clock_reset_n ;
  end

initial
  begin
    ff1d = 0;
    crbs_n = 0;
    tpw2_n = 0;

    tpw1 = 0;
    tpw0 = 0;
    tpr1 = 0;
    tpr1_n = 0;
    tendly_n = 0;
  end


// *******
// Resets!
// *******

initial
  begin
  end

//external
//assign memack_n = 1;
//assign memgrant_n = 1;
//assign mempar_in = 0;
//assign adrpar_n = 0;
//assign loadmd = 0;
//assign ignpar_n = 1;


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

wire bus_int;

  busint busint(
	.bus(busint_bus),
	.addr({pma,vma[7:0]}),
	.spy(spy),
	.mclk(MCLK),
	.mempar_in(mempar_in),
	.adrpar_n(adrpar_n),
	.req(memrq),
	.ack_n(memack_n),
	.loadmd(loadmd),
	.ignpar(ignpar_n),
	.memgrant_n(memgrant_n),
	.wrcyc(wrcyc),
	.int(bus_int),
	.mempar_out(mempar_out),
	.reset_n(reset_n)
	);

endmodule

