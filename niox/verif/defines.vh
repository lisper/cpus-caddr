//
`ifdef XILINX_ISIM
 `undef SIMULATION
 `define SIMULATION 1
`endif

`ifdef __CVER__
 `undef SIMULATION
 `define SIMULATION 1
`endif


`ifdef ISE
 `undef SIMULATION
 `undef XILINX_ISIM
`endif

