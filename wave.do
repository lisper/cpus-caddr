add wave -noupdate -format Logic test.cpu.power_reset_n
add wave -noupdate -format Logic test.cpu.power_reset
add wave -noupdate -format Logic test.cpu.clock_reset_n
add wave -noupdate -format Logic test.cpu.busint_lm_reset_n
add wave -noupdate -divider { }
add wave -noupdate -format Logic test.cpu.machrun
add wave -noupdate -format Logic test.cpu.sstep
add wave -noupdate -format Logic test.cpu.ssdone_n
add wave -noupdate -format Logic test.cpu.srun
add wave -noupdate -format Logic test.cpu.errhalt_n
add wave -noupdate -format Logic test.cpu.wait_n
add wave -noupdate -format Logic test.cpu.stathalt_n
add wave -noupdate -divider { }
add wave -noupdate -format Logic test.cpu.boot_n
add wave -noupdate -format Logic test.cpu.run
add wave -noupdate -format Logic test.cpu.boot1_n
add wave -noupdate -format Logic test.cpu.boot2_n
add wave -noupdate -format Logic test.cpu.prog_boot
add wave -noupdate -divider { }
add wave -noupdate -format Logic test.cpu.lcinc
add wave -noupdate -format Logic test.cpu.needfetch
add wave -noupdate -divider { }
add wave -noupdate -format Logic test.cpu.CLK
add wave -noupdate -format Logic test.cpu.clk_n
add wave -noupdate -format Logic test.cpu.tpclk_n
add wave -noupdate -format Logic test.cpu.tpclk
add wave -noupdate -format Logic test.cpu.tse
add wave -noupdate -format Logic test.cpu.wp
add wave -noupdate -divider { }
add wave -noupdate -format Logic test.cpu.reset
add wave -noupdate -format Logic test.cpu.boot_n
add wave -noupdate -format Logic test.cpu.clock_reset_n
add wave -noupdate -format Logic test.cpu.prog_reset_n
add wave -noupdate -format Logic test.cpu.spy
add wave -noupdate -divider { }
add wave -noupdate -format Logic test.cpu.sspeed0
add wave -noupdate -format Logic test.cpu.sspeed1
add wave -noupdate -format Logic test.cpu.tpclk
add wave -noupdate -format Logic test.cpu.tpwp
add wave -noupdate -format Logic test.cpu.machrun
add wave -noupdate -format Logic test.cpu.cyclecompleted
add wave -noupdate -divider { }
add wave -noupdate -format Literal -radix hexadecimal test.cpu.reta
add wave -noupdate -format Literal -radix hexadecimal test.cpu.wpc
add wave -noupdate -format Literal -radix hexadecimal test.cpu.spcw
add wave -noupdate -format Literal -radix hexadecimal test.cpu.spco
add wave -noupdate -format Literal -radix hexadecimal test.cpu.spcptr
add wave -noupdate -divider { }
add wave -noupdate -format Literal -radix hexadecimal test.cpu.pc
add wave -noupdate -format Literal -radix hexadecimal test.cpu.npc
add wave -noupdate -format Literal -radix hexadecimal test.cpu.ipc
add wave -noupdate -format Literal -radix hexadecimal test.cpu.lpc
add wave -noupdate -format Literal -radix hexadecimal test.cpu.dpc
add wave -noupdate -format Literal -radix hexadecimal test.cpu.spc
add wave -noupdate -format Literal -radix hexadecimal test.cpu.ir
add wave -noupdate -divider { }
add wave -noupdate -format Literal -radix hexadecimal test.cpu.npc
add wave -noupdate -format Literal -radix hexadecimal test.cpu.trap
add wave -noupdate -format Literal -radix hexadecimal test.cpu.pcs1
add wave -noupdate -format Literal -radix hexadecimal test.cpu.pcs0
add wave -noupdate -divider { }
add wave -noupdate -format Literal -radix hexadecimal test.cpu.conds
add wave -noupdate -format Literal -radix hexadecimal test.cpu.jfalse
add wave -noupdate -format Literal -radix hexadecimal test.cpu.jcond
add wave -noupdate -format Literal -radix hexadecimal test.cpu.irjump
add wave -noupdate -format Literal -radix hexadecimal test.cpu.dispenb
add wave -noupdate -format Literal -radix hexadecimal test.cpu.dr
add wave -noupdate -format Literal -radix hexadecimal test.cpu.dp
add wave -noupdate -format Literal -radix hexadecimal test.cpu.dn
add wave -noupdate -format Logic test.cpu.CLK
add wave -noupdate -divider { }
add wave -noupdate -format Literal -radix hexadecimal test.cpu.mskl
add wave -noupdate -format Literal -radix hexadecimal test.cpu.msk_left_out
add wave -noupdate -format Literal -radix hexadecimal test.cpu.mskr
add wave -noupdate -format Literal -radix hexadecimal test.cpu.msk_right_out
add wave -noupdate -format Literal -radix hexadecimal test.cpu.msk
add wave -noupdate -divider { }
add wave -noupdate -format Literal -radix hexadecimal test.cpu.mpass
add wave -noupdate -format Literal -radix hexadecimal test.cpu.mpassm_n
add wave -noupdate -format Literal -radix hexadecimal test.cpu.pdldrive_n
add wave -noupdate -format Literal -radix hexadecimal test.cpu.spcdrive_n
add wave -noupdate -divider { }
add wave -noupdate -format Literal -radix hexadecimal test.cpu.alumode
add wave -noupdate -format Literal -radix hexadecimal test.cpu.aluf
add wave -noupdate -format Literal -radix hexadecimal test.cpu.aeqm_bits
add wave -noupdate -format Literal -radix hexadecimal test.cpu.aeqm
add wave -noupdate -format Literal -radix hexadecimal test.cpu.aluneg
add wave -noupdate -format Literal -radix hexadecimal test.cpu.alu
add wave -noupdate -format Literal -radix hexadecimal test.cpu.m
add wave -noupdate -format Literal -radix hexadecimal test.cpu.a
add wave -noupdate -format Literal -radix hexadecimal test.cpu.l
add wave -noupdate -format Literal -radix hexadecimal test.cpu.q
add wave -noupdate -format Literal -radix hexadecimal test.cpu.r
add wave -noupdate -format Literal -radix hexadecimal test.cpu.sa
add wave -noupdate -format Literal -radix hexadecimal test.cpu.latched_amem
add wave -noupdate -format Literal -radix hexadecimal test.cpu.amemenb_n
add wave -noupdate -divider { }
add wave -noupdate -format Literal -radix hexadecimal test.cpu.srcq
add wave -noupdate -format Literal -radix hexadecimal test.cpu.qdrive
add wave -noupdate -format Literal -radix hexadecimal test.cpu.mfdrive
add wave -noupdate -format Literal -radix hexadecimal test.cpu.mf
add wave -noupdate -format Literal -radix hexadecimal test.cpu.mem
add wave -noupdate -divider { }
add wave -noupdate -format Literal -radix hexadecimal test.cpu.aadr
add wave -noupdate -format Literal -radix hexadecimal test.cpu.amem
add wave -noupdate -format Literal -radix hexadecimal test.cpu.l
add wave -noupdate -format Literal -radix hexadecimal test.cpu.awp_n
add wave -noupdate -divider { }
add wave -noupdate -format Literal -radix hexadecimal test.cpu.wadr
add wave -noupdate -format Literal -radix hexadecimal test.cpu.madr
add wave -noupdate -format Literal -radix hexadecimal test.cpu.mmem
add wave -noupdate -format Literal -radix hexadecimal test.cpu.l
add wave -noupdate -format Literal -radix hexadecimal test.cpu.mwp_n
add wave -noupdate -divider { }
add wave -noupdate -format Literal -radix hexadecimal test.cpu.alusub
add wave -noupdate -format Literal -radix hexadecimal test.cpu.mulnop_n
add wave -noupdate -format Literal -radix hexadecimal test.cpu.a
add wave -noupdate -format Literal -radix hexadecimal test.cpu.divsubcond
add wave -noupdate -format Literal -radix hexadecimal test.cpu.divaddcond
add wave -noupdate -format Literal -radix hexadecimal test.cpu.irjump_n
add wave -noupdate -divider { }
add wave -noupdate -format Literal -radix hexadecimal test.cpu.q
add wave -noupdate -format Literal -radix hexadecimal test.cpu.mul_n
add wave -noupdate -format Literal -radix hexadecimal test.cpu.div_n
add wave -noupdate -format Literal -radix hexadecimal test.cpu.divposlasttime_n
add wave -noupdate -divider { }
add wave -noupdate -format Literal -radix hexadecimal test.cpu.aluf_n
add wave -noupdate -format Literal -radix hexadecimal test.cpu.alusub
add wave -noupdate -format Literal -radix hexadecimal test.cpu.aluadd
add wave -noupdate -format Literal -radix hexadecimal test.cpu.ob
add wave -noupdate -format Literal -radix hexadecimal test.cpu.osel
add wave -noupdate -format Logic test.cpu.destimod1_n
add wave -noupdate -format Logic test.cpu.destimod0_n
add wave -noupdate -format Literal -radix hexadecimal test.cpu.irbyte_n
add wave -noupdate -divider { }
add wave -noupdate -format Literal -radix hexadecimal test.cpu.irdisp_n
add wave -noupdate -format Literal -radix hexadecimal test.cpu.irjump_n
add wave -noupdate -format Literal -radix hexadecimal test.cpu.iralu_n
add wave -noupdate -format Literal -radix hexadecimal test.cpu.popj
add wave -noupdate -format Literal -radix hexadecimal test.cpu.ignpopj_n
add wave -noupdate -divider { }
add wave -noupdate -format Logic test.cpu.ir
add wave -noupdate -format Logic test.cpu.iob
add wave -noupdate -format Logic test.cpu.i
add wave -noupdate -format Logic test.cpu.iprom
add wave -noupdate -format Logic test.cpu.idebug_n
add wave -noupdate -format Logic test.cpu.promce_n
add wave -noupdate -format Logic test.cpu.promenable_n
add wave -noupdate -format Logic test.cpu.bottom_1k
add wave -noupdate -format Logic test.cpu.idebug_n
add wave -noupdate -format Logic test.cpu.promdisabled_n
add wave -noupdate -format Logic test.cpu.iwrited_n
configure wave -namecolwidth 150
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
