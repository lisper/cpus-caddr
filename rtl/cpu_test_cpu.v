//
// ultra simple microcoded cpu for testing peripheral interfaces
// simple u-code is easier than writing complex state machines
//

module cpu_test_cpu_rom(clk, reset, addr, data);
   
   input clk;
   input reset;
   input [7:0] addr;
   output [47:0] data;
   reg [47:0] data;
   
   parameter [3:0] 
		OP_NOP = 0,
		OP_WRITE = 1,
		OP_READ = 2,
		OP_ADD = 3,
		OP_SUB = 4,
		OP_TST = 5,
		OP_CMP = 6,
		OP_JMP = 7,
		OP_DONE = 8,
		OP_WAIT = 9,
		OP_FAULT = 15;

   parameter [2:0] 
		R_NONE = 0,
		R_A = 1,
		R_B = 2,
		R_C = 3,
		R_D = 4,
		R_I = 5,
		R_DD = 7;

   parameter [5:0]
		N_NOP = 0;
   
   parameter [31:0]
		D_NONE = 0;
   
   always @(posedge clk)
     if (reset)
       data <= 0;
     else
       case (addr)
	 // fill
	 8'h00: data <= { OP_ADD,   R_A,    R_NONE, N_NOP, 32'h11000 };  // a = 0x11000
	 8'h01: data <= { OP_ADD,   R_B,    R_NONE, N_NOP, 32'h0 };  // b = 0 (count)
	 8'h02: data <= { OP_ADD,   R_D,    R_DD,   N_NOP, D_NONE }; // d<-data
	 8'h03: data <= { OP_WRITE, R_NONE, R_NONE, N_NOP, D_NONE }; // write m[a]<-d
	 8'h04: data <= { OP_ADD,   R_A,    R_A,    N_NOP, 32'h00000001 }; // a++
	 8'h05: data <= { OP_ADD,   R_B,    R_B,    N_NOP, 32'h00000001 }; // b++
	 8'h06: data <= { OP_CMP,   R_B,    R_I,    6'h08, 32'h00000100 };
	 8'h07: data <= { OP_JMP,   R_NONE, R_NONE, 6'h02, D_NONE }; // loop

	 // write block
	 8'h08: data <= { OP_NOP,   R_NONE, R_NONE, N_NOP, D_NONE };
	 8'h09: data <= { OP_ADD,   R_A,    R_NONE, N_NOP, 32'h00010001 };
	 8'h0a: data <= { OP_ADD,   R_D,    R_NONE, N_NOP, 32'h00011000 };
	 8'h0b: data <= { OP_WRITE, R_NONE, R_NONE, N_NOP, D_NONE };   // write mem

	 8'h0c: data <= { OP_ADD,   R_D,    R_NONE, N_NOP, 32'h0 };
 	 8'h0d: data <= { OP_ADD,   R_A,    R_NONE, N_NOP, 32'o17377776 };
	 8'h0e: data <= { OP_WRITE, R_NONE, R_NONE, N_NOP, D_NONE };   // write da

 	 8'h0f: data <= { OP_ADD,   R_A,    R_NONE, N_NOP, 32'o17377775 };
	 8'h10: data <= { OP_ADD,   R_D,    R_NONE, N_NOP, 32'h00010001 };
	 8'h11: data <= { OP_WRITE, R_NONE, R_NONE, N_NOP, D_NONE };   // write clp

 	 8'h12: data <= { OP_ADD,   R_A,    R_NONE, N_NOP, 32'o17377774 };
	 8'h13: data <= { OP_ADD,   R_D,    R_NONE, N_NOP, 32'o0011 };
	 8'h14: data <= { OP_WRITE, R_NONE, R_NONE, N_NOP, D_NONE };   // write cmd

 	 8'h15: data <= { OP_ADD,   R_A,    R_NONE, N_NOP, 32'o17377777 };
	 8'h16: data <= { OP_ADD,   R_D,    R_NONE, N_NOP, 32'h0 };
	 8'h17: data <= { OP_WRITE, R_NONE, R_NONE, N_NOP, D_NONE };   // write go

 	 8'h18: data <= { OP_WAIT,  R_NONE, R_NONE, N_NOP, D_NONE };
	 8'h19: data <= { OP_ADD,   R_A,    R_NONE, N_NOP, 32'o17377770 };
	 8'h1a: data <= { OP_READ,  R_NONE, R_NONE, N_NOP, D_NONE };
	 8'h1b: data <= { OP_TST,   R_D,    R_I,    6'h18, 32'h00000001 }; // wait

	 // loop
	 8'h1c: data <= { OP_ADD,   R_C,    R_C,    N_NOP, 32'h00000001 };  // c++
	 8'h1d: data <= { OP_CMP,   R_C,    R_I,    6'h21, 32'd100 };  // if (c == 100)
	 8'h1e: data <= { OP_ADD,   R_D,    R_C,    N_NOP, D_NONE };   // d = c
	 8'h1f: data <= { OP_JMP,   R_NONE, R_NONE, 6'h0d, D_NONE };   // loop back
	 8'h20: data <= { OP_ADD,   R_C,    R_I,    N_NOP, 32'h00000000 }; // c = 0

	 8'h21: data <= { OP_JMP,   R_NONE, R_NONE, 6'h2f, 32'h00000000 }; // skip
