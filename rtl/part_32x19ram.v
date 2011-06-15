/* 32x19 synchronous dual port ram */

`include "defines.vh"

module part_32x19dpram(reset,
		       clk_a, address_a, q_a, data_a, wren_a, rden_a,
   		       clk_b, address_b, q_b, data_b, wren_b, rden_b);

   input reset;
   input clk_a, clk_b;
   input [4:0] address_a;
   input [4:0] address_b;
   input [18:0] data_a;
   input [18:0] data_b;
   input 	wren_a, rden_a;
   input 	wren_b, rden_b;

   output [18:0] q_a;
   output [18:0] q_b;

`ifdef QUARTUS
   altsyncram ram
     (
      .address_a(address_a),
      .address_b(address_b),
      .clock0(clk_a),
      .data_a(data_a),
      .data_b(data_b),
      .q_a(q_a),
      .q_b(q_b),
      .rden_a(rden_a),
      .rden_b(rden_b),
      .wren_a(wren_a)
      .wren_b(wren_b)
      );

  defparam ram.address_reg_b = "CLOCK0",
           ram.maximum_depth = 0,
           ram.numwords_a = 32,
           ram.numwords_b = 32,
           ram.operation_mode = "DUAL_PORT",
           ram.outdata_reg_b = "UNREGISTERED",
           ram.ram_block_type = "AUTO",
           ram.rdcontrol_reg_b = "CLOCK0",
           ram.read_during_write_mode_mixed_ports = "NEW_DATA",
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
		.DOUTA(q_a),
		.ADDRA(address_a),
		.ENA(rden_a),
		.WEA(wren_a),

		.CLKB(clk_b),
		.DINB(data_b),
		.DOUTB(q_b),
		.ADDRB(address_a),
		.ENB(rden_b),
		.WEB(wren_a),

		.REGCEA(),
		.SSRA(),
		.REGCEB(),
		.SSRB());
   // synopsys translate_on
`endif //  ISE

//`ifdef SIMULATION
`ifdef ISE_OR_SIMULATION
   reg [18:0] 	 ram [0:31];
   reg [18:0] 	 out_a;
   reg [18:0] 	 out_b;

   assign q_a = out_a;
   assign q_b = out_b;
   
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
	  ram[ address_a ] <= data_a;
`ifdef debug
	  if (debug != 0)
	    $display("spc:  W %o <- %o; %t", address_a, data_a, $time);
`endif
       end
     else if (wren_b)
       begin
	  ram[ address_b ] <= data_b;
`ifdef debug
	  if (debug != 0)
	    $display("spc:  W %o <- %o; %t", address_b, data_b, $time);

`endif
`ifdef use_iologger
	  test.iologger(32'd10, {17'b0, address_b}, {13'b0, data_b});
`endif
       end

   always @(posedge clk_a)
     if (reset)
       out_a <= 0;
     else if (rden_a)
       begin
	  /* WE NEED 'READ NEW DATA' ON SIMULTANEOUS WRITE/READ TO SAME ADDR */
	  if (wren_b && address_b == address_a)
	    begin
	       out_a <= data_b;
`ifdef debug
	       if (address_a != 0 && debug != 0)
		 $display("spc:  R %o -> %o; (collision) %t", address_a, data_b, $time);
`endif
`ifdef use_iologger
	       test.iologger(32'd11, {17'b0, address_a}, {13'b0, data_b});
`endif
	    end
	  else
	    begin
	       out_a <= ram[ address_a ];
`ifdef debug
	       if (address_a != 0 && debug != 0)
		 $display("spc:  R %o -> %o; %t", address_a, ram[address_a], $time);
`endif
`ifdef use_iologger
	       test.iologger(32'd11, {17'b0, address_a}, {13'b0, ram[address_a]});
`endif
	    end
       end

   always @(posedge clk_b)
     if (reset)
       out_b <= 0;
     else if (rden_b)
       begin
	  out_b <= ram[ address_b ];
`ifdef debug
	  if (address_b != 0 && debug != 0)
	    $display("spc:  R %o -> %o; %t", address_b, ram[address_b], $time);
`endif
       end

`endif // SIMULATION
   
endmodule

