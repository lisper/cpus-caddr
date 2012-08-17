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
		R_DA = 6,
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
	 8'h09: data <= { OP_ADD,   R_A,    R_NONE, N_NOP, 32'h00010100 };
	 8'h0a: data <= { OP_ADD,   R_D,    R_NONE, N_NOP, 32'h00011000 };
	 8'h0b: data <= { OP_WRITE, R_NONE, R_NONE, N_NOP, D_NONE };   // write mem

	 8'h0c: data <= { OP_ADD,   R_D,    R_DA,   N_NOP, 32'h0 };	// d = da
 	 8'h0d: data <= { OP_ADD,   R_A,    R_NONE, N_NOP, 32'o17377776 };
	 8'h0e: data <= { OP_WRITE, R_NONE, R_NONE, N_NOP, 32'h0001 };   // write da

 	 8'h0f: data <= { OP_ADD,   R_A,    R_NONE, N_NOP, 32'o17377775 };
	 8'h10: data <= { OP_ADD,   R_D,    R_NONE, N_NOP, 32'h00010100 };
	 8'h11: data <= { OP_WRITE, R_NONE, R_NONE, N_NOP, D_NONE };   // write clp

 	 8'h12: data <= { OP_ADD,   R_A,    R_NONE, N_NOP, 32'o17377774 };
	 8'h13: data <= { OP_ADD,   R_D,    R_NONE, N_NOP, 32'o0011 }; // write
	 8'h14: data <= { OP_WRITE, R_NONE, R_NONE, N_NOP, D_NONE };   // write cmd

 	 8'h15: data <= { OP_ADD,   R_A,    R_NONE, N_NOP, 32'o17377777 };
	 8'h16: data <= { OP_ADD,   R_D,    R_NONE, N_NOP, 32'h0 };
	 8'h17: data <= { OP_WRITE, R_NONE, R_NONE, N_NOP, D_NONE };   // write go

 	 8'h18: data <= { OP_WAIT,  R_NONE, R_NONE, N_NOP, D_NONE };
	 8'h19: data <= { OP_ADD,   R_A,    R_NONE, N_NOP, 32'o17377770 };
	 8'h1a: data <= { OP_READ,  R_NONE, R_NONE, N_NOP, D_NONE };
	 8'h1b: data <= { OP_TST,   R_D,    R_I,    6'h18, 32'h00000001 }; // wait

	 // loop
	 8'h1c: data <= { OP_ADD,   R_C,    R_C,    N_NOP, 32'h00000001 }; // c++
	 8'h1d: data <= { OP_CMP,   R_C,    R_I,    6'h20, 32'd2000 };     // if (c == 100)
	 8'h1e: data <= { OP_ADD,   R_DA,   R_NONE, N_NOP, 32'h00000001 }; // da = da + 1
	 8'h1f: data <= { OP_JMP,   R_NONE, R_NONE, 6'h0c, D_NONE };       // loop back
	 8'h20: data <= { OP_ADD,   R_C,    R_I,    N_NOP, 32'h00000000 }; // c = 0
	 8'h21: data <= { OP_ADD,   R_DA,   R_NONE, N_NOP, 32'h00000000 }; // da = 0

