/* 16k49 sram */

`include "defines.vh"

module part_16kx49ram(clk_a, reset, address_a, q_a, data_a, wren_a, rden_a);

   input clk_a;
   input reset;
   input [13:0] address_a;
   input [48:0] data_a;
   input 	wren_a, rden_a;
   output [48:0] q_a;

   parameter IRAM_SIZE = 16384;

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
           ram.numwords_a = 16384,
           ram.numwords_b = 16384,
           ram.operation_mode = "DUAL_PORT",
           ram.outdata_reg_b = "UNREGISTERED",
           ram.ram_block_type = "AUTO",
           ram.rdcontrol_reg_b = "CLOCK0",
           ram.read_during_write_mode_mixed_ports = "OLD_DATA",
           ram.width_a = 49,
           ram.width_b = 49,
           ram.widthad_a = 14,
           ram.widthad_b = 14;
`endif // QUARTUS

`ifdef ISE
   wire ena_a = rden_a | wren_a;
   
   ise_16kx49ram inst
     (
      .clka(clk_a),
      .ena(ena_a),
      .wea(wren_a),
      .addra(address_a),
      .dina(data_a),
      .douta(q_a)
      );
`endif

`ifdef SIMULATION
   reg [48:0] 	 ram [0:IRAM_SIZE-1];
   reg [48:0] 	 out_a;

   assign q_a = out_a;

`ifdef debug
   integer 	 i, debug;

   initial
     begin
	debug = 0;
	for (i = 0; i < IRAM_SIZE; i=i+1)
          ram[i] = 49'b0;
     end
`endif

   /* synthesis syn_ramstyle="block_ram" */
   always @(posedge clk_a)
     if (wren_a)
       begin
	  ram[ address_a ] <= data_a;
`ifdef debug
	  if (debug != 0)
	    $display("iram: W %o <- %o; %t", address_a, data_a, $time);
`endif
       end

   always @(posedge clk_a)
     if (rden_a)
       begin
	  // patch out disk-copy (which takes hours to sim)
`ifdef debug_patch_disk_copy
	  out_a <= address_a == 14'o24045 ? 49'h000000001000 : ram[ address_a ];
`else
	  out_a <= ram[ address_a ];
`endif
`ifdef debug
	  if (debug > 1)
	    $display("iram: R %o -> %o; %t",
		     address_a, ram[ address_a ], $time);
`endif
       end
   
`endif // SIMULATION
   
endmodule

