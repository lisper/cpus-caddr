onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -format Logic /test/cpu/CLK
add wave -noupdate -format Logic /test/clk
add wave -noupdate -format Logic /test/cpu/CLK
add wave -noupdate -format Logic /test/cpu/tpw1
add wave -noupdate -format Logic /test/cpu/tpw2
add wave -noupdate -format Logic /test/cpu/wp
add wave -noupdate -divider {New Divider}
add wave -noupdate -format Logic /test/cpu/needfetch
add wave -noupdate -format Logic /test/cpu/have_wrong_word
add wave -noupdate -format Logic /test/cpu/last_byte_in_word
add wave -noupdate -format Logic /test/cpu/lc0b
add wave -noupdate -format Logic /test/cpu/newlc_n
add wave -noupdate -format Logic /test/cpu/destlc_n
add wave -noupdate -format Literal -radix octal /test/cpu/lc
add wave -noupdate -divider {New Divider}
add wave -noupdate -format Logic /test/cpu/machrun
add wave -noupdate -format Logic /test/cpu/srun
add wave -noupdate -format Logic /test/cpu/run
add wave -noupdate -format Logic /test/cpu/boot_n
add wave -noupdate -format Logic /test/cpu/boot2_n
add wave -noupdate -format Logic /test/cpu/boot1_n
add wave -noupdate -format Logic /test/cpu/power_reset_n
add wave -noupdate -format Logic /test/cpu/clock_reset_n
add wave -noupdate -divider {New Divider}
add wave -noupdate -format Literal -radix octal /test/cpu/lpc
add wave -noupdate -format Literal -radix octal /test/cpu/npc
add wave -noupdate -format Literal -radix octal /test/cpu/pc
add wave -noupdate -format Literal -radix hexadecimal /test/cpu/dpc
add wave -noupdate -format Literal -radix octal /test/cpu/ipc
add wave -noupdate -format Literal -radix hexadecimal /test/cpu/ir
add wave -noupdate -format Literal -radix hexadecimal /test/cpu/ob
add wave -noupdate -format Literal -radix hexadecimal /test/cpu/iob
add wave -noupdate -format Logic /test/cpu/destimod0_n
add wave -noupdate -format Logic /test/cpu/destimod1_n
add wave -noupdate -format Logic /test/cpu/irbyte_n
add wave -noupdate -format Logic /test/cpu/irdisp_n
add wave -noupdate -format Logic /test/cpu/irjump_n
add wave -noupdate -format Logic /test/cpu/iralu_n
add wave -noupdate -format Logic /test/cpu/CLK
add wave -noupdate -divider Jump
add wave -noupdate -format Logic /test/cpu/jcond
add wave -noupdate -format Logic /test/cpu/jfalse
add wave -noupdate -format Literal /test/cpu/conds
add wave -noupdate -format Literal /test/cpu/aluf
add wave -noupdate -format Logic /test/cpu/alumode
add wave -noupdate -format Logic /test/cpu/cin0_n
add wave -noupdate -format Logic /test/cpu/aluadd
add wave -noupdate -format Logic /test/cpu/alusub
add wave -noupdate -format Logic /test/cpu/pcs0
add wave -noupdate -format Logic /test/cpu/pcs1
add wave -noupdate -divider Shift
add wave -noupdate -format Literal -radix hexadecimal /test/cpu/r
add wave -noupdate -format Literal -radix hexadecimal /test/cpu/sa
add wave -noupdate -format Logic /test/cpu/s0
add wave -noupdate -format Logic /test/cpu/s1
add wave -noupdate -format Logic /test/cpu/s2
add wave -noupdate -format Logic /test/cpu/s3
add wave -noupdate -format Logic /test/cpu/s4
add wave -noupdate -divider {M & A bus}
add wave -noupdate -format Literal -radix hexadecimal /test/cpu/alu
add wave -noupdate -format Literal -radix hexadecimal /test/cpu/q
add wave -noupdate -format Literal /test/cpu/aeqm_bits
add wave -noupdate -format Literal -radix hexadecimal /test/cpu/a
add wave -noupdate -format Literal -radix hexadecimal /test/cpu/m
add wave -noupdate -format Literal -radix hexadecimal /test/cpu/mmem_latched
add wave -noupdate -format Logic /test/cpu/mpassm_n
add wave -noupdate -format Logic /test/cpu/pdldrive_n
add wave -noupdate -format Logic /test/cpu/spcdrive_n
add wave -noupdate -format Logic /test/cpu/mfdrive_n
add wave -noupdate -divider {M & A mem}
add wave -noupdate -format Logic /test/cpu/CLK
add wave -noupdate -format Literal -radix hexadecimal /test/cpu/wadr
add wave -noupdate -format Literal -radix hexadecimal /test/cpu/madr
add wave -noupdate -format Literal -radix hexadecimal /test/cpu/mmem
add wave -noupdate -format Logic /test/cpu/mwp_n
add wave -noupdate -format Literal -radix hexadecimal /test/cpu/aadr
add wave -noupdate -format Literal -radix hexadecimal /test/cpu/amem
add wave -noupdate -format Logic /test/cpu/awp_n
add wave -noupdate -format Literal -radix hexadecimal /test/cpu/l
add wave -noupdate -divider {New Divider}
add wave -noupdate -format Literal -radix hexadecimal /test/cpu/mf
add wave -noupdate -format Logic /test/cpu/lcdrive_n
add wave -noupdate -format Logic /test/cpu/opcdrive_n
add wave -noupdate -format Logic /test/cpu/dcdrive
add wave -noupdate -format Logic /test/cpu/ppdrive_n
add wave -noupdate -format Logic /test/cpu/pidrive
add wave -noupdate -format Logic /test/cpu/qdrive
add wave -noupdate -format Logic /test/cpu/mddrive_n
add wave -noupdate -format Logic /test/cpu/mpassl_n
add wave -noupdate -format Logic /test/cpu/vmadrive_n
add wave -noupdate -divider {New Divider}
add wave -noupdate -format Literal -radix hexadecimal /test/cpu/q
add wave -noupdate -format Logic /test/cpu/qs1
add wave -noupdate -format Logic /test/cpu/qs0
add wave -noupdate -format Literal -radix hexadecimal /test/cpu/ob
add wave -noupdate -format Literal /test/cpu/osel
add wave -noupdate -format Literal -radix hexadecimal /test/cpu/mskl
add wave -noupdate -format Literal -radix hexadecimal /test/cpu/mskr
add wave -noupdate -format Literal -radix octal /test/cpu/msk
add wave -noupdate -format Literal -radix octal /test/cpu/r
add wave -noupdate -format Literal -radix octal /test/cpu/a
add wave -noupdate -format Logic /test/cpu/CLK
add wave -noupdate -divider SPC
add wave -noupdate -format Literal -radix hexadecimal /test/cpu/spcptr
add wave -noupdate -format Logic /test/cpu/swp_n
add wave -noupdate -format Logic /test/cpu/spcnt_n
add wave -noupdate -format Logic /test/cpu/spush_n
add wave -noupdate -format Logic /test/cpu/spop_n
add wave -noupdate -format Literal -radix hexadecimal /test/cpu/spcw
add wave -noupdate -format Literal -radix hexadecimal /test/cpu/spco
add wave -noupdate -format Literal -radix hexadecimal /test/cpu/spco_latched
add wave -noupdate -format Logic /test/cpu/spcdrive_n
add wave -noupdate -format Literal -radix hexadecimal /test/cpu/spc
add wave -noupdate -divider PDL
add wave -noupdate -format Literal -radix hexadecimal /test/cpu/pdlidx
add wave -noupdate -format Literal -radix hexadecimal /test/cpu/pdlptr
add wave -noupdate -format Literal -radix hexadecimal /test/cpu/pdla
add wave -noupdate -format Logic /test/cpu/pwp_n
add wave -noupdate -format Logic /test/cpu/pdlwrite
add wave -noupdate -format Logic /test/cpu/pdlwrited
add wave -noupdate -format Logic /test/cpu/destpdltop_n
add wave -noupdate -format Logic /test/cpu/destpdl_x_n
add wave -noupdate -format Logic /test/cpu/destpdl_p_n
add wave -noupdate -format Logic /test/cpu/destm
add wave -noupdate -divider {VMA memory}
add wave -noupdate -format Literal -radix hexadecimal /test/cpu/md
add wave -noupdate -format Logic /test/cpu/mdclk
add wave -noupdate -format Literal -radix hexadecimal /test/cpu/mds
add wave -noupdate -format Logic /test/cpu/vm0wp_n
add wave -noupdate -format Literal -radix hexadecimal /test/cpu/mapi
add wave -noupdate -format Logic /test/cpu/vm1wp_n
add wave -noupdate -format Logic /test/cpu/wmap
add wave -noupdate -format Logic /test/cpu/wmapd
add wave -noupdate -format Literal -radix hexadecimal /test/cpu/vma
add wave -noupdate -format Literal -radix hexadecimal /test/cpu/vmas
add wave -noupdate -format Literal -radix hexadecimal /test/cpu/ob
add wave -noupdate -divider IRAM
add wave -noupdate -format Literal -radix octal /test/cpu/pc
add wave -noupdate -format Literal -radix hexadecimal /test/cpu/iwr
add wave -noupdate -format Logic /test/cpu/iwe_n
add wave -noupdate -divider {Dispatch mem}
add wave -noupdate -format Literal -radix hexadecimal /test/cpu/md
add wave -noupdate -format Logic /test/cpu/dwe_n
add wave -noupdate -format Literal -radix hexadecimal /test/cpu/dadr_n
add wave -noupdate -format Literal -radix hexadecimal /test/cpu/dmask
add wave -noupdate -format Literal -radix hexadecimal /test/cpu/r
add wave -noupdate -format Literal -radix octal /test/cpu/lpc
add wave -noupdate -divider {New Divider}
add wave -noupdate -format Logic /test/cpu/pgf_or_int
add wave -noupdate -format Logic /test/cpu/pgf_or_int_or_sb
add wave -noupdate -format Logic /test/cpu/pfr_n
add wave -noupdate -format Logic /test/cpu/pfw_n
add wave -noupdate -format Literal /test/cpu/lvmo_n
add wave -noupdate -format Literal -radix hexadecimal /test/cpu/pma
add wave -noupdate -format Literal -radix hexadecimal /test/cpu/vmem1_adr
add wave -noupdate -format Literal -radix hexadecimal /test/cpu/vmo
add wave -noupdate -format Logic /test/cpu/vmaok_n
add wave -noupdate -format Logic /test/cpu/sint
add wave -noupdate -format Logic /test/cpu/sintr
add wave -noupdate -format Logic /test/cpu/int
add wave -noupdate -divider {Bus Interface}
add wave -noupdate -format Logic /test/cpu/wmap_n
add wave -noupdate -format Logic /test/cpu/memrd_n
add wave -noupdate -format Logic /test/cpu/memwr_n
add wave -noupdate -format Logic /test/cpu/destmem_n
add wave -noupdate -format Logic /test/cpu/memop_n
add wave -noupdate -format Logic /test/cpu/memstart
add wave -noupdate -format Logic /test/cpu/memrq
add wave -noupdate -format Logic /test/cpu/memprepare
add wave -noupdate -format Logic /test/cpu/memack_n
add wave -noupdate -format Logic /test/cpu/mfinish_n
add wave -noupdate -format Logic /test/cpu/mfinishd_n
add wave -noupdate -format Logic /test/cpu/rdfinish_n
add wave -noupdate -format Logic /test/cpu/wait_n
add wave -noupdate -format Logic /test/cpu/memgrant_n
add wave -noupdate -format Logic /test/cpu/mbusy
add wave -noupdate -format Logic /test/cpu/use_md
add wave -noupdate -format Logic /test/cpu/wmap
add wave -noupdate -format Logic /test/cpu/wmapd
add wave -noupdate -format Logic /test/cpu/rdcyc
add wave -noupdate -format Logic /test/cpu/wrcyc
add wave -noupdate -format Literal -radix hexadecimal /test/cpu/vmo
add wave -noupdate -format Literal -radix hexadecimal /test/cpu/pma
add wave -noupdate -format Logic /test/cpu/loadmd
add wave -noupdate -format Logic /test/cpu/mdsel
add wave -noupdate -format Logic /test/cpu/memdrive_n
add wave -noupdate -format Literal -radix hexadecimal /test/cpu/md
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {34420 ns} 0} {{Cursor 2} {65668 ns} 0}
configure wave -namecolwidth 180
configure wave -valuecolwidth 94
configure wave -justifyvalue right
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
update
WaveRestoreZoom {33860 ns} {36180 ns}
