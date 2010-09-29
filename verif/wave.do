onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -format Logic /test/clk100
add wave -noupdate -format Logic /test/clk50
add wave -noupdate -format Logic /test/clk25
add wave -noupdate -format Logic /test/clk1x
add wave -noupdate -format Logic /test/reset
add wave -noupdate -format Literal -radix decimal /test/cpu_state
add wave -noupdate -format Logic /test/fetch
add wave -noupdate -format Logic /test/prefetch
add wave -noupdate -format Literal -radix decimal /test/rc/state_out
add wave -noupdate -format Literal -radix hexadecimal /test/vram_vga_addr
add wave -noupdate -format Logic /test/vram_vga_req
add wave -noupdate -format Logic /test/vram_vga_ready
add wave -noupdate -format Logic /test/sdram_ready
add wave -noupdate -format Logic /test/sdram_req
add wave -noupdate -format Logic /test/sdram_write
add wave -noupdate -format Logic /test/sdram_done
add wave -noupdate -divider sram
add wave -noupdate -format Literal -radix hexadecimal /test/sram_a
add wave -noupdate -format Logic /test/sram_oe_n
add wave -noupdate -format Logic /test/sram_we_n
add wave -noupdate -format Literal /test/sram1_in
add wave -noupdate -format Literal -radix hexadecimal /test/sram1_out
add wave -noupdate -format Literal /test/sram2_in
add wave -noupdate -format Literal -radix hexadecimal /test/sram2_out
add wave -noupdate -format Logic /test/sram1_ce_n
add wave -noupdate -format Logic /test/sram1_ub_n
add wave -noupdate -format Logic /test/sram1_lb_n
add wave -noupdate -format Logic /test/sram2_ce_n
add wave -noupdate -format Logic /test/sram2_ub_n
add wave -noupdate -format Logic /test/sram2_lb_n
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {0 ns} 0}
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
WaveRestoreZoom {1504 ns} {4131 ns}
