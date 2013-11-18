
ASM=../asm/asm

src = $(shell echo *.m)
obj = $(src:.m=.o)

all: $(obj)

$(obj): %.o: %.m
	$(ASM) <$< -o $@ -l $*.l

clean:
	rm -f *.o *.l
