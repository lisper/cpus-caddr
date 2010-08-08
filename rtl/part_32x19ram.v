/* 32x19 synchronous static ram */

`include "defines.vh"

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

//`ifdef SIMULATION
`ifdef ISE_OR_SIMULATION
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

