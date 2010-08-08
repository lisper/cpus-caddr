/* 2kx17 synchronous static ram */

`include "defines.vh"

module part_2kx17ram(clk_a, reset, address_a, q_a, data_a, wren_a, rden_a);

   input clk_a;
   input reset;
   input [10:0] address_a;
   input [16:0] data_a;
   input 	wren_a, rden_a;
   output [16:0] q_a;

`ifdef QUARTUS
   altsyncram ram
     (
      .address_a(address_a),
      .address_b(address_a),
      .clock0(clk_a),
      .data_a(data_a),
      .q_b(q_a),
      .rden_b(rden_a),
      .wren_a(wren_a)
      );

  defparam ram.address_reg_b = "CLOCK0",
           ram.maximum_depth = 0,
           ram.numwords_a = 2048,
           ram.numwords_b = 2048,
           ram.operation_mode = "DUAL_PORT",
           ram.outdata_reg_b = "UNREGISTERED",
           ram.ram_block_type = "AUTO",
           ram.rdcontrol_reg_b = "CLOCK0",
           ram.read_during_write_mode_mixed_ports = "OLD_DATA",
           ram.width_a = 17,
           ram.width_b = 17,
           ram.widthad_a = 11,
           ram.widthad_b = 11;
`endif // QUARTUS

`ifdef ISE_OR_SIMULATION
   reg [16:0] 	 ram [0:2047];
   reg [16:0] 	 out_a;

   assign q_a = out_a;

`ifdef debug
   integer 	 i, debug;

   initial
     begin
	debug = 0;
	for (i = 0; i < 2048; i=i+1)
          ram[i] = 17'b0;
     end
`endif

   always @(posedge clk_a)
     if (wren_a)
       ram[ address_a ] = data_a;

   always @(posedge clk_a)
     if (rden_a)
       out_a = ram[ address_a ];

//  always @(negedge wren_a)
//      ram[ address_a ] = data_a;
//
//   assign q_a = ram[ address_a ];
   
`endif // SIMULATION
   
endmodule