//	 8'h08: data <= { OP_JMP,   R_NONE, R_NONE, 6'h2f, 32'h00000000 }; // skip
	 
`ifdef never
	 // read block
	 8'h20: data <= { OP_ADD,   R_D,    R_NONE, N_NOP, 32'h0 };
 	 8'h21: data <= { OP_ADD,   R_A,    R_NONE, N_NOP, 32'o17377776 };
	 8'h22: data <= { OP_WRITE, R_NONE, R_NONE, N_NOP, D_NONE };

 	 8'h23: data <= { OP_ADD,   R_A,    R_NONE, N_NOP, 32'o17377775 };
	 8'h24: data <= { OP_ADD,   R_D,    R_NONE, N_NOP, 32'h00010001 };
	 8'h25: data <= { OP_WRITE, R_NONE, R_NONE, N_NOP, D_NONE };

 	 8'h26: data <= { OP_ADD,   R_A,    R_NONE, N_NOP, 32'o17377774 };
	 8'h27: data <= { OP_ADD,   R_D,    R_NONE, N_NOP, 32'h0 };
	 8'h28: data <= { OP_WRITE, R_NONE, R_NONE, N_NOP, D_NONE };

 	 8'h29: data <= { OP_ADD,   R_A,    R_NONE, N_NOP, 32'o17377777 };
	 8'h2a: data <= { OP_ADD,   R_D,    R_NONE, N_NOP, 32'h0 };
	 8'h2b: data <= { OP_WRITE, R_NONE, R_NONE, N_NOP, D_NONE };

 	 8'h2c: data <= { OP_ADD,   R_A,    R_NONE, N_NOP, 32'o17377770 };
	 8'h2d: data <= { OP_READ,  R_NONE, R_NONE, N_NOP, D_NONE };
	 8'h2e: data <= { OP_TST,   R_D,    R_I,    6'h2d, 32'h00000001 };
`endif

	 // compare
	 8'h2f: data <= { OP_ADD,   R_A,    R_NONE, N_NOP, 32'h11000 }; // a = 0x11000
	 8'h30: data <= { OP_ADD,   R_B,    R_NONE, N_NOP, 32'h0 };     // b = 0 (count)
	 8'h31: data <= { OP_READ,  R_NONE, R_NONE, N_NOP, D_NONE };    // read
	 8'h32: data <= { OP_CMP,   R_D,    R_DD,   6'h34, D_NONE };    // check
	 8'h33: data <= { OP_FAULT, R_NONE, R_NONE, N_NOP, D_NONE };
	 8'h34: data <= { OP_ADD,   R_A,    R_A,    N_NOP, 32'h00000001 }; // a++
	 8'h35: data <= { OP_ADD,   R_B,    R_B,    N_NOP, 32'h00000001 }; // b++
	 8'h36: data <= { OP_CMP,   R_B,    R_I,    6'h38, 32'h00000100 }; // if (b == )
	 8'h37: data <= { OP_JMP,   R_NONE, R_NONE, 6'h31, 32'h00000000 }; // loop
	 
