/*
 * $Id$
 */

//`define QUARTUS
//`define ISE
`define SIMULATION

`ifdef ISE
 `define ISE_OR_SIMULATION
`endif

`ifdef SIMULATION
 `define ISE_OR_SIMULATION
`endif

module part_1kx32ram_a(clk_a, reset, address_a, q_a, data_a, wren_a, rden_a);

   input clk_a;
   input reset;
   input [9:0] address_a;
   input [31:0] data_a;
   input 	wren_a, rden_a;
   output [31:0] q_a;

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
           ram.width_a = 32,
           ram.width_b = 32,
           ram.widthad_a = 10,
           ram.widthad_b = 10;
`endif //  `ifdef QUARTUS

`ifdef ISE
   // synopsys translate_off

   BLK_MEM_GEN_V1_1 #(
		10,	// c_addra_width
		10,	// c_addrb_width
		1,	// c_algorithm
		9,	// c_byte_size
		1,	// c_common_clk
		"0",	// c_default_data
		1,	// c_disable_warn_bhv_coll
		1,	// c_disable_warn_bhv_range
		"spartan3",	// c_family
		1,	// c_has_ena
		1,	// c_has_enb
		0,	// c_has_mem_output_regs
		0,	// c_has_mux_output_regs
		0,	// c_has_regcea
		0,	// c_has_regceb
		0,	// c_has_ssra
		0,	// c_has_ssrb
		"no_coe_file_loaded",	// c_init_file_name
		0,	// c_load_init_file
		1,	// c_mem_type
		1,	// c_prim_type
		1024,	// c_read_depth_a
		1024,	// c_read_depth_b
		32,	// c_read_width_a
		32,	// c_read_width_b
		"NONE",	// c_sim_collision_check
		"0",	// c_sinita_val
		"0",	// c_sinitb_val
		0,	// c_use_byte_wea
		0,	// c_use_byte_web
		0,	// c_use_default_data
		1,	// c_wea_width
		1,	// c_web_width
		1024,	// c_write_depth_a
		1024,	// c_write_depth_b
		"WRITE_FIRST",	// c_write_mode_a
		"WRITE_FIRST",	// c_write_mode_b
		32,	// c_write_width_a
		32)	// c_write_width_b
	inst (
		.CLKA(clk_a),
		.DINA(data_a),
		.ADDRA(address_a),
		.ENA(1'b0),
		.WEA(wren_a),
		.CLKB(clk_a),
		.ADDRB(address_a),
		.ENB(rden_a),
		.DOUTB(q_a),
		.REGCEA(),
		.SSRA(),
		.DOUTA(),
		.DINB(),
		.REGCEB(),
		.WEB(),
		.SSRB());
   // synopsys translate_on
`endif //  ISE

`ifdef SIMULATION
   reg [31:0] ram [0:1023];
   reg [31:0] out_a;

   assign q_a = out_a;
   
`ifdef debug
  integer i, debug;

  initial
    begin
       debug = 0;
       for (i = 0; i < 1024; i=i+1)
         ram[i] = 32'b0;
    end
`endif

   always @(posedge clk_a)
     if (wren_a)
       begin
          ram[ address_a ] = data_a;
`ifdef debug
	  if (address_a != 0 && debug != 0)
	    $display("amem: W addr %o val %o; %t", address_a, data_a, $time);
`endif
       end

   always @(posedge clk_a)
     if (rden_a)
       begin
	  out_a = ram[ address_a ];
`ifdef debug
	  if (address_a != 0 && debug != 0)
	    $display("amem: R addr %o val %o; %t",
		     address_a, ram[ address_a ], $time);
`endif
       end
`endif // SIMULATION
   
endmodule

module part_1kx32ram_p(clk_a, reset, address_a, q_a, data_a, wren_a, rden_a);

   input clk_a;
   input reset;
   input [9:0] address_a;
   input [31:0] data_a;
   input 	wren_a, rden_a;
   output [31:0] q_a;

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
           ram.width_a = 32,
           ram.width_b = 32,
           ram.widthad_a = 10,
           ram.widthad_b = 10;
`endif // QUARTUS

`ifdef ISE_OR_SIMULATION
   reg [31:0] ram [0:1023];
   reg [31:0] out_a;

   assign q_a = out_a;

`ifdef debug
  integer i, debug;

  initial
    begin
       debug = 0;
       for (i = 0; i < 1024; i=i+1)
         ram[i] = 32'b0;
    end
`endif

   always @(posedge clk_a)
     if (wren_a)
       begin
          ram[ address_a ] = data_a;
