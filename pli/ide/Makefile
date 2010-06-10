#

INCS = -I../../cver/gplcver-2.12a.src/pli_incs

CFLAGS= -fPIC -Wall -g $(INCS) -D__CVER__
LFLAGS= -G -shared -export-dynamic

all: pli_ide.so pli_ide.vpi

pli_ide.o: pli_ide.c 
	$(CC) $(CFLAGS) -c pli_ide.c

pli_ide.so: pli_ide.o
	$(LD) $(LFLAGS) pli_ide.o -o pli_ide.so

pli_ide.vpi: pli_ide.o
	$(LD) $(LFLAGS) pli_ide.o -o pli_ide.vpi

clean:
	rm -f *.o *.so *.vpi