`ifdef never
	 // loop
	 8'h38: data <= { OP_ADD,   R_C,    R_NONE, N_NOP, 32'h00000001 }; // c++
	 8'h39: data <= { OP_CMP,   R_C,    R_I,    6'h00, 32'd100 };  // if (c == 100)
	 8'h3a: data <= { OP_ADD,   R_D,    R_C,    N_NOP, D_NONE };   // d = c
	 8'h3b: data <= { OP_JMP,   R_NONE, R_NONE, 6'h21, D_NONE };   // loop reading
	 8'h3c: data <= { OP_ADD,   R_C,    R_I,    N_NOP, 32'h00000000 }; // c = 0
	 8'h3d: data <= { OP_DONE,  R_NONE, R_NONE, N_NOP, D_NONE };   // done
	 8'h3e: data <= { OP_JMP,   R_NONE, R_NONE, 6'h00, 32'h00000000 }; // restart
`else
	 8'h38: data <= { OP_DONE,  R_NONE, R_NONE, N_NOP, D_NONE }; 
`endif
	 
	 default: data <= { OP_JMP, R_NONE, R_NONE, 6'h00, D_NONE };
       endcase
endmodule

module cpu_test_cpu(clk, reset, start, done, fault, pc_out,
		    busint_memrq,
		    busint_memwr,
		    busint_memack,
		    busint_memdone,
		    busint_addr,
		    busint_busin,
		    busint_busout);

   input clk;
   input reset;
   input start;
   output done;
   output fault;
   output [7:0] pc_out;
   
   output busint_memrq;
   output  busint_memwr;
   input busint_memack;
   input busint_memdone;
   output [21:0] busint_addr;
   input [31:0]  busint_busin;
   output [31:0] busint_busout;

   reg 		busint_memrq;
   reg 		busint_memwr;

   //
   wire [47:0] 	ir;
   wire [7:0] 	npc;

   reg [7:0] 	pc;
   reg [21:0] 	addr;
   reg [31:0] 	b;
   reg [31:0] 	c;
   reg [31:0] 	data;
	
   wire 	load_pc;
   wire 	stall_pc;
   wire [3:0] 	ir_op;
   wire [3:0] 	ir_dreg;
   wire [3:0] 	ir_sreg;
   wire [7:0] 	ir_next;
   wire [31:0] 	ir_data;

   assign busint_addr = addr;
   assign busint_busout = data;

   assign npc =
	       load_pc ? ir_next :
	       pc + 1;
   
   always @(posedge clk)
     if (reset)
       pc <= 8'hff;
     else
       if (stall_pc)
	 pc <= pc;
       else
	 pc <= npc;

   assign pc_out = pc;
   
   wire [7:0] rom_pc;
   assign rom_pc = stall_pc ? pc : npc;
   
   cpu_test_cpu_rom rom(.clk(clk),
			.reset(reset),
			.addr(rom_pc),
			.data(ir));

   assign ir_op   = ir[47:44];
   assign ir_dreg  = ir[43:41];
   assign ir_sreg  = ir[40:38];
   assign ir_next = ir[37:32];
   assign ir_data = ir[31:0];

   parameter [3:0] 
		OP_NOP = 0,
		OP_WRITE = 1,
		OP_READ = 2,
		OP_ADD = 3,
		OP_SUB = 4,
		OP_TST = 5,
		OP_CMP = 6,
		OP_JMP = 7,
		OP_DONE = 8,
		OP_WAIT = 9,
		OP_FAULT = 15;

   parameter [2:0] 
		R_NONE = 0,
		R_A = 1,
		R_B = 2,
		R_C = 3,
		R_D = 4,
		R_I = 5,
		R_DD = 7;

   wire [31:0] 	   checker_out;
   
   cpu_test_disk cpu_test_disk(
			       .clk(clk),
			       .reset(reset),
			       .addr(addr[7:0]),
			       .data(checker_out)
			       );
   wire [31:0] 	   src;
   wire [31:0] 	   dst;

   assign src = ir_sreg == R_A ? addr :
		ir_sreg == R_B ? b :
		ir_sreg == R_C ? c :
		ir_sreg == R_D ? data :
		ir_sreg == R_I ? ir_data :
		ir_sreg == R_DD ? checker_out :
		0;

   assign dst = ir_dreg == R_A ? addr :
		ir_dreg == R_B ? b :
		ir_dreg == R_C ? c :
		ir_dreg == R_D ? data :
		0;

   always @(posedge clk)
     if (reset)
       begin
	  addr <= 0;
	  b <= 0;
	  c <= 0;
       end
     else
       begin
	  case (ir_op)
	    OP_ADD:
	      case (ir_dreg)
		R_A: addr <= src + ir_data;
		R_B: b    <= src + ir_data;
		R_C: c    <= src + ir_data;
	      endcase
	    
	    OP_SUB:
	      case (ir_dreg)
		R_A: addr <= src - ir_data;
		R_B: b    <= src - ir_data;
		R_C: c    <= src - ir_data;
	      endcase

	    default: ;
	  endcase
       end

`ifdef debug_activity
   always @(posedge clk)
     begin
	if (~stall_pc && ir_op == OP_WRITE && addr[3:0] == 0)
	  $display("dsk: write addr=0x%x %t", addr, $time);
	if (~stall_pc && ir_op == OP_READ && addr[3:0] == 0)
	  $display("dsk: read addr=0x%x %t", addr, $time);
     end