`ifdef debug
	  if (debug != 0)
	    $display("pdl: W addr %o val %o; %t", address_a, data_a, $time);
`endif
       end

   always @(posedge clk_a)
     if (rden_a)
       begin
	  out_a = ram[ address_a ];
`ifdef debug
	  if (address_a != 0 && debug != 0)
	    $display("amem: R addr %o val %o; %t",
		     address_a, ram[ address_a ], $time);
`endif
       end
`endif // SIMULATION
   
endmodule

/* 2kx17 static ram */

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

/* 32x32 synchronous static ram */

module part_32x32ram(clk_a, reset, address_a, q_a, data_a, wren_a, rden_a);

   input clk_a;
   input reset;
   input [4:0] address_a;
   input [31:0] data_a;
   input 	wren_a, rden_a;
   output [31:0] q_a;

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
           ram.numwords_a = 32,
           ram.numwords_b = 32,
           ram.operation_mode = "DUAL_PORT",
           ram.outdata_reg_b = "UNREGISTERED",
           ram.ram_block_type = "AUTO",
           ram.rdcontrol_reg_b = "CLOCK0",
           ram.read_during_write_mode_mixed_ports = "OLD_DATA",
           ram.width_a = 32,
           ram.width_b = 32,
           ram.widthad_a = 5,
           ram.widthad_b = 5;
`endif // QUARTUS

`ifdef ISE_OR_SIMULATION
   reg [31:0] 	 ram [0:31];
   reg [31:0] 	 out_a;

   assign q_a = out_a;
   
`ifdef debug
   integer 	 i, debug;

   initial
     begin
	debug = 0;
	for (i = 0; i < 32; i=i+1)
          ram[i] = 32'b0;
     end
`endif

   always @(posedge clk_a)
     if (wren_a)
       ram[ address_a ] = data_a;

   always @(posedge clk_a)
     if (rden_a)
       out_a = ram[ address_a ];

`endif // SIMULATION

endmodule

/* 32x19 synchronous static ram */

module part_32x19ram(clk_a, reset, address_a, q_a, data_a, wren_a, rden_a);

   input clk_a;
   input reset;
   input [4:0] address_a;
   input [18:0] data_a;
   input 	wren_a, rden_a;
   output [18:0] q_a;

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
           ram.numwords_a = 32,
           ram.numwords_b = 32,
           ram.operation_mode = "DUAL_PORT",
           ram.outdata_reg_b = "UNREGISTERED",
           ram.ram_block_type = "AUTO",
           ram.rdcontrol_reg_b = "CLOCK0",
           ram.read_during_write_mode_mixed_ports = "OLD_DATA",
           ram.width_a = 19,
           ram.width_b = 19,
           ram.widthad_a = 5,
           ram.widthad_b = 5;
