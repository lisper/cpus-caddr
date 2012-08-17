//
// fake cpu which exercises all the external interfaces
// in a cpu-like manner
//

`define exercise_mcr
`define exercise_memory
//`define exercise_disk
`define exercise_disk_rw
`define normal

module cpu_test ( clk, ext_int, ext_reset, ext_boot, ext_halt, ext_switches,

	       spy_in, spy_out, dbread, dbwrite, eadr,

	       pc_out, state_out, machrun_out,
	       prefetch_out, fetch_out,
	       disk_state_out, bus_state_out,
	       
	       mcr_addr, mcr_data_out, mcr_data_in,
	       mcr_ready, mcr_write, mcr_done,

	       sdram_addr, sdram_data_in, sdram_data_out,
	       sdram_req, sdram_ready, sdram_write, sdram_done,

	       vram_addr, vram_data_in, vram_data_out,
	       vram_req, vram_ready, vram_write, vram_done,

	       ide_data_in, ide_data_out, ide_dior, ide_diow, ide_cs, ide_da,

	       kb_data, kb_ready,
	       ms_x, ms_y, ms_button, ms_ready );

   input clk;
   input ext_int;
   input ext_reset;
   input ext_boot;
   input ext_halt;
   input [7:0] ext_switches;

   input [15:0] spy_in;
   output [15:0] spy_out;
   input 	dbread;
   input 	dbwrite;
   input [3:0] 	eadr;

   output [13:0] pc_out;
   output [5:0]  state_out;
   output [4:0]  disk_state_out;
   output [3:0]  bus_state_out;
   output 	 machrun_out;
   output 	 prefetch_out;
   output 	 fetch_out;

   output [13:0] mcr_addr;
   output [48:0] mcr_data_out;
   input [48:0]  mcr_data_in;
   input 	 mcr_ready;
   output 	 mcr_write;
   input 	 mcr_done;

   output [21:0]  sdram_addr;
   output [31:0] sdram_data_out;
   input [31:0]  sdram_data_in;
   output 	 sdram_req;
   input 	 sdram_ready;
   output 	 sdram_write;
   input 	 sdram_done;

   output [14:0] vram_addr;
   output [31:0] vram_data_out;
   input [31:0]  vram_data_in;
   output 	 vram_req;
   input 	 vram_ready;
   output 	 vram_write;
   input 	 vram_done;
   
   input [15:0]  ide_data_in;
   output [15:0] ide_data_out;
   output 	 ide_dior;
   output 	 ide_diow;
   output [1:0]  ide_cs;
   output [2:0]  ide_da;

   input [15:0]  kb_data;
   input 	 kb_ready;
   
   input [11:0]  ms_x, ms_y;
   input [2:0] 	 ms_button;
   input 	 ms_ready;

   // --------------------------------------------------------------------------
   wire       state_decode, state_read, state_alu, state_write, state_fetch;
   wire       state_mmu, state_prefetch;

   wire        busint_memack, busint_memload;
   wire [31:0] busint_busout;

   wire        en_mem, en_mcr, en_dsk;
   wire        en_dk1, en_dk2;

   assign en_mem = ext_switches[0];
   assign en_mcr = ext_switches[1];
   assign en_dsk = ext_switches[2];
   assign en_dk1 = ext_switches[3];
   assign en_dk2 = ext_switches[4];

   reg [4:0]   busowner;
   
   // --------------------------------------------------------------------------
   wire       mcr_hold;
   wire       reset;

   assign reset = ext_reset;

   wire       need_mmu_state;
   assign     need_mmu_state = 0;
   
   assign fetch_out = state_fetch;
   assign prefetch_out = (need_mmu_state ? state_mmu : state_write) || state_prefetch;

   assign     mcr_hold = ~mcr_ready;

   // **********************
   // main cpu state machine
   // **********************
   
   parameter [5:0]
		STATE_RESET  = 6'b000000,
		STATE_DECODE = 6'b000001,
		STATE_READ   = 6'b000010,
		STATE_ALU    = 6'b000100,
		STATE_WRITE  = 6'b001000,
		STATE_MMU    = 6'b010000,
   		STATE_FETCH  = 6'b100000;

   reg [5:0] state;
   wire [5:0] next_state;
   
   always @(posedge clk)
     if (reset)
       state <= STATE_RESET;
     else
       state <= next_state;

   assign next_state = 
		       state == STATE_RESET  ? STATE_DECODE :
		       state == STATE_DECODE ? STATE_READ :
		       state == STATE_DECODE ? STATE_DECODE :
		       state == STATE_READ   ? STATE_ALU :
		       state == STATE_ALU    ? STATE_WRITE :
		       (state == STATE_WRITE && need_mmu_state) ? STATE_MMU :
		       (state == STATE_WRITE && ~need_mmu_state) ? STATE_FETCH :
		       state == STATE_MMU    ? STATE_FETCH :
		       (state == STATE_FETCH && mcr_hold) ? STATE_FETCH :
		       STATE_DECODE;

   assign state_decode = state[0];
   assign state_read = state[1];
   assign state_alu = state[2];
   assign state_write = state[3];
   assign state_mmu = state[4];
   assign state_prefetch = state[5] & mcr_hold;
   assign state_fetch = state[5] & ~mcr_hold;

   wire   ud_fault, md_fault, dd_fault;
   assign machrun_out = ~ud_fault && ~md_fault && ~dd_fault;

   //
   //
   //
   reg [7:0] mem_count, mcr_count, dsk_count;
   wire      m_done, ud_done, dd_done;
   wire [7:0] d_pc;
   wire [11:0] dsk_lba;
   
   assign pc_out = 
		   en_dk1 ? { 2'b0, dsk_lba } :
		   en_dk2 ? { 6'b0, dsk_count } :
		   en_mem ? { 6'b0, mem_count } :
		   en_mcr ? { 6'b0, mcr_count } :
		   en_dsk ? { 6'b0, d_pc } :
		   0;
      
   always @(posedge clk)
     if (reset)
       begin
	  mem_count <= 0;
	  mcr_count <= 0;
	  dsk_count <= 0;
       end
     else
       begin
	  if (m_done)
	    mem_count <= mem_count + 1;
	  if (ud_done)
	    mcr_count <= mcr_count + 1;
	  if (dd_done)
	    dsk_count <= dsk_count + 1;
`ifdef debug
	  if (m_done)
	    $display("******** mem_count %d ********", mem_count);
	  
	  if (ud_done)
	    $display("******** mcr_count %d ********", mcr_count);

	  if (dd_done)
	    $display("******** dsk_count %d ********", dsk_count);

//	  if (mem_count >= 10 || dsk_count >= 10) $finish;
`endif
       end
	     
   //
   //
   wire [21:0] dc_busint_addr;
   wire        dc_memrq, dc_memwr;

   wire [21:0] dw_busint_addr;
   wire [31:0] dw_busint_busin;
   wire        dw_memrq, dw_memwr;

   wire [21:0] md_busint_addr;
   wire [31:0] md_busint_busin;
   wire        md_memrq, md_memwr;
   
   
`ifdef exercise_mcr
   // *************
   // Excercise mcr
   // *************

   //
   // initially, fill mcr data with known data
   // then, acting as cpu, fetch mcr and check data
   //
   
   reg [2:0] ud_state;
   wire [2:0] ud_state_next;

   always @(posedge clk)
     if (reset)
       ud_state <= 0;
     else
       ud_state <= ud_state_next;

   parameter [2:0]
		UDS_IDLE = 0,
		UDS_FILL0 = 1,
		UDS_FILL1 = 2,
		UDS_CHECK = 3,
		UDS_DONE  = 4,
		UDS_FAULT = 5;

   wire u_done, u_fault;
   
   assign    ud_state_next =
			    (ud_state == UDS_IDLE && en_mcr) ? UDS_FILL0 :
			    ud_state == UDS_FILL0 ? UDS_FILL1 :
			    (ud_state == UDS_FILL1 & u_done) ? UDS_CHECK :
			    (ud_state == UDS_CHECK & u_fault) ? UDS_FAULT :
			    ud_state;

   assign ud_fault = ud_state == UDS_FAULT;
//   assign ud_done = ud_state == UDS_DONE;
   
   //
   //
   reg [3:0] u_state;
   wire [3:0] u_state_next;

   always @(posedge clk)
     if (reset)
       u_state <= 0;
     else
       u_state <= u_state_next;

   parameter [3:0]
		U_IDLE = 0,
		U_START = 1,
		U_DO_W  = 2,
		U_DO_W1 = 3,
		U_DO_W2 = 4,
		U_NEXT = 5,
		U_HOLD = 6,
		U_DONE = 7;

   wire u_start, u_start_w;
   wire u_full, u_clr, u_incr;
   
   assign u_start_w = ud_state == UDS_FILL0;

   assign u_done = u_state == U_DONE;
   assign u_clr = (u_state == U_START) || (u_state == U_HOLD);
   assign u_incr = u_state == U_NEXT || (u_state == /*U_IDLE*/U_DONE && fetch_out);

   assign ud_done = u_full;

   assign u_state_next =
			(u_state == U_IDLE && u_start_w) ? U_START :
			u_state == U_START ? U_DO_W :

			u_state == U_DO_W ? U_DO_W1 :
			(u_state == U_DO_W1 && mcr_done) ? U_DO_W2 :
			u_state == U_DO_W2 ? U_NEXT :

			(u_state == U_NEXT && u_full) ? U_HOLD :
			(u_state == U_NEXT && ~u_full) ? U_DO_W :

			(u_state == U_HOLD && fetch_out) ? U_DONE :
//			u_state == U_DONE ? U_IDLE :
			u_state;

   reg [13:0] u_addr;

   always @(posedge clk)
     if (reset)
       u_addr <= 0;
     else
       if (u_clr)
	 u_addr <= 0;
       else
	 if (u_incr)
	   u_addr <= u_addr + 1;

`ifdef short_test
   assign     u_full = (u_addr == 16'h0003) && u_state == U_NEXT;
`else
   assign     u_full = (u_addr == 16'h3fff) && u_state == U_NEXT;
`endif
   
   assign mcr_write = u_state == U_DO_W1;
   assign mcr_addr = u_addr;

   reg [48:0] u_data;
   wire [48:0] u_checker_out;
   reg [13:0]  u_last_addr;
   
   always @(posedge clk)
     if (reset)
       u_data <= 0;
     else
       if (mcr_ready)
	 u_data <= mcr_data_in;

   cpu_test_mcr cpu_test_mcr(
			     .clk(clk),
			     .reset(reset),
			     .addr(mcr_addr),
			     .data(u_checker_out),
			     .ena((u_state == U_DO_W) || state_fetch)
			     );

`ifdef debug_mcr
   always @(posedge clk)
     if ((u_state == U_START) || state_fetch)
       $display("cpu_test_mcr: addr=%x data=%x", mcr_addr, u_checker_out);
`endif

   always @(posedge clk)
     if (reset)
       begin
	  u_last_addr <= 0;
       end
     else
       if ((u_state == U_DO_W1) || state_fetch)
	 begin
	    u_last_addr <= mcr_addr;
	 end

   assign mcr_data_out = u_checker_out;

   wire ud_ok;
   assign ud_ok = (u_data == u_checker_out);

   assign u_fault = (ud_state == UDS_CHECK) && state_decode && ~ud_ok;

`ifdef debug_mcr
   always @(posedge clk)
     if (ud_state == UDS_CHECK && state_decode)
       $display("ud: u_last_addr=0x%x u_data=%o u_checker_out=%o %t",
		u_last_addr, u_data, u_checker_out, $time);

   always @(posedge clk)
     if (u_fault)
       begin
	  $display("u_fault: u_last_addr=0x%x u_data=%o u_checker_out=%o %t",
		   u_last_addr, u_data, u_checker_out, $time);
	  $finish;
       end
`endif
   
`else
   assign ud_fault = 0;
   assign mcr_addr = 0;
   assign mcr_write = 0;
   assign mcr_data_out = 0;
`endif
   
`ifdef exercise_memory
   // ****************
   // Excercise memory
   // ****************

   //
   // alternately fill 64k of memory and then read it back,
   // checking the contents
   //
   reg [2:0] md_state;
   wire [2:0] md_state_next;

   always @(posedge clk)
     if (reset)
       md_state <= 0;
     else
       md_state <= md_state_next;

   parameter [2:0]
		MDS_IDLE = 0,
		MDS_WRITE0 = 1,
		MDS_WRITE1 = 2,
		MDS_READ0 = 3,
		MDS_READ1 = 4,
		MDS_FAULT = 5;

   wire m_fault;
   
   assign    md_state_next =
			    (md_state == MDS_IDLE && en_mem)    ? MDS_WRITE0 :
			    md_state == MDS_WRITE0              ? MDS_WRITE1 :
			    (md_state == MDS_WRITE1 && m_done)  ? MDS_READ0 :
			    (md_state == MDS_WRITE1 && m_fault) ? MDS_FAULT :
			    md_state == MDS_READ0               ? MDS_READ1 :
			    (md_state == MDS_READ1 && m_done)   ? MDS_IDLE :
			    (md_state == MDS_READ1 && m_fault)  ? MDS_FAULT :
			    md_state;

   assign    md_fault = md_state == MDS_FAULT;
   
   //
   //
   reg [3:0] m_state;
   wire [3:0] m_state_next;

   always @(posedge clk)
     if (reset)
       m_state <= 0;
     else
       m_state <= m_state_next;

   parameter [3:0]
		M_IDLE = 0,
		M_START = 1,
		M_DO_R = 2,
		M_DO_R1 = 3,
		M_DO_R2 = 4,
		M_DO_W = 5,
		M_DO_W1 = 6,
		M_DO_W2 = 7,
		M_NEXT = 8,
		M_DONE = 9,
		M_DONE1 = 10,
		M_DONE2 = 11;

   wire m_start, m_start_w, m_start_r;
   wire m_full, m_clr, m_incr;
   
   assign m_start_w = md_state == MDS_WRITE1;
   assign m_start_r = md_state == MDS_READ1;
   assign m_start = m_start_w || m_start_r;

   assign m_done = m_state == M_DONE;
   assign m_clr = m_state == M_START;
   assign m_incr = m_state == M_NEXT;

   wire   m_memack;
   assign m_memack = busint_memack && (busowner == 5'b00001);
   
   assign m_state_next =
			(m_state == M_IDLE && m_start) ? M_START :
			(m_state == M_START && m_start_r) ? M_DO_R :
			(m_state == M_START && m_start_w) ? M_DO_W :

			(m_state == M_DO_W && m_memack) ? M_DO_W1 :
			m_state == M_DO_W1 ? M_DO_W2 :
			m_state == M_DO_W2 ? M_NEXT :

			(m_state == M_DO_R && m_memack) ? M_DO_R1 :
			m_state == M_DO_R1 ? M_DO_R2 :
			m_state == M_DO_R2 ? M_NEXT :

			(m_state == M_NEXT && m_full) ? M_DONE :
			(m_state == M_NEXT && m_start_r) ? M_DO_R :
			(m_state == M_NEXT && m_start_w) ? M_DO_W :

			m_state == M_DONE  ? M_DONE1 :
			m_state == M_DONE1 ? M_DONE2 :
			m_state == M_DONE2 ? M_IDLE :
			m_state;

   reg [15:0] m_addr;

   always @(posedge clk)
     if (reset)
       m_addr <= 0;
     else
       if (m_clr)
	 m_addr <= 0;
       else
	 if (m_incr)
	   m_addr <= m_addr + 1;

 `ifdef short_test
   assign m_full = m_addr == 16'h0005;
 `else
   assign m_full = m_addr == 16'hffff;
 `endif
   
   assign md_memrq = m_state == M_DO_W || m_state == M_DO_R;
   assign md_memwr = md_memrq && m_start_w;
   assign md_busint_addr = { 6'b0, m_addr };

   reg [31:0] data;
   reg [31:0] check_data;
   wire [31:0] checker_out;
   
   always @(posedge clk)
     if (reset)
       data <= 0;
     else
       if (busint_memload)
	 data <= busint_busout;

   cpu_test_data cpu_test_data(
			       .clk(clk),
			       .reset(reset),
			       .addr(md_busint_addr),
			       .data(checker_out),
			       .ena(1'b1)
			       );
   
`ifdef debug_checker
   always @(posedge clk)
     if ((m_state != M_DO_R && m_state_next == M_DO_R) ||
	 (m_state != M_DO_W && m_state_next == M_DO_W))
       $display("cpu_test_data: addr=%x data=%x", md_busint_addr, checker_out);
`endif

   always @(posedge clk)
     if (reset)
       check_data <= 0;
     else
       if (m_state == M_DO_R || m_state == M_DO_W)
	 check_data <= checker_out;

   assign md_busint_busin = check_data;

   wire md_ok;
   assign md_ok = data == check_data;

   assign m_fault = m_start_r && (m_state == M_NEXT) && ~md_ok;

`ifdef debug
   always @(posedge clk)
     if (m_fault)
       begin
	  $display("m_fault: m_addr=0x%x data=%x check_data=%x %t",
		   m_addr, data, check_data, $time);
	  $finish;
       end
`endif

`ifdef debug_activity
   always @(posedge clk)
     if (m_incr && m_addr[7:0] == 0)
       $display("mem: m_addr=0x%x %t", m_addr, $time);
`endif
   
`else
   assign md_fault = 0;
   assign md_busint_addr = 0;
   assign md_busint_busin = 0;
   assign md_memrq = 0;
   assign md_memwr = 0;
`endif

`ifdef exercise_disk
   // **************
   // Excercise disk
   // **************

   //
   // assume disk has known data on sector 0
   // read sector 0 into memory @ 128k
   //   write disk controller registers
   //     write mem 0x10001 <- 0x11000
   //     write da (reg 6)
   //     write clp (reg 5) <-  0x10001
   //     write command 0 (reg 4)
   //     write start (reg 7)
   //   wait for disk controller done
   //     read status (reg 0)
   // read memory @ 128k and compare
   //   read memory
   //

   reg [2:0] dd_state;
   wire [2:0] dd_state_next;

   always @(posedge clk)
     if (reset)
       dd_state <= 0;
     else
       dd_state <= dd_state_next;

   parameter [2:0]
		DDS_IDLE = 0,
		DDS_START = 1,
		DDS_READ = 2,
		DDS_COMPARE = 3,
		DDS_DONE = 4,
		DDS_FAULT = 5;
  
   wire d_done, d_end, d_fault;

   assign dd_state_next =
			 dd_state == DDS_IDLE                 ? DDS_START :
			 dd_state == DDS_START                ? DDS_READ :
			 (dd_state == DDS_READ && d_done)     ? DDS_COMPARE :
			 (dd_state == DDS_COMPARE && d_end)   ? DDS_DONE :
			 (dd_state == DDS_COMPARE && d_fault) ? DDS_FAULT :
			 dd_state == DDS_DONE                 ? DDS_IDLE :
			 dd_state;

   assign dd_fault = dd_state == DDS_FAULT;
   assign dd_done = dd_state == DDS_DONE;
   
   //
   // disk controller register setup
   reg [3:0] dr_state;
   wire [3:0] dr_state_next;

   always @(posedge clk)
     if (reset)
       dr_state <= 0;
     else
       dr_state <= dr_state_next;

   parameter [3:0]
		DR_IDLE = 0,
		DR_START = 1,
		DR_DO_W1 = 2,
		DR_DO_W2 = 3,
		DR_DO_W3 = 4,
		DR_DO_W4 = 5,
		DR_DO_W5 = 6,
		DR_WAIT = 7,
		DR_DONE = 8;

   wire dr_start, dw_done;

   assign dr_start = dd_state == DDS_START;
   assign d_done = dr_state == DR_DONE;

   assign dr_state_next =
			(dr_state == DR_IDLE && dr_start) ? DR_START :
			 dr_state == DR_START ? DR_DO_W1 :
			 (dr_state == DR_DO_W1 && dw_done) ? DR_DO_W2 :
			 (dr_state == DR_DO_W2 && dw_done) ? DR_DO_W3 :
			 (dr_state == DR_DO_W3 && dw_done) ? DR_DO_W4 :
			 (dr_state == DR_DO_W4 && dw_done) ? DR_DO_W5 :
			 (dr_state == DR_DO_W5 && dw_done) ? DR_WAIT :
			 (dr_state == DR_WAIT  && dw_done && dc_data[0]) ? DR_DONE :
			 (dr_state == DR_WAIT  && dw_done && ~dc_data[0]) ? DR_WAIT :
			 dr_state;

   //
   // write one disk register
   reg [31:0] dc_data;

   reg [3:0] dw_state;
   wire [3:0] dw_state_next;

   always @(posedge clk)
     if (reset)
       dw_state <= 0;
     else
       dw_state <= dw_state_next;

   parameter [3:0]
		DW_IDLE = 0,
		DW_START = 1,
		DW_WAIT  = 2,
		DW_DONE  = 3;

   wire dw_start, dw_active;
   
   assign dw_done = dw_state == DW_DONE;
   assign dw_start = (dr_state == DR_DO_W1 ||
		      dr_state == DR_DO_W2 ||
		      dr_state == DR_DO_W3 ||
		      dr_state == DR_DO_W4 ||
		      dr_state == DR_DO_W5 ||
   		      dr_state == DR_WAIT);

   wire   dw_memack;
   assign dw_memack = busint_memack && (busowner == 5'b00010);
   
   assign dw_state_next =
		(dw_state == DW_IDLE && dw_start) ? DW_START :
		 dw_state == DW_START ? DW_WAIT :
		 (dw_state == DW_WAIT && dw_memack) ? DW_DONE :
		 dw_state == DW_DONE ? DW_IDLE :			 
		 dw_state;

   assign dw_active = (dw_state == DW_START) || (dw_state == DW_WAIT);
   assign dw_memrq = dw_active;
   assign dw_memwr = dw_active && ~(dr_state == DR_WAIT);

   assign dw_busint_addr = 
			   dr_state == DR_DO_W1 ? 22'h010001 :
			   dr_state == DR_DO_W2 ? 22'o17377776 :
			   dr_state == DR_DO_W3 ? 22'o17377775 :
			   dr_state == DR_DO_W4 ? 22'o17377774 :
			   dr_state == DR_DO_W5 ? 22'o17377777 :
			   dr_state == DR_WAIT  ? 22'o17377770 :
			   0;
   
   assign dw_busint_busin = 
			   dr_state == DR_DO_W1 ? 22'h011000 :
			   dr_state == DR_DO_W2 ? 22'o0 :
			   dr_state == DR_DO_W3 ? 22'h010001 :
			   dr_state == DR_DO_W4 ? 22'o0 :
			   0;

   //
   // disk data compare
   reg [3:0] dc_state;
   wire [3:0] dc_state_next;

   always @(posedge clk)
     if (reset)
       dc_state <= 0;
     else
       dc_state <= dc_state_next;

   parameter [3:0]
		DC_IDLE = 0,
		DC_START = 1,
		DC_READ  = 2,
		DC_CHECK = 3,
		DC_NEXT  = 4,
		DC_DONE  = 5;

   wire dc_start, dc_active;
   wire dc_end, dc_clr, dc_incr;
   
   assign dc_start = dd_state == DDS_COMPARE;

   assign d_end = dc_state == DC_DONE;
   assign dc_clr = dc_state == DC_START;
   assign dc_incr = dc_state == DC_NEXT;

   wire   dc_memack;
   assign dc_memack = busint_memack && (busowner == 5'b00100);

   assign dc_state_next =
			 (dc_state == DC_IDLE && dc_start) ? DC_START :
			 dc_state == DC_START ? DC_READ :
			 (dc_state == DC_READ && dc_memack) ? DC_CHECK :
			 dc_state == DC_CHECK ? DC_NEXT :
			 (dc_state == DC_NEXT && dc_end) ? DC_DONE :
			 (dc_state == DC_NEXT && ~dc_end) ? DC_READ :
			 dc_state == DC_DONE ? DC_IDLE :
			 dc_state;
   
   reg [7:0]   dc_addr;
   
   always @(posedge clk)
     if (reset)
       dc_addr <= 0;
     else
       if (dc_clr)
	 dc_addr <= 0;
       else
	 if (dc_incr)
	   dc_addr <= dc_addr + 1;

   assign dc_end = dc_addr == 16'hff;
   assign dc_active = (dc_state == DC_START) || (dc_state == DC_READ);

   assign dc_memrq = dc_active;
   assign dc_memwr = 0;
   assign dc_busint_addr = { 14'h0110, dc_addr };

   reg [31:0] dc_check_data;
   wire [31:0] dc_checker_out;
   
   always @(posedge clk)
     if (reset)
       dc_data <= 0;
     else
       if (busint_memload)
	 dc_data <= busint_busout;

   cpu_test_disk cpu_test_disk(
			       .clk(clk),
			       .reset(reset),
			       .addr(dc_addr),
			       .data(dc_checker_out)
			       );
   
   always @(posedge clk)
     if (reset)
       dc_check_data <= 0;
     else
       if (dc_state == DC_READ)
	 dc_check_data <= dc_checker_out;

   wire dc_ok;
   assign dc_ok = dc_data == dc_check_data;

   assign d_fault = dc_start && (dc_state == DC_NEXT) && ~dc_ok;

`ifdef debug
   always @(posedge clk)
     if (d_fault)
       begin
	  $display("d_fault: dc_addr=0x%x dc_data=%x dc_check_data=%x %t",
		   dc_addr, dc_data, dc_check_data, $time);
	  $finish;
       end
`endif

`else // !`ifdef exercise_disk
   assign dc_busint_addr = 0;
   assign dc_memrq = 0;
   assign dc_memwr = 0;
`endif
   
`ifdef exercise_disk_rw

   reg [1:0] dd_state;
   wire [1:0] dd_state_next;

   always @(posedge clk)
     if (reset)
       dd_state <= 0;
     else
       dd_state <= dd_state_next;

   parameter [2:0]
		DDS_IDLE = 0,
		DDS_START = 1,
		DDS_DONE  = 2,
		DDS_FAULT = 3;
  
   wire d_fault;

   assign dd_state_next =
			 dd_state == DDS_IDLE  ? DDS_START :
			 dd_state == DDS_START ? DDS_DONE :
			 (dd_state == DDS_DONE && d_fault) ? DDS_FAULT :
			 dd_state;

   assign dd_fault = dd_state == DDS_FAULT;

   wire dd_memack, dd_memdone;
 `ifdef normal
   assign dd_memack = busint_memack && (busowner == 5'b00010);
   assign dd_memdone = busint_memload && (busowner == 5'b00010);
 `else
   assign dd_memack = busint_memack;
   assign dd_memdone = busint_memload;
 `endif
     
   // everything is done by the test computer
   cpu_test_cpu cpu_test_cpu(.clk(clk),
			     .reset(reset),
			     .start(en_dsk),
			     .done(dd_done),
			     .fault(d_fault),
			     .pc_out(d_pc),
			     .dsk_out(dsk_lba),
			     .busint_memrq(dw_memrq),
			     .busint_memwr(dw_memwr),
			     .busint_memack(dd_memack),
			     .busint_memdone(dd_memdone),
			     .busint_addr(dw_busint_addr),
			     .busint_busin(busint_busout),
			     .busint_busout(dw_busint_busin));
   
`ifdef debug
   always @(posedge clk)
     if (d_fault)
       begin
	  $display("d_fault: d_pc=0x%x %t",
		   d_pc, $time);
	  $finish;
       end
`endif

`endif

`ifndef exercise_disk_rw
 `ifndef exercise_disk
  `define no_disk
 `endif
`endif
   
`ifdef no_disk
   assign dd_fault = 0;

   assign dw_busint_addr = 0;
   assign dw_busint_busin = 0;
   assign dw_memrq = 0;
   assign dw_memwr = 0;

   assign dc_busint_addr = 0;
   assign dc_memrq = 0;
   assign dc_memwr = 0;
`endif

   // *************
   // Bus Interface
   // *************

 `ifdef normal
   reg [31:0] busint_busin;
   reg [21:0] busint_addr;
   reg 	      busint_memrq;
   reg 	      busint_memwr;
   
   wire        bus_interrupt;
   wire        set_promdisable;

   always @(posedge clk)
     if (reset)
       busowner <= 5'b0;
     else
       begin
`ifdef debug_busowner
	  if (busowner == 5'b0000 && dc_memwr)
	    $display("busowner: dc");
	  if (busowner == 5'b0000 && dw_memwr)
	    $display("busowner: dw");
	  if (busowner == 5'b0000 && md_memwr)
	    $display("busowner: md");
`endif
       busowner <=
		  (busowner == 5'b00000 && dc_memrq)  ? 5'b00100 :
		  (busowner == 5'b00000 && dw_memrq)  ? 5'b00010 :
		  (busowner == 5'b00000 && md_memrq)  ? 5'b00001 :
		  (busowner == 5'b00100 && ~dc_memrq) ? 5'b01000 :
		  (busowner == 5'b00010 && ~dw_memrq) ? 5'b01000 :
		  (busowner == 5'b00001 && ~md_memrq) ? 5'b01000 :
		  (busowner == 5'b01000)              ? 5'b10000 :
		  (busowner == 5'b10000)              ? 5'b11000 :
		  (busowner == 5'b11000)              ? 5'b00000 :
		  busowner;
       end
   
   always @(posedge clk)
     if (reset)
       begin
	  busint_busin <= 0;
	  busint_addr <= 0;
	  busint_memrq <= 0;
	  busint_memwr <= 0;
       end
     else
       begin
	  case (busowner)
	    5'b00001: busint_memrq <= md_memrq;
	    5'b00010: busint_memrq <= dw_memrq;
	    5'b00100: busint_memrq <= dc_memrq;
	    default: busint_memrq <= 0;
	  endcase

	  case (busowner)
	    5'b00001: busint_memwr <= md_memwr;
	    5'b00010: busint_memwr <= dw_memwr;
	    5'b00100: busint_memwr <= dc_memwr;
	    default: busint_memwr <= 0;
	  endcase

	  case (busowner)
	    5'b00001: busint_addr <= md_busint_addr;
	    5'b00010: busint_addr <= dw_busint_addr;
	    5'b00100: busint_addr <= dc_busint_addr;
	    default: busint_addr <= 0;
	  endcase
   
	  case (busowner)
	    5'b00001: busint_busin <= md_busint_busin;
	    5'b00010: busint_busin <= dw_busint_busin;
	    default: busint_busin <= 0;
	  endcase
       end
`else // !`ifdef normal
   wire [31:0] busint_busin;
   wire [21:0]  busint_addr;
   wire 	busint_memrq;
   wire 	busint_memwr;
   
   wire        bus_interrupt;
   wire        set_promdisable;

   assign busint_memrq = dw_memrq;
   assign busint_memwr = dw_memwr;
   assign busint_addr  = dw_busint_addr;
   assign busint_busin = dw_busint_busin;
`endif	    
   

   busint busint(
		 .mclk(clk),
		 .reset(reset),
		 .addr(busint_addr),
		 .busin(busint_busin),
		 .busout(busint_busout),
		 .spyin(spy_in),
		 .spyout(busint_spyout),

		 .req(busint_memrq),
		 .ack(busint_memack),
		 .write(busint_memwr),
		 .load(busint_memload),
		 
		 .interrupt(bus_interrupt),

		 .sdram_addr(sdram_addr),
		 .sdram_data_in(sdram_data_in),
		 .sdram_data_out(sdram_data_out),
		 .sdram_req(sdram_req),
		 .sdram_ready(sdram_ready),
		 .sdram_write(sdram_write),
		 .sdram_done(sdram_done),
      
		 .vram_addr(vram_addr),
		 .vram_data_in(vram_data_in),
		 .vram_data_out(vram_data_out),
		 .vram_req(vram_req),
		 .vram_ready(vram_ready),
		 .vram_write(vram_write),
		 .vram_done(vram_done),
		 
		 .ide_data_in(ide_data_in),
		 .ide_data_out(ide_data_out),
		 .ide_dior(ide_dior),
		 .ide_diow(ide_diow),
		 .ide_cs(ide_cs),
		 .ide_da(ide_da),

		 .kb_data(kb_data),
		 .kb_ready(kb_ready),
		 .ms_x(ms_x),
		 .ms_y(ms_y),
		 .ms_button(ms_button),
		 .ms_ready(ms_ready),

		 .promdisable(set_promdisable),
		 .disk_state(disk_state_out),
		 .bus_state(bus_state_out)
		 );

endmodule