`ifdef never
	 // read block
	 8'h22: data <= { OP_ADD,   R_D,    R_DA,   N_NOP, 32'h0 };	// d = da
 	 8'h23: data <= { OP_ADD,   R_A,    R_NONE, N_NOP, 32'o17377776 };
	 8'h24: data <= { OP_WRITE, R_NONE, R_NONE, N_NOP, 32'h0001 };  // write da

 	 8'h25: data <= { OP_ADD,   R_A,    R_NONE, N_NOP, 32'o17377775 };
	 8'h26: data <= { OP_ADD,   R_D,    R_NONE, N_NOP, 32'h00010100 };
	 8'h27: data <= { OP_WRITE, R_NONE, R_NONE, N_NOP, D_NONE };    // write clp

 	 8'h29: data <= { OP_ADD,   R_A,    R_NONE, N_NOP, 32'o17377774 };
	 8'h29: data <= { OP_ADD,   R_D,    R_NONE, N_NOP, 32'h0 };
	 8'h2a: data <= { OP_WRITE, R_NONE, R_NONE, N_NOP, D_NONE };	// write cmd

 	 8'h2b: data <= { OP_ADD,   R_A,    R_NONE, N_NOP, 32'o17377777 };
	 8'h2c: data <= { OP_ADD,   R_D,    R_NONE, N_NOP, 32'h0 };
	 8'h2d: data <= { OP_WRITE, R_NONE, R_NONE, N_NOP, D_NONE };	// write go

 	 8'h2e: data <= { OP_WAIT,  R_NONE, R_NONE, N_NOP, D_NONE };
 	 8'h2f: data <= { OP_ADD,   R_A,    R_NONE, N_NOP, 32'o17377770 };
	 8'h30: data <= { OP_READ,  R_NONE, R_NONE, N_NOP, D_NONE };
	 8'h31: data <= { OP_TST,   R_D,    R_I,    6'h2e, 32'h00000001 }; // wait
`else
	 8'h22: data <= { OP_JMP,   R_NONE, R_NONE, 6'h32, 32'h00000000 }; // skip
`endif

`ifdef never
	 // compare
	 8'h32: data <= { OP_ADD,   R_A,    R_NONE, N_NOP, 32'h11000 }; // a = 0x11000
	 8'h33: data <= { OP_ADD,   R_B,    R_NONE, N_NOP, 32'h0 };     // b = 0 (count)
	 8'h34: data <= { OP_READ,  R_NONE, R_NONE, N_NOP, D_NONE };    // read
	 8'h35: data <= { OP_CMP,   R_D,    R_DD,   6'h37, D_NONE };    // check
	 8'h36: data <= { OP_FAULT, R_NONE, R_NONE, N_NOP, D_NONE };
	 8'h37: data <= { OP_ADD,   R_A,    R_A,    N_NOP, 32'h00000001 }; // a++
	 8'h38: data <= { OP_ADD,   R_B,    R_B,    N_NOP, 32'h00000001 }; // b++
	 8'h39: data <= { OP_CMP,   R_B,    R_I,    6'h3b, 32'h00000100 }; // if (b == 100)
	 8'h3a: data <= { OP_JMP,   R_NONE, R_NONE, 6'h34, 32'h00000000 }; // loop