`endif
   
   always @(posedge clk)
     if (reset)
       data <= 0;
     else
       begin
	  if (busint_memdone)
	    data <= busint_busin;
	  else
	    if (ir_dreg == R_D)
	      begin
		 if (ir_op == OP_ADD)
		   data <= src + ir_data;
		 else
		   if (ir_op == OP_SUB)
		     data <= src - ir_data;
	      end
       end

   assign fault = ir_op == OP_FAULT;
   assign done = ir_op == OP_DONE;
   
   wire tst_result, cmp_result;
   
   assign tst_result = ~|(dst & src);

   assign cmp_result = dst == src;

`ifdef debug_tst
   always @(posedge clk)
     if (ir_op == OP_TST)
	   $display("TST: dst=%o, src=%o, tst_result=%b",
		    data, src, tst_result);
`endif

   reg [3:0] wait_count;
   wire	wait_done;

   always @(posedge clk)
     if (reset)
       wait_count <= 0;
     else
       if (ir_op == OP_WAIT)
	 wait_count <= wait_count + 1;
       else
	 wait_count <= 0;
   
   assign wait_done = wait_done == 4'f;
   
   assign stall_pc =
		    ~start ||
		    (ir_op == OP_WAIT && ~wait_done) ||
		    (ir_op == OP_WRITE && ~busint_memack) ||
		    (ir_op == OP_READ && ~busint_memdone);

   assign load_pc =
		   ((ir_op == OP_TST) && tst_result) ||
		   ((ir_op == OP_CMP) && cmp_result) ||
		   (ir_op == OP_JMP);
   
   always @(posedge clk)
     if (reset)
       begin
	  busint_memrq <= 0;
	  busint_memwr <= 0;
       end
     else
       begin
	  busint_memrq <= ir_op == OP_WRITE || ir_op == OP_READ;
	  busint_memwr <= ir_op == OP_WRITE;
       end

`ifdef debug_op
   always @(posedge clk)
     if (~stall_pc)
     case (ir_op)
       OP_NOP: $display("%x: NOP ir=%x", pc, ir);
       OP_WRITE: $display("%x: WRITE ir=%x, addr=%x (0%o)", pc, ir, addr, addr);
       OP_READ:  $display("%x: READ  ir=%x", pc, ir);
       OP_ADD:   $display("%x: ADD   ir=%x", pc, ir);
       OP_SUB:   $display("%x: SUB   ir=%x", pc, ir);
       OP_TST:   $display("%x: TST   ir=%x, load_pc=%b", pc, ir, load_pc);
       OP_CMP:   $display("%x: CMP   ir=%x, load_pc=%b", pc, ir, load_pc);
       OP_JMP:   $display("%x: JMP   ir=%x, load_pc=%b", pc, ir, load_pc);
       OP_DONE:  $display("%x: DONE  ir=%x", pc, ir);
       OP_WAIT:  $display("%x: WAIT  ir=%x", pc, ir);
       OP_FAULT: $display("%x: FAULT", pc);
     endcase
`endif
   
endmodule
