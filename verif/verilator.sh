verilator -cc -exe --trace --Mdir ./tmp --top-module test run-verilator.v ../verilator/test.cpp ../verilator/ide.cpp && \
(cd tmp; make OPT="-O2" -f Vtest.mk)
