/* 21kx32 sram */

`include "defines.vh"

module part_21kx32dpram(reset,
			clk_a, address_a, q_a, data_a, wren_a, rden_a,
			clk_b, address_b, q_b, data_b, wren_b, rden_b);
   
   input reset;

   input        clk_a;
   input [14:0] address_a;
   input [31:0] data_a;
   input 	wren_a, rden_a;
   output [31:0] q_a;

   input 	 clk_b;
   input [14:0]  address_b;
   input [31:0]  data_b;
   input 	 wren_b, rden_b;
   output [31:0] q_b;

   parameter IRAM_SIZE = 21504;
   
`ifdef QUARTUS
   altsyncram ram
     (
      .clock0(clk_a),
      .clock1(clk_b),

      .address_a(address_a),
      .data_a(data_a),
      .q_a(q_a),
      .rden_a(rden_a),
      .wren_a(wren_a)

      .address_b(address_b),
      .data_b(data_b),
      .q_b(q_b),
      .rden_b(rden_b),
      .wren_b(wren_b)
      );

  defparam ram.address_reg_b = "CLOCK0",
           ram.maximum_depth = 0,
           ram.numwords_a = 21504,
           ram.numwords_b = 21504,
           ram.operation_mode = "DUAL_PORT",
           ram.outdata_reg_b = "UNREGISTERED",
           ram.ram_block_type = "AUTO",
           ram.rdcontrol_reg_b = "CLOCK0",
           ram.read_during_write_mode_mixed_ports = "OLD_DATA",
           ram.width_a = 32,
           ram.width_b = 32,
           ram.widthad_a = 15,
           ram.widthad_b = 15;
`endif // QUARTUS

`ifdef ISE
 `define ISE_MODEL
`endif

`ifdef XILINX_ISIM
 `define ISE_MODEL
`endif
   
`ifdef ISE_MODEL
   wire ena_a = rden_a | wren_a;
   wire ena_b = rden_b | wren_b;
   
   ise_21kx32_dpram inst
     (
      .clka(clk_a),
      .ena(ena_a),
      .wea(wren_a),
      .addra(address_a),
      .dina(data_a),
      .douta(q_a),
      .clkb(clk_b),
      .enb(ena_b),
      .web(wren_b),
      .addrb(address_b),
      .dinb(data_b),
      .doutb(q_b)
      );
`endif

`ifdef SIMULATION_XXX
   reg [31:0] 	 ram [0:IRAM_SIZE-1];

   reg [31:0] 	 q_a;
   reg [31:0] 	 q_b;

   integer i;
   initial
     begin
//	for (i = 0; i < IRAM_SIZE-1; i = i + 1)
//	  ram[i] = 0;
     end
	   
   always @(posedge clk_a)
     if (reset)
       q_a <= 0;
     else
       begin
 `ifdef debug_rw
	  $display("part_21kx32dpram: read @ %x", address_a);
 `endif
	  q_a <= ram[ address_a ];
	  if (wren_a)
	    begin
	       q_a <= data_a;
	       ram[ address_a ] <= data_a;
	    end
       end
   
   always @(posedge clk_b)
     if (reset)
       q_b <= 0;
     else
       begin
 `ifdef debug_rw
	  $display("part_21kx32dpram: read @ %x", address_b);
 `endif
	  q_b <= ram[ address_b ];
	  if (wren_b)
	    begin
	       q_b <= data_b;
	       ram[ address_b ] <= data_b;
	    end
       end

`endif // SIMULATION
   
endmodule

`ifdef SIMULATION
`ifdef ISE_MODEL
 `include "../ise-lx45/ipcore_dir/ise_21kx32_dpram.v"
`endif
`endif