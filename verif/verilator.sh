verilator -cc -LDFLAGS "-lSDL -lpthread" -exe --trace --Mdir ./tmp --top-module test run-verilator.v ../verilator/test.cpp ../verilator/ide.cpp ../verilator/vga.cpp && \
(cd tmp; make OPT="-O2" -f Vtest.mk)

#verilator -cc -exe --trace --Mdir ./tmp --top-module test $F ../verilator/test.cpp ../verilator/ide.cpp && \
#(cd tmp; make OPT="-O2" -f Vtest.mk)
