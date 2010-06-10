#

INCS = -I../../cver/gplcver-2.12a.src/pli_incs

CFLAGS= -fPIC -Wall -g $(INCS) -D__CVER__
LFLAGS= -G -shared -export-dynamic

all: pli_busint.so pli_busint.vpi

pli_busint.o: pli_busint.c 
	$(CC) $(CFLAGS) -c pli_busint.c

pli_busint.so: pli_busint.o
	$(LD) $(LFLAGS) pli_busint.o -o pli_busint.so

pli_busint.vpi: pli_busint.o
	$(LD) $(LFLAGS) pli_busint.o -o pli_busint.vpi

clean:
	rm -f *.o *.so *.vpi
