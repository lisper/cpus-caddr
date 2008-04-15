#
#
#

IVERILOG=iverilog
VERILOG=cver

all: igo

PARTS = 74181.v 74182.v memory.v rom.v rompatch.v

parts.o: $(PARTS)
	$(VERILOG) -o parts.o $(PARTS)

irun: $(PARTS) run.v caddr.v
	$(IVERILOG) -o run run.v

crun: $(PARTS) run.v caddr.v
	$(VERILOG) +change_port_type run.v
	echo "exit 0" > run
	chmod +x run

go: crun
	./run
igo: irun
	./run

display:
	./maketraces.sh >traces
	gtkwave caddr.vcd traces

snapshot:
	(suffix=`date +%y%m%d`; tar cfz caddr_verilog_$$suffix.tar.gz *.v Makefile)
	mv cadfr_verilog* ~/html/unlambda/html/download/cadr
