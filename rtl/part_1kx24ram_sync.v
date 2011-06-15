/* 1kx24 synchronous static ram */

`include "defines.vh"

module part_1kx24ram_sync(clk_a, reset, address_a, q_a, data_a, wren_a, rden_a);

   input clk_a;
   input reset;
   input [9:0]   address_a;
   input [23:0]  data_a;
   input 	 wren_a, rden_a;
   output [23:0] q_a;

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
           ram.numwords_a = 1024,
           ram.numwords_b = 1024,
           ram.operation_mode = "DUAL_PORT",
           ram.outdata_reg_b = "UNREGISTERED",
           ram.ram_block_type = "AUTO",
           ram.rdcontrol_reg_b = "CLOCK0",
           ram.read_during_write_mode_mixed_ports = "OLD_DATA",
           ram.width_a = 24,
           ram.width_b = 24,
           ram.widthad_a = 10,
           ram.widthad_b = 10;
`endif // QUARTUS

`ifdef ISE_OR_SIMULATION
   reg [23:0] 	 ram [0:1023];
   reg [23:0] 	 out_a;

   assign q_a = out_a;

`ifdef debug
   integer 	 i, debug;

   initial
     begin
	debug = 0;
	for (i = 0; i < 1024; i=i+1)
          ram[i] = 24'b0;
     end
`endif

   always @(posedge clk_a)
     if (wren_a)
       begin
	  ram[ address_a ] <= data_a;
`ifdef debug
	  if (debug != 0)
	    $display("vmem1: W addr %o <- val %o; %t",
		     address_a, data_a, $time);
`endif
       end

   always @(posedge clk_a)
     if (rden_a)
       begin
	  out_a <= ram[ address_a ];
`ifdef debug
	  if (debug != 0)
	    $display("vmem1: R addr %o -> val %o; %t",
		     address_a, ram[ address_a ], $time);
`endif
       end

`endif // SIMULATION

endmodule