`endif // QUARTUS

`ifdef ISE
   // synopsys translate_off

   BLK_MEM_GEN_V1_1 #(
		5,	// c_addra_width
		5,	// c_addrb_width
		1,	// c_algorithm
		9,	// c_byte_size
		1,	// c_common_clk
		"0",	// c_default_data
		1,	// c_disable_warn_bhv_coll
		1,	// c_disable_warn_bhv_range
		"spartan3",	// c_family
		1,	// c_has_ena
		1,	// c_has_enb
		0,	// c_has_mem_output_regs
		0,	// c_has_mux_output_regs
		0,	// c_has_regcea
		0,	// c_has_regceb
		0,	// c_has_ssra
		0,	// c_has_ssrb
		"no_coe_file_loaded",	// c_init_file_name
		0,	// c_load_init_file
		1,	// c_mem_type
		1,	// c_prim_type
		32,	// c_read_depth_a
		32,	// c_read_depth_b
		19,	// c_read_width_a
		19,	// c_read_width_b
		"NONE",	// c_sim_collision_check
		"0",	// c_sinita_val
		"0",	// c_sinitb_val
		0,	// c_use_byte_wea
		0,	// c_use_byte_web
		0,	// c_use_default_data
		1,	// c_wea_width
		1,	// c_web_width
		32,	// c_write_depth_a
		32,	// c_write_depth_b
		"WRITE_FIRST",	// c_write_mode_a
		"WRITE_FIRST",	// c_write_mode_b
		19,	// c_write_width_a
		19)	// c_write_width_b
	inst (
		.CLKA(clk_a),
		.DINA(data_a),
		.ADDRA(address_a),
		.ENA(1'b0),
		.WEA(wren_a),
		.CLKB(clk_a),
		.ADDRB(address_a),
		.ENB(rden_a),
		.DOUTB(q_a),
		.REGCEA(),
		.SSRA(),
		.DOUTA(),
		.DINB(),
		.REGCEB(),
		.WEB(),
		.SSRB());
   // synopsys translate_on
`endif //  ISE

`ifdef SIMULATION
   reg [18:0] 	 ram [0:31];
   reg [18:0] 	 out_a;

   assign q_a = out_a;
   
`ifdef debug
   integer 	 i, debug;

   initial
     begin
	debug = 0;
	for (i = 0; i < 32; i=i+1)
          ram[i] = 19'b0;
     end
`endif

   always @(posedge clk_a)
     if (wren_a)
       begin
	  ram[ address_a ] = data_a;
`ifdef debug
	  if (address_a != 0 && debug != 0)
	    $display("spc: W addr %o val %o; %t", address_a, data_a, $time);
`endif
       end

   always @(posedge clk_a)
     if (rden_a)
       out_a = ram[ address_a ];

`endif // SIMULATION
   
endmodule

module part_2kx5ram(clk_a, reset, address_a, q_a, data_a, wren_a, rden_a);

   input clk_a;
   input reset;
   input [10:0] address_a;
   input [4:0] 	data_a;
   input 	wren_a, rden_a;
   output [4:0] q_a;

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
           ram.width_a = 5,
           ram.width_b = 5,
           ram.widthad_a = 11,
           ram.widthad_b = 11;
`endif // QUARTUS

`ifdef ISE_OR_SIMULATION
   reg [4:0] 	ram [0:2047];
   reg [4:0] 	out_a;

//   assign q_a = out_a;

`ifdef debug
   integer 	 i, debug;

   initial
     begin
	debug = 0;
	for (i = 0; i < 2048; i=i+1)
          ram[i] = 5'b0;
     end
`endif

   always @(posedge wren_a/*clk_a*/)
     if (wren_a)
       begin
	  ram[ address_a ] = data_a;
`ifdef debug
	  if (debug != 0)
	    $display("vmem0: W addr %o <- val %o; %t",
		     address_a, data_a, $time);
`endif
       end

//   always @(posedge clk_a)
//     if (rden_a)
//       out_a = ram[ address_a ];
assign q_a = ram[ address_a ];

`endif // SIMULATION

endmodule

module part_1kx24ram(clk_a, reset, address_a, q_a, data_a, wren_a, rden_a);

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

//   assign q_a = out_a;

`ifdef debug
   integer 	 i, debug;

   initial
     begin
	debug = 0;
	for (i = 0; i < 1024; i=i+1)
          ram[i] = 24'b0;
     end
`endif

   always @(posedge wren_a/*clk_a*/)
     if (wren_a)
       begin
	  ram[ address_a ] = data_a;
`ifdef debug
	  if (debug != 0)
	    $display("vmem1: W addr %o <- val %o; %t",
		     address_a, data_a, $time);
`endif
       end

//   always @(posedge clk_a)
//     if (rden_a)
//       begin
//	  out_a = ram[ address_a ];
//`ifdef debug
//	  if (debug != 0)
//	    $display("vmem1: R addr %o -> val %o; %t",
//		     address_a, ram[ address_a ], $time);
//`endif
//       end
assign q_a = ram[ address_a ];
   
`endif // SIMULATION

endmodule

module part_16kx49ram(clk_a, reset, address_a, q_a, data_a, wren_a, rden_a);

   input clk_a;
   input reset;
   input [13:0] address_a;
   input [48:0] data_a;
   input 	wren_a, rden_a;
   output [48:0] q_a;

`ifdef debug
   parameter IRAM_SIZE = 16384;
`else
   parameter IRAM_SIZE = 4;
`endif
   
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

`ifdef ISE_OR_SIMULATION
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

   always @(posedge clk_a)
     if (wren_a)
       begin
	  ram[ address_a ] = data_a;
`ifdef debug
	  if (debug != 0)
	    $display("iram: W addr %o val %o; %t", address_a, data_a, $time);
`endif
       end

   always @(posedge clk_a)
     if (rden_a)
       begin
	  out_a = ram[ address_a ];
`ifdef debug
	  if (debug != 0)
	    $display("iram: R addr %o val %o; %t",
		     address_a, ram[ address_a ], $time);
`endif
       end
   
`endif // SIMULATION
   
endmodule

