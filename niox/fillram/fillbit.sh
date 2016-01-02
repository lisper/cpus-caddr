#!/bin/sh

ELF=../cli/diag.elf
BIT=../ise/test_niox.bit
RAM0=../cli/niox_dram0.hex
RAM1=../cli/niox_dram1.hex
RAM2=../cli/niox_dram2.hex
RAM3=../cli/niox_dram3.hex
ROM=../cli/niox_irom.hex

D2M=/opt/Xilinx/14.4/ISE_DS/ISE/bin/lin/data2mem 

cpu_rom_Mram_mem1
cpu_rom_Mram_mem2
cpu_rom_Mram_mem3
cpu_rom_Mram_mem4
cpu_rom_Mram_mem5
cpu_rom_Mram_mem6
cpu_rom_Mram_mem7
cpu_rom_Mram_mem8

cpu_ram_Mram_mem01 [3:0]
cpu_ram_Mram_mem02 [7:4]
cpu_ram_Mram_mem11 [11:8]
cpu_ram_Mram_mem12 [15:12]
cpu_ram_Mram_mem21 [19:16]
cpu_ram_Mram_mem22 [23:20]
cpu_ram_Mram_mem31 [27:24]
cpu_ram_Mram_mem32 [31:28]

$D2M
