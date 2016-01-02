#CC = /opt/tools/6809/bin/m6809-unknown-none-gcc
CROSS= /opt/altera/13.1/nios2eds/bin/gnu/H-i686-pc-linux-gnu/bin/nios2-elf-
CC = $(CROSS)gcc
LD = $(CROSS)ld
OBJDUMP = $(CROSS)objdump
OBJCOPY = $(CROSS)objcopy

SRC = main.c cli.c readline.c printf.c strings.c serial.c tv.c util.c support.c
OBJ = $(SRC:.c=.o)

CFLAGS = -O1
#CFLAGS = -O2

all: diag.elf diag.bin \
	niox_dram3.hex niox_dram2.hex niox_dram1.hex niox_dram0.hex niox_irom.hex

diag.elf: $(OBJ) start.o
	$(LD) -o $@ -T diag.ldscript start.o $(OBJ)
#	$(LD) -o $@ -Ttext=0 start.o $(OBJ)
	$(OBJDUMP) -d diag.elf >diag.objdump

diag.bin: diag.elf
	$(OBJCOPY) -S -g -O binary diag.elf $@

start.o: start.S
	$(CC) -c start.S

#
niox_irom.bin: diag.elf
	$(OBJCOPY) -S -g -O binary --only-section=.text diag.elf $@
niox_irom.hex: niox_irom.bin
	hexdump -v -e '"%08x" "\n"' niox_irom.bin >$@

SECTIONS = --only-section=.rodata --only-section=.rwdata --change-addresses -0x10000

niox_dram3.hex: diag.elf
	$(OBJCOPY) -S -g -O verilog $(SECTIONS) --interleave=4 --byte=3 diag.elf $@
niox_dram2.hex: diag.elf
	$(OBJCOPY) -S -g -O verilog $(SECTIONS) --interleave=4 --byte=2 diag.elf $@
niox_dram1.hex: diag.elf
	$(OBJCOPY) -S -g -O verilog $(SECTIONS) --interleave=4 --byte=1 diag.elf $@
niox_dram0.hex: diag.elf
	$(OBJCOPY) -S -g -O verilog $(SECTIONS) --interleave=4 --byte=0 diag.elf $@


clean:
	rm -f *.o *.elf *.bin *.hex
	rm -f diag diag.elf diag.bin diag.objdump