`else
	 8'h32: data <= { OP_JMP,   R_NONE, R_NONE, 6'h3b, 32'h00000000 }; // skip
`endif
	 
	 // loop
	 8'h3b: data <= { OP_ADD,   R_C,    R_NONE, N_NOP, 32'h00000001 }; // c++
	 8'h3c: data <= { OP_CMP,   R_C,    R_I,    6'h3f, 32'd1000 };     // if (c == 100)
	 8'h3d: data <= { OP_ADD,   R_DA,   R_NONE, N_NOP, 32'h00000001 }; // da = da + 1
	 8'h3e: data <= { OP_JMP,   R_NONE, R_NONE, 6'h22, D_NONE };       // loop reading
	 8'h3f: data <= { OP_ADD,   R_C,    R_I,    N_NOP, 32'h00000000 }; // c = 0
	 8'h40: data <= { OP_ADD,   R_DA,   R_NONE, N_NOP, 32'h00000000 }; // da = 0
	 8'h41: data <= { OP_DONE,  R_NONE, R_NONE, N_NOP, D_NONE };       // done
	 8'h42: data <= { OP_JMP,   R_NONE, R_NONE, 6'h00, 32'h00000000 }; // restart
	 
	 default: data <= { OP_JMP, R_NONE, R_NONE, 6'h00, D_NONE };
       endcase
endmodule

module cpu_test_cpu(clk, reset, start, done, fault, pc_out, dsk_out,
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
   output [11:0] dsk_out;
   reg [11:0] 	 dsk_out;
   
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
   reg [31:0] 	da;
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

   always @(posedge clk)
     if (reset)
       dsk_out <= 0;
     else
       dsk_out <= c[13:2];
   
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
		R_DA = 6,
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
		ir_sreg == R_DA ? da :
		ir_sreg == R_DD ? checker_out :
		0;

   assign dst = ir_dreg == R_A ? addr :
		ir_dreg == R_B ? b :
		ir_dreg == R_C ? c :
		ir_dreg == R_D ? data :
		ir_dreg == R_DA ? da :
		0;

   // da is magic (da = disk addr)
   wire da_blk_oflo  = da[4:0] == 5'd16;	// 17 sectors/track
   wire da_head_oflo = da[12:8] == 5'd18;	// 19 heads
   wire da_cyl_oflo  = da[27:16] == 12'd814;	// 815 cyls

   wire [4:0] da_blk_new  = da_blk_oflo  ? 5'b0  : da[4:0]   + 5'b00001;
   wire [4:0] da_head_new = da_head_oflo ? 5'b0  : da[12:8]  + 5'b00001;
   wire [11:0] da_cyl_new = da_cyl_oflo  ? 12'b0 : da[27:16] + 12'h001;
   
   always @(posedge clk)
     if (reset)
       da <= 0;
     else
       if (ir_op == OP_ADD && ir_dreg == R_DA)
	 begin
	    // clear
	    if (ir_data == 0)
	      da <= 0;
	    else
	      begin
		 // increment
		 da[4:0] <= da_blk_new;
		 da[12:8] <= da_blk_oflo ? da_head_new : da[12:8];
		 da[27:16] <= (da_head_oflo && da_blk_oflo) ? da_cyl_new : da[27:16];
	      end
	 end

   // normal registers
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

`ifdef debug
   always @(posedge clk)
   	if (ir_op == OP_ADD && ir_dreg == R_C)
	  $display("dsk: c <- 0x%x (%d) %t", c, c, $time);
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

   reg [4:0] wait_count;
   wire	wait_done;

   always @(posedge clk)
     if (reset)
       wait_count <= 0;
     else
       if (ir_op == OP_WAIT)
	 wait_count <= wait_count + 1;
       else
	 wait_count <= 0;
   
   assign wait_done = wait_count == 4'h1f;

`ifdef debug_wait
   always @(posedge clk)
     if (ir_op == OP_WAIT)
       $display("WAIT: count %x", wait_count);
`endif

   // small state machine to manage req/ack protocol to busint
   parameter [1:0]
		M_IDLE = 0,
		M_REQ = 1,
		M_WAIT = 2,
		M_DONE = 3;
   
   reg [1:0] mem_state;
   wire [1:0] mem_state_next;
   wire mem_done;

   always @(posedge clk)
     if (reset)
       mem_state <= 0;
     else
       mem_state <= mem_state_next;

   assign mem_state_next =
      (mem_state == M_IDLE && (ir_op == OP_WRITE || ir_op == OP_READ)) ? M_REQ :
      (mem_state == M_REQ && busint_memack) ? M_WAIT :
      (mem_state == M_WAIT && ~busint_memack) ? M_DONE :
      (mem_state == M_DONE) ? M_IDLE :
      mem_state;

   assign mem_done = mem_state == M_DONE;
   
   assign stall_pc =
		    ~start ||
		    (ir_op == OP_WAIT && ~wait_done) ||
		    (ir_op == OP_WRITE && ~mem_done) ||
		    (ir_op == OP_READ && ~mem_done);

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
	  busint_memrq <= mem_state == M_REQ;
	  busint_memwr <= mem_state == M_REQ && ir_op == OP_WRITE;
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
