`ifndef SIMULATION
`define ISE
//`define SIMULATION
`endif

`ifdef ISE
 `define ISE_OR_SIMULATION
 `undef SIMULATION
`endif

`ifdef SIMULATION
 `ifdef ISE
  `undef ISE
 `endif
 `define ISE_OR_SIMULATION
`endif

`define x512Mb
`define FULL_MEM
`define sg5
`define x16
