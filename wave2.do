onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -format logic /test/cpu/sspeed0
add wave -noupdate -format logic /test/cpu/sspeed1
add wave -noupdate -format logic /test/cpu/tpclk
add wave -noupdate -format logic /test/cpu/tpr0_n
add wave -noupdate -format logic /test/cpu/tpwp
add wave -noupdate -format logic /test/cpu/cyclecompleted
add wave -noupdate -divider {}
add wave -noupdate -format logic /test/cpu/reset
add wave -noupdate -format logic /test/cpu/internal4
add wave -noupdate -divider {}
add wave -noupdate -format literal -radix hexadecimal /test/cpu/reta
add wave -noupdate -format literal -radix hexadecimal /test/cpu/ipc
add wave -noupdate -format literal -radix hexadecimal /test/cpu/wpc
add wave -noupdate -format literal -radix hexadecimal /test/cpu/spcw
add wave -noupdate -format literal -radix hexadecimal /test/cpu/spco
add wave -noupdate -format literal -radix hexadecimal /test/cpu/spcptr
add wave -noupdate -divider {}
add wave -noupdate -format literal -radix hexadecimal /test/cpu/pc
add wave -noupdate -format literal -radix hexadecimal /test/cpu/lpc
add wave -noupdate -format literal -radix hexadecimal /test/cpu/ir
add wave -noupdate -format literal -radix hexadecimal /test/cpu/ob
add wave -noupdate -divider {}
add wave -noupdate -format logic /test/cpu/a
add wave -noupdate -format logic /test/cpu/m
add wave -noupdate -format logic /test/cpu/aeqm
add wave -noupdate -divider {}
add wave -noupdate -format logic /test/cpu/iralu_n
add wave -noupdate -format logic /test/cpu/irjump_n
add wave -noupdate -format logic /test/cpu/irdisp_n
add wave -noupdate -format logic /test/cpu/irbyte_n
add wave -noupdate -divider {}
add wave -noupdate -format logic /test/cpu/clk4b
add wave -noupdate -format logic /test/cpu/npc
add wave -noupdate -format logic /test/cpu/pcs1
add wave -noupdate -format logic /test/cpu/pcs0
add wave -noupdate -divider {}
add wave -noupdate -format logic /test/cpu/pgf_or_int_or_sb
add wave -noupdate -format logic /test/cpu/pgf_or_int
add wave -noupdate -format logic /test/cpu/vmaok_n
add wave -noupdate -format logic /test/cpu/aeqm
add wave -noupdate -format logic /test/cpu/alu32
add wave -noupdate -format logic /test/cpu/aluneg
add wave -noupdate -format logic /test/cpu/r0
add wave -noupdate -format logic /test/cpu/jcond
add wave -noupdate -format logic /test/cpu/conds2
add wave -noupdate -format logic /test/cpu/conds1
add wave -noupdate -format logic /test/cpu/conds0
add wave -noupdate -divider {}
add wave -noupdate -format literal -radix hexadecimal /test/cpu/alu0
add wave -noupdate -format literal -radix hexadecimal /test/cpu/alu1
add wave -noupdate -format literal -radix hexadecimal /test/cpu/r0
add wave -noupdate -format literal -radix hexadecimal /test/cpu/a0
add wave -noupdate -format literal -radix hexadecimal /test/cpu/a0
add wave -noupdate -format literal -radix hexadecimal /test/cpu/osel1b
add wave -noupdate -format literal -radix hexadecimal /test/cpu/osel0b
add wave -noupdate -format literal -radix hexadecimal /test/cpu/msk0
add wave -noupdate -format literal -radix hexadecimal /test/cpu/q31
add wave -noupdate -divider {}
add wave -noupdate -format literal -radix hexadecimal /test/cpu/ir
add wave -noupdate -format literal -radix hexadecimal /test/cpu/vmo
add wave -noupdate -format literal -radix hexadecimal /test/cpu/dmask0
add wave -noupdate -format literal -radix hexadecimal /test/cpu/dmapbenb_n
add wave -noupdate -format literal -radix hexadecimal /test/cpu/dadr0c_n
add wave -noupdate -format literal -radix hexadecimal /test/cpu/vmo
add wave -noupdate -format literal -radix hexadecimal /test/cpu/ir
add wave -noupdate -divider {}
add wave -noupdate -format literal -radix hexadecimal /test/cpu/mskr
add wave -noupdate -divider {}
add wave -noupdate -format logic /test/cpu/iob39
add wave -noupdate -format logic /test/cpu/i39
add wave -noupdate -format logic /test/cpu/ob13
add wave -noupdate -format logic /test/cpu/osel1b
add wave -noupdate -format logic /test/cpu/osel0b
add wave -noupdate -format logic /test/cpu/msk13
add wave -noupdate -format logic /test/cpu/alu12
add wave -noupdate -format logic /test/cpu/alu14
add wave -noupdate -format logic /test/cpu/alu13
add wave -noupdate -format logic /test/cpu/r13
add wave -noupdate -format logic /test/cpu/a13
add wave -noupdate -divider {}
add wave -noupdate -format logic /test/cpu/aluf3b
add wave -noupdate -format logic /test/cpu/aluf2b
add wave -noupdate -format logic /test/cpu/aluf1b
add wave -noupdate -format logic /test/cpu/aluf0b
add wave -noupdate -format logic /test/cpu/\\-cin12\\
add wave -noupdate -format logic /test/cpu/alumode
add wave -noupdate -format logic /test/cpu/alu12
add wave -noupdate -format logic /test/cpu/alu13
add wave -noupdate -format logic /test/cpu/alu14
add wave -noupdate -format logic /test/cpu/alu15
add wave -noupdate -format logic /test/cpu/aeqm
add wave -noupdate -format logic /test/cpu/xout15
add wave -noupdate -format logic /test/cpu/nc461
add wave -noupdate -format logic /test/cpu/yout15
add wave -noupdate -format logic /test/cpu/a15
add wave -noupdate -format logic /test/cpu/a14
add wave -noupdate -format logic /test/cpu/a13
add wave -noupdate -format logic /test/cpu/a12
add wave -noupdate -format logic /test/cpu/m15
add wave -noupdate -format logic /test/cpu/m14
add wave -noupdate -format logic /test/cpu/m13
add wave -noupdate -format logic /test/cpu/m12
add wave -noupdate -divider {}
add wave -noupdate -format logic /test/cpu/yout3
add wave -noupdate -format logic /test/cpu/xout3
add wave -noupdate -format logic /test/cpu/yout7
add wave -noupdate -format logic /test/cpu/xout7
add wave -noupdate -format logic /test/cpu/yout11
add wave -noupdate -format logic /test/cpu/xout11
add wave -noupdate -format logic /test/cpu/yout15
add wave -noupdate -format logic /test/cpu/xout15
add wave -noupdate -format logic /test/cpu/xx0
add wave -noupdate -format logic /test/cpu/\\-cin12\\
add wave -noupdate -format logic /test/cpu/yy0
add wave -noupdate -format logic /test/cpu/\\-cin8\\
add wave -noupdate -format logic /test/cpu/\\-cin4\\
add wave -noupdate -format logic /test/cpu/\\-cin0\\
add wave -noupdate -divider {}
add wave -noupdate -format logic /test/cpu/a3
add wave -noupdate -format logic /test/cpu/a2
add wave -noupdate -format logic /test/cpu/a1
add wave -noupdate -format logic /test/cpu/a0
add wave -noupdate -format logic /test/cpu/m3
add wave -noupdate -format logic /test/cpu/m2
add wave -noupdate -format logic /test/cpu/m1
add wave -noupdate -format logic /test/cpu/m0
add wave -noupdate -format logic /test/cpu/aluf3b
add wave -noupdate -format logic /test/cpu/aluf2b
add wave -noupdate -format logic /test/cpu/aluf1b
add wave -noupdate -format logic /test/cpu/aluf0b
add wave -noupdate -format logic /test/cpu/\\-cin0\\
add wave -noupdate -format logic /test/cpu/alumode
add wave -noupdate -format logic /test/cpu/alu0
add wave -noupdate -format logic /test/cpu/alu1
add wave -noupdate -format logic /test/cpu/alu2
add wave -noupdate -format logic /test/cpu/alu3
add wave -noupdate -format logic /test/cpu/aeqm
add wave -noupdate -format logic /test/cpu/xout3
add wave -noupdate -format logic /test/cpu/nc464
add wave -noupdate -format logic /test/cpu/yout3
add wave -noupdate -divider {}
add wave -noupdate -format logic /test/cpu/ir39
add wave -noupdate -format logic /test/cpu/\\-destimod1\\
add wave -noupdate -format logic /test/cpu/i_iram33_2b26/do
add wave -noupdate -format logic /test/cpu/clk3b
add wave -noupdate -format logic /test/cpu/\\-promce0\\
add wave -noupdate -format logic /test/cpu/\\-promce1\\
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {290 ns} 0}
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
update
WaveRestoreZoom {0 ns} {1 us}
