#

INCS = -I../../cver/gplcver-2.12a.src/pli_incs

CFLAGS= -fPIC -Wall -g $(INCS) -D__CVER__
LFLAGS= -G -shared -export-dynamic -lSDL -lpthread

all: display.so display.vpi

display.o: display.c 
	$(CC) $(CFLAGS) -c display.c

display.so: display.o Makefile
	$(LD) $(LFLAGS) display.o -o display.so

display.vpi: display.o Makefile
	$(LD) $(LFLAGS) display.o -o display.vpi

clean:
	rm -f *.o *.so *.vpi
