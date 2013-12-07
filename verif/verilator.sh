V=/usr/local/src/verilator-3.854/bin/verilator
#V=verilator

#$V -cc -LDFLAGS "-lSDL -lpthread" -exe --Mdir ./tmp --top-module test run-verilator.v ../verilator/test.cpp ../verilator/ide.cpp ../verilator/vga.cpp && \
#(cd tmp; make OPT="-O2" -f Vtest.mk)

$V -cc -LDFLAGS "-lSDL -lpthread" -exe --trace --Mdir ./tmp --top-module test run-verilator.v ../verilator/test.cpp ../verilator/ide.cpp ../verilator/mmc.cpp ../verilator/vga.cpp ../verilator/block_dev.cpp && \
(cd tmp; make OPT="-O2" -f Vtest.mk)

#$V -cc -exe --trace --Mdir ./tmp --top-module test $F ../verilator/test.cpp ../verilator/ide.cpp && \
#(cd tmp; make OPT="-O2" -f Vtest.mk)
