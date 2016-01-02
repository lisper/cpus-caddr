/*
 * xbus-disk.v
 * $Id$
 * generic block device version
 *
 * It expects the block device to provide 1024 byte blocks w/16 bit interface
 * Currently the lba is passed with 512 byte block addressing
 * 
 */

/*
17377774
17377770 disk

	disk controller registers:
	  0 read status
	  1 read ma
	  2 read da
	  3 read ecc
	  4 load cmd
	  5 load clp (command list pointer)
	  6 load da (disk address)
	  7 start

	Commands (cmd reg)
	  0000 read
	  0010 read compare
	  0011 write
	  0002 read all
	  0013 write all
	  0004 seek
	  0005 at ease
	  1005 recalibreate
	  0405 fault clear
	  0006 offset clear
	  0016 stop,reset

	Command bits
	  0
	  1 cmd
	  2

	  3 cmd to memory
	  4 servo offset plus
	  5 servo offset

	  6 data strobe early
	  7 data strobe late
	  8 fault clear

	  9 recalibrate
	  10 attn intr enb
	  11 done intr enb

	Status bits (status reg)
	  0 active-
	  1 any attention
	  2 sel unit attention
	  3 intr
	  4 multiple select
	  5 no select
	  6 sel unit fault
	  7 sel unit read only
	  8 on cyl sync-
	  9 sel unit on line-
	  10 sel unit seek error
	  11 timeout error
	  12 start block error
	  13 stopped by error
	  14 overrun
	  15 ecc.soft

	  16 ecc.hard
	  17 header ecc err
	  18 header compare err
	  19 mem parity err
	  20 nmx error
	  21 ccw cyc
	  22 read comp diff
	  23 internal parity err
	  
	  24-31 block.ctr

	Disk address (da reg)
	  31 n/c
	  30 unit2
	  29 unit1
	  28 unit0

	  27 cyl11
	  ...
	  16 cyl0	  
	  
	  15 head7
	  ...
	  8  head0

	  7  block7
	  ...
	  0  block0

	  ---

	  clp (command list pointer) points to list of CCW's
	  Each CCW is phy address to write block

	  clp register (22 bits)
	  [21:16][15:0]
	  fixed  counts up

	  clp address is used to read in new ccw
	  ccw's are read (up to 65535)

	  ccw is used to produce dma address
	  dma address comes from ccw + 8 bit counter

	  ccw
	  [21:1][1]
          physr  |
	  addr   0 = last ccw, 1 = more ccw's

	  ccw   counter
	  [21:8][7:0]

	  ---

	  read ma register
	   t0  t1 CLP
	  [23][22][21:0]
            |   |
            |   type 1 (show how controller is strapped; i.e. what type of
            type 0      disk drive)

	    (trident is type 0)


 -----------------------------------------------------------------

 we look like a Trident T-300:
   cyls = 815
   heads/unit = 19
   blocks/track = 17

 17*19=323

 323 = 320 + 3 = 16 * 10 * 2 + 3

 blocks are 256 * 4 = 1024 bytes

 block# = (cyl * blocks/track * heads/unit) +
 (head * blocks/track) + block

    
 Commands implemented
 
 disk_cmd
	0000 read
	0010 read compare
	0011 write
	1005 recalibreate
	0405 fault clear
 
        disk_da
        3322222222221111111111
        10987654321098765432109876543210
         uuucccccccccccchhhhhhhhbbbbbbbb
        unit            head
            cylinder            block
 
 read
	process ccw's
 	  dma word from ccw address (disk_clp)
          dma address = { word[31:8], 8'b0 }
 
 	  read block
 	     (blocks are 256 * 4 = 1024 bytes)
             block# = (cyl * blocks/track * heads/unit) +
 			(head * blocks/track) + block

 	     dma 256 words to memory
 
 	  increment da, respecting blocks/track & heads/unit
          if word[0]==0, stop
          increment disk_clp
          repeat

 	if disk_cmd[11]
 	   assert interrupt
 
 read compare
 	same as read but don't dma write; dma read instead  
 
 write
	process ccw's
 	  dma word from ccw address (disk_clp)
          dma address = { word[31:8], 8'b0 }
 
 	  write block
 	     (blocks are 256 * 4 = 1024 bytes)
             block# = (cyl * blocks/track * heads/unit) +
 			(head * blocks/tracks) + block

 	     dma 256 words from memory
 
 	  increment da, respecting blocks/track & heads/unit
          if word[0]==0, stop
          increment disk_clp
          repeat

 	if disk_cmd[11]
 	   assert interrupt

 recalibreate
	does nothing
 
 fault clear
 	does nothing
 
 -----------------------------------------------------------------

 states
 
 s_idle
 	if start
 		if disk_cmd == 0000 goto s_read_ccw
  		if disk_cmd == 0010 goto s_read_ccw
   		if disk_cmd == 0011 goto s_read_ccw
    		if disk_cmd == 1005 goto s_busy
     		if disk_cmd == 0405 goto s_busy
 		else goto s_idle

 s_busy
 	goto s_idle
 
 s_read_ccw 
 	req_out = 1
 	addrout = disk_clp
 
 	if (grantin)
 		goto s_read_ccw2

 s_read_ccw2 
 	disk_ccw <= datain
 
*/
  
module xbus_disk (
		  reset, clk,
		  addrin, addrout,
		  datain, dataout,
		  reqin, reqout,
		  ackin, ackout,
		  busgrantin, busreqout,
		  writein, writeout,
		  decodein, decodeout,
		  interrupt,
		  bd_cmd, bd_start, bd_bsy, bd_rdy, bd_err, bd_addr,
		  bd_data_in, bd_data_out, bd_rd, bd_wr, bd_iordy, bd_state_in,
		  disk_state
		);

   input reset;
   input clk;
   input [21:0] addrin;		/* request address */
   input [31:0] datain;		/* request data */
   input 	reqin;		/* request read */
   input 	ackin;		/* ack */
   input 	busgrantin;	/* grant from bus arbiter */
   input 	writein;	/* request read#/write */
   input 	decodein;	/* decode ok from bus arbiter */
   
   output [21:0] addrout;
   output [31:0] dataout;
   output 	 reqout;	/* request read */
   output 	 ackout;	/* request done */
   output 	 busreqout;	/* reques bus */
   output 	 writeout;	/* reques write */
   output 	 decodeout;	/* request addr ok */
   output 	 interrupt;

   reg [21:0] 	 addrout;
   reg 		 reqout;
   reg 		 writeout;
   reg 		 busreqout;

   output [1:0]  bd_cmd;	/* generic block device interface */
   output 	 bd_start;
   input 	 bd_bsy;
   input 	 bd_rdy;
   input 	 bd_err;
   output [23:0] bd_addr;
   input [15:0]  bd_data_in;
   output [15:0] bd_data_out;
   output 	 bd_rd;
   output 	 bd_wr;
   input 	 bd_iordy;
   input [11:0]  bd_state_in;
   
   output [4:0]  disk_state;

   reg [1:0]	 bd_cmd;
   reg 		 bd_start;
   reg [15:0] 	 bd_data_out;
   reg 		 bd_rd;
   reg 		 bd_wr;
   
   // -------------------------------------------------------------------
   
   reg [21:0] 	disk_clp;
   reg [9:0] 	disk_cmd;

   reg 		attn_intr_enb;
   reg 		done_intr_enb;

   reg [2:0] 	disk_unit;
   reg [11:0] 	disk_cyl;
   reg [4:0] 	disk_head;
   reg [4:0] 	disk_block;
   
   wire [31:0] 	disk_da;

   reg [31:0] 	disk_ma;

   reg [21:8] 	disk_ccw;
   reg 		more_ccws;

   reg 		disk_interrupt;
   
   parameter DISK_CMD_READ = 10'o0000,
	       DISK_CMD_RDCMP = 10'o0010,
	       DISK_CMD_WRITE = 10'o0011,
	       DISK_CMD_RECAL = 10'o1005,
	       DISK_CMD_CLEAR = 10'o0405;
	       
   wire 	 addr_match;
   wire 	 decode;
   reg [1:0]	 ack_delayed;

   wire 	 active;
   reg 		 err;
   
   wire [31:0] 	 disk_status;

   // disk state
`ifdef never
   parameter [4:0]
		s_idle = 0,
		s_busy = 1,
		s_read_ccw = 2,
		s_read_ccw_done = 3,
		s_init0 = 4,
		s_init1 = 5,

		s_read0 = 6,
		s_read1 = 7,
		s_read2 = 8,
		s_read3 = 9,

		s_write0 = 10,
		s_write1 = 11,
		s_write1a = 21,
		s_write2 = 12,
		s_write2a = 22,

		s_last0 = 14,
		s_last1 = 15,
		s_last2 = 16,
		s_done0 = 17,
		s_done1 = 18,
		s_reset = 19,
		s_reset0 = 20;
`else
   parameter [4:0]
		s_idle = 0,
		s_busy = 1,
		s_read_ccw = 2,
		s_read_ccw_done = 3,
		s_init0 = 4,
		s_init1 = 5,

		s_read0 = 6,
		s_read1 = 7,
		s_read2 = 8,
		s_read3 = 9,

		s_write0 = 10,
		s_write1 = 11,
		s_write1a = 12,
		s_write2 = 13,
		s_write2a = 14,

		s_last0 = 15,
		s_last1 = 16,
		s_last2 = 17,
		s_done0 = 18,
		s_done1 = 19,
		s_reset = 20,
		s_reset0 = 21;
`endif
   
    reg [4:0] state;
    reg [4:0] state_next;

 // synthesis attribute keep state true;
 // synthesis attribute keep reqin true;
 // synthesis attribute keep ackout true;
 // synthesis attribute keep reqout true;
 // synthesis attribute keep busreqout true;
 // synthesis attribute keep busgrantin true;
 // synthesis attribute keep writeout true;
 // synthesis attribute keep ackin true;

    parameter DISK_CYLS = 815,
		DISK_HEADS = 19,
		DISK_BLOCKS = 17;

    reg [23:0] lba;
    wire [22:0] block_number;

    wire [22:0] cyl_blocks;
    wire [8:0]  head_blocks;
    wire [17:0] cylx10;

    reg        clear_err;
    reg        set_err;
    reg        clear_wc;
    reg        inc_wc;
    reg        inc_da;
    reg        inc_clp;
    reg        assert_int;
    reg 	      deassert_int;

    reg        disk_start;


    reg [31:0] reg_dataout;
    reg [31:0] dma_dataout;

 `ifdef debug
   integer  debug/* verilator public_flat */;
   integer  debug_state/* verilator public_flat */;
   
    initial
      begin
	 debug = 0/*1*/;
	 debug_state = 0/*1*/;
      end
 `endif

    // -----------------------------------------------------------------


    assign interrupt = done_intr_enb & disk_interrupt;


    // bus address
    assign addr_match = { addrin[21:6], 6'b0 } == 22'o17377700 ?
			1'b1 : 1'b0;

    assign decode = (reqin && addr_match) ? 1'b1 : 1'b0;

    assign decodeout = decode;
    assign ackout = ack_delayed[1];

    assign dataout = (state == s_read3 && busgrantin) ?
		     dma_dataout : reg_dataout;


    // disk registers
    assign disk_status = { 18'b0, err, 9'b0, disk_interrupt, 2'b0, ~active };

    assign active = state != s_idle;

    assign disk_da = { 1'b0, disk_unit, disk_cyl,
		       3'b0, disk_head, 3'b0, disk_block};


    always @(posedge clk)
      if (reset)
	ack_delayed <= 0;
      else
	begin
	   ack_delayed[0] <= decode && ~ack_delayed[1];
	   ack_delayed[1] <= ack_delayed[0];
	end

    always @(posedge clk)
      if (reset)
	begin
	   disk_cmd <= 0;

	   attn_intr_enb <= 0;
	   done_intr_enb <= 0;

	   reg_dataout = 0;
	end
      else
	begin
	   deassert_int = 0;
	   disk_start = 0;

	if (decode)
	  begin
 `ifdef debug
	     if (debug > 1)
	       $display("disk: decode %b, addrin %o, writein %b",
			decode, addrin, writein);
 `endif
	   if (~writein)
	     begin
		if (addrin[5:3] == 3'o7)
	       case (addrin[2:0])
		 3'o0:
		   begin
		      reg_dataout = disk_status;
 `ifdef debug
		      if (debug != 0 && disk_status != 0) $display("disk: read status %o", disk_status);
 `endif
		   end
		 3'o1: reg_dataout = disk_ma;
		 3'o2: reg_dataout = disk_da;
		 3'o3: reg_dataout = 0;
		 3'o4:
		   begin
		      reg_dataout = disk_status;
 `ifdef debug
		      if (debug != 0 && disk_status != 0) $display("disk: read status %o", disk_status);
 `endif
		   end
		 3'o5: reg_dataout = { 8'b0, 2'b00, disk_clp };
		 3'o6: reg_dataout = disk_da;
		 3'o7: reg_dataout = { 2'b0, wc, bd_state_in, disk_state, state };
	       endcase // case(addrin[2:0])
		else
		  // debug registers
		  if (addrin[5:3] == 3'o6)
		    case (addrin[2:0])
		      3'o0: reg_dataout = 0;
		      3'o1: reg_dataout = 0;
		      3'o2: reg_dataout = 0;
		      3'o3: reg_dataout = 0;
		      3'o4: reg_dataout = 0;
		      3'o5: reg_dataout = { 16'h1234, 16'h5678 };
		      3'o6: reg_dataout = { 8'b0, wc, bd_data_in };
		      3'o7: reg_dataout = { 10'b0, bd_state_in, disk_state, state };
		    endcase
		else
		  begin
 `ifdef debug
		     if (debug != 0) $display("disk: unknown read %o", addrin);
 `endif
		     reg_dataout = 0;
		  end
	    end

	  if (writein)
	    begin
		if (addrin[5:3] == 3'o7)
	       case (addrin[2:0])
		 3'o0, 3'o1, 3'o2, 3'o3:
		   begin
		   end

		 3'o4:
		   begin
 `ifdef debug
		      if (debug != 0) $display("disk: load cmd %o", datain);
 `endif
		      disk_cmd <= datain[9:0];

		      attn_intr_enb <= datain[10];
		      done_intr_enb <= datain[11];

		      if (datain[11:10] != 2'b00)
			deassert_int = 1;
		   end // case: 3'o4

		 3'o5, 3'o6:
		   begin
		   end

		 3'o7:
		   begin
 `ifdef debug
		      if (debug != 0) $display("disk: start!");
 `endif
		      disk_start = 1;
		   end
	       endcase // case(addrin[2:0])
		else
		  begin
 `ifdef debug
		     if (debug != 0) 
		     $display("disk: unknown write %o <- %o", addrin, datain);

 `endif
		  end
	    end
	  end // if (decode)
	end


    always @(posedge clk)
      if (reset)
	begin
	   disk_clp <= 0;

	   disk_unit <= 0;
	   disk_cyl <= 0;
	   disk_head <= 0;
	   disk_block <= 0;
	end
      else
	begin
	if (decode && writein && (addrin[5:0] == 6'o75 || addrin[5:0] == 6'o76))
	  begin
	     if (addrin[2:0] == 3'o5)
	      begin
 `ifdef debug
		 if (debug != 0) $display("disk: load clp %o", datain);
 `endif
		 disk_clp <= datain[21:0];
	      end
	     else
	       if (addrin[2:0] == 3'o6)
		 begin
 `ifdef debug
		    if (debug != 0) $display("disk: load da %o", datain);
 `endif
		    disk_unit <= datain[30:28];
		    disk_cyl <= datain[27:16];
		    disk_head <= datain[12:8];
		    disk_block <= datain[4:0];
		 end
	  end
	else
	  begin
	     // increment disk address by 1 block
	     if (inc_da)
	       begin
	       if (disk_block == DISK_BLOCKS-1)
		 begin
		    disk_block <= 0;

		    if (disk_head == DISK_HEADS-1)
		      begin
			 disk_head <= 0;

			 if (disk_cyl == DISK_CYLS-1)
			   begin
			      disk_cyl <= 0;
			   end
			 else
			   disk_cyl <= disk_cyl + 12'd1;
		      end
		    else
		      disk_head <= disk_head + 5'd1;
		 end
	       else
		 disk_block <= disk_block + 5'd1;

	       end

	     if (inc_clp)
	       disk_clp <= disk_clp + 22'd1;

	  end
	end


    //

    // = (cyl * 323)
    // = (cyl * 320) + cyl + cyl + cyl
    // = (cyl * 32 * 10) + cyl + cyl + cyl
    // = ((cyl * 8) + cyl + cyl) * 32 + cyl + cyl + cyl

    assign cylx10 = { 3'b0, disk_cyl, 3'b0 } +
		    { 6'b0, disk_cyl } + 
		    { 6'b0, disk_cyl };

    // (cyl * blocks/track * heads/unit) = cyl * 323
    assign cyl_blocks = { cylx10, 5'b0 } +
			{ 11'b0, disk_cyl } +
			{ 11'b0, disk_cyl } +
			{ 11'b0, disk_cyl };

    // (head * blocks/track) = head * 17
    assign head_blocks = { disk_head, 4'b0000 } + { 4'b0000, disk_head };

    assign block_number = cyl_blocks +
			  { 14'b0, head_blocks } +
			  { 18'b0, disk_block };


    assign bd_addr = lba;

    // lba = block# * 2
    always @(posedge clk)
      if (reset)
	lba <= 0;
      else
	lba <= { block_number, 1'b0 };
 //   assign lba = { block_number, 1'b0 };

    always @(posedge clk)
      if (reset)
	err <= 1'b0;
      else
	if (clear_err)
	  err <= 1'b0;
	else
	  if (set_err)
	    err <= 1'b1;


    reg [7:0]   wc;

    always @(posedge clk)
      if (reset)
	begin
	   wc <= 8'b0;
	end
      else
	if (clear_wc)
	  wc <= 8'b0;
	else
	  if (inc_wc)
	    wc <= wc + 8'b1;

    // disk state machine
    always @(posedge clk)
      if (reset)
	state <= s_idle;
      else
	begin
	   state <= state_next;
 `ifdef debug
	   if (state_next != 0 && state != state_next && debug > 1)
	     $display("disk: state %d", state_next);
 `endif
	end

    // status to top for led's
    wire disk_state_rd, disk_state_wr;

    assign disk_state_rd = (state == s_read0) || (state == s_read1) || (state == s_read2) || (state == s_read3);
    assign disk_state_wr = (state == s_write0) || (state == s_write1) || (state == s_write2);

    assign disk_state = { 1'b0, err, disk_state_rd, disk_state_wr, active };

    //
    always @(posedge clk)
      if (reset)
	disk_interrupt <= 0;
      else
	   if (assert_int)
	     begin
 `ifdef debug
		if (debug_state != 0) $display("disk: assert interrupt\n");
 `endif
		disk_interrupt <= 1;
	     end
	   else
	     if (deassert_int)
	       begin
		  disk_interrupt <= 0;
 `ifdef debug
		  if (debug_state != 0) $display("disk: deassert interrupt\n");
 `endif
	       end

    reg [31:0] dma_data_hold;
    reg [15:0] disk_data_hold;

    // grab the dma'd data, later used by disk
    always @(posedge clk)
      if (reset)
	dma_data_hold <= 0;
      else
      if (state == s_write0 && busgrantin && ackin)
	begin
	   dma_data_hold <= datain;
 `ifdef debug
	   if (debug != 0)
	   $display("disk: dma_data_hold %x", datain);
 `endif
	end

    // grab the disk data, later used by dma
    always @(posedge clk)
      if (reset)
	disk_data_hold <= 0;
      else
      if ((state == s_read0 || state == s_read1) && bd_iordy)
	begin
	   disk_data_hold <= bd_data_in;
 `ifdef debug
	   if (debug != 0)
	     $display("disk: bd_data_in %x state %d", bd_data_in, state);
 `endif
	end

    //
    always @(posedge clk)
      if (reset)
	begin
	   disk_ccw <= 0;
	   more_ccws <= 0;
	end
      else
	if (state == s_read_ccw && busgrantin && ackin)
	  begin
 `ifdef debug
	     if (debug != 0)
	       $display("disk: grab ccw %o, %t", datain, $time);
 `endif
	     disk_ccw <= datain[21:8];
	     more_ccws <= datain[0];
	  end

    //
    always @(posedge clk)
      if (reset)
	disk_ma <= 0;
      else
	if (state == s_read3 || state == s_write0)
	  disk_ma <= { 10'b0, addrout };

    //
    always @(posedge clk)
      if (reset)
	 addrout <= 0;
      else
	addrout <=
		  state_next == s_read_ccw ? { disk_clp } :
		  state_next == s_read3    ? { disk_ccw, wc } :
		  state_next == s_write0   ? { disk_ccw, wc } :
		  addrout;

    //
    always @(posedge clk)
      if (reset)
	 reqout <= 1'b0;
      else
	 reqout <=
		  state_next == s_read_ccw ? 1'b1 :
		  state_next == s_read3    ? 1'b1 :
		  state_next == s_write0   ? 1'b1 :
		  1'b0;

    //
    always @(posedge clk)
      if (reset)
	busreqout <= 1'b0;
      else
	busreqout <=
		    state_next == s_read_ccw ? 1'b1 :
		    state_next == s_read3    ? 1'b1 :
		    state_next == s_write0   ? 1'b1 :
		    1'b0;

    //
    always @(posedge clk)
      if (reset)
	writeout <= 1'b0;
      else
	writeout <= state_next == s_read3    ? 1'b1 : 1'b0;

    // combinatorial logic based on state
   always @(state or disk_cmd or disk_da or disk_ccw or disk_clp or
	    lba or disk_start or wc or more_ccws or
            bd_bsy or bd_rdy or bd_err or bd_iordy or bd_data_in or disk_data_hold or
	    busgrantin or ackin or dma_data_hold
	    )
      begin
	 state_next = state;

	 assert_int = 0;

	 clear_err = 0;
	 set_err = 0;

	 inc_da = 0;
	 inc_clp = 0;

	 clear_wc = 0;
	 inc_wc = 0;

	 bd_rd = 0;
	 bd_wr = 0;
	 bd_data_out = 0;
	 bd_start = 0;
	 bd_cmd = 0;

	 dma_dataout = 0;

	 case (state)
	   s_idle:
	     if (disk_start)
	       begin
		  case (disk_cmd)
		    DISK_CMD_READ,
		      DISK_CMD_RDCMP:
			begin
			   state_next = s_read_ccw;
			end
		    DISK_CMD_WRITE:
			begin
			   state_next = s_read_ccw;
			end

		    DISK_CMD_RECAL:
		      state_next = s_busy;
		    DISK_CMD_CLEAR:
		      state_next = s_reset;

		    default:
		      begin
 `ifdef debug
			 if (debug != 0) 
			   $display("disk: unhandled command %o", disk_cmd);
			 $finish;
 `endif
		      end
		  endcase
	       end

	   s_busy:
	     begin
		state_next = s_idle;
	     end

	   s_reset:
	     begin
		bd_start = 1;
		bd_cmd = 2'b0;

		if (bd_bsy)
		  state_next = s_reset0;
	     end

	   s_reset0:
	     begin
		if (bd_rdy)
		  state_next = s_busy;
	     end

	   s_read_ccw:
	     begin
		/* busreqout = 1; */
		/* reqout = 1; */
		/* addrout <= disk_clk; */
		if (busgrantin && ackin)
		  state_next = s_read_ccw_done;
	     end

	   s_read_ccw_done:
	     begin
		state_next = s_init0;
	     end

	   s_init0:
	     begin
		bd_start = 1;
		if (disk_cmd == DISK_CMD_WRITE)
		  bd_cmd = 2'b10;
		else
		  if (disk_cmd == DISK_CMD_RDCMP || disk_cmd == DISK_CMD_READ)
		    bd_cmd = 2'b01;

		if (bd_bsy)
		  state_next = s_init1;
	     end

	   s_init1:
	     begin
		if (bd_rdy && bd_err)
		  begin
		     set_err = 1;
		  end

		if (bd_rdy && ~bd_err)
		  begin
		     clear_wc = 1;

		     if (disk_cmd == DISK_CMD_WRITE)
		       state_next = s_write0;
		     else
		     if (disk_cmd == DISK_CMD_READ || disk_cmd == DISK_CMD_RDCMP)
		       state_next = s_read0;
		  end
	     end

	   s_read0:
	     begin
		if (bd_iordy)
		  state_next = s_read1;
	     end

	   s_read1:
	     begin
		bd_rd = 1;
		if (~bd_iordy)
		  state_next = s_read2;
	     end

	   s_read2:
	     begin
		if (bd_iordy)
		  state_next = s_read3;
	     end
	  
	  s_read3:
	    begin
	       // mem write
	       /* busreqout <= 1; */
	       /* reqout <= 1; */
	       /* addrout <= { disk_ccw, wc } */

	       dma_dataout = { bd_data_in, disk_data_hold };
	       
	       /* writeout <= 1; */
	       
	       if (busgrantin && ackin)
		 begin
		    inc_wc = 1;
		    
		    if (wc == 8'hff)
		      state_next = s_last0;
		    else
		      state_next = s_read0;

		    bd_rd = 1;
		 end
	    end

	  s_write0:
	    begin
	       //mem read
	       /* busreqout = 1; */
	       /* reqout = 1; */
	       /* addrout <= { disk_ccw, wc }; */

	       if (busgrantin && ackin)
		 state_next = s_write1;
	    end

	  s_write1:
	    begin
	       bd_wr = 1;
	       bd_data_out = dma_data_hold[15:0];
	       if (bd_iordy)
		 state_next = s_write1a;
	    end

	  s_write1a:
	    if (~bd_iordy)
	      state_next = s_write2;

	  s_write2:
	    begin
	       bd_wr = 1;
	       bd_data_out = dma_data_hold[31:16];

	       if (bd_iordy)
		 begin
		    inc_wc = 1;
		    if (wc == 8'hff)
		      state_next = s_last0;
		    else
		      state_next = s_write2a;
		 end
	    end
	  
	  s_write2a:
	    if (~bd_iordy)
	      state_next = s_write0;

	  s_last0:
	    begin
	       if (bd_rdy)
		 state_next = s_last1;
	    end
	  
	  s_last1:
	    begin
	       if (bd_rdy)
		 begin
		    if (bd_err)
		      set_err = 1;

		    state_next = s_last2;
		 end
	    end

	  s_last2:
	    begin
	       if (more_ccws)
		 begin
		    inc_da = 1;
		    inc_clp = 1;
		    state_next = s_read_ccw;
		 end
	       else
		 state_next = s_done0;
	    end
	
	  s_done0:
	    begin
	       assert_int = 1;
	       
	       clear_err = 1;
	       state_next = s_done1;
	    end

	  s_done1:
	    begin
	       state_next = s_idle;
	    end

	  default:
	    begin
	    end
	  
	endcase
     end

`ifdef debug_with_usim_delay
   integer busy_cycles;
   integer blocks_io;
   integer fetch;
   integer done_waiting;
   
   initial
     begin
	busy_cycles = 0;
	blocks_io = 0;
	fetch = 0;
	done_waiting = 0;
     end
   
   always @(posedge clk)
     begin
	if (state != s_idle && state_next == s_idle)
	  begin
	     $display("xxx: going idle; busy_cycles %d, blocks_io %d",
		      busy_cycles, blocks_io);
	  end
	else
	  if (state == s_idle && state_next != s_idle)
	    begin
	       $display("xxx: going busy");
	       busy_cycles = 0;
	       blocks_io = 0;
	       done_waiting = 0;
	    end
	  else
//	    if (state != s_idle)
	    if (fetch != 0 && state != s_idle)
	      begin
		 busy_cycles = busy_cycles + 1;
		 if (0) $display("xxx: busy_cycles %d; state %d",
				 busy_cycles, state);
		 if (busy_cycles == (1400 * blocks_io)-1)
		   begin
		      done_waiting = 1;
		      $display("xxx: done waiting; state %d", state);
		   end
	      end

	if (state == s_read_ccw_done)
	  blocks_io = blocks_io + 1;
     end
`endif

   // monitor
`ifdef debug
   always @(state or disk_cmd or disk_da or disk_ccw or disk_clp or
	    lba or disk_start or wc or more_ccws or
            bd_bsy or bd_rdy or bd_iordy or bd_data_in or disk_data_hold or
	    busgrantin or ackin or dma_data_hold
	    )
     begin
	if (debug_state != 0)
	  case (state)
	    s_idle:
	      $display("disk: s_idle; go! disk_cmd %o", disk_cmd);

	    s_read_ccw:
	      if (busgrantin && ackin)
		$display("disk: s_read_ccw; dma clp @ %o", disk_clp);

	    s_read_ccw_done:
	      $display("disk: s_read_ccw_done; %t", $time);

	    s_init0: $display("disk: init0");
	    s_init1: $display("disk: init1");

	    s_read3:
	       if (busgrantin && ackin)
		 $display("disk: s_read3; dma_data_out %o (%x), dma_addr %o, wc 0x%x",
			  dma_dataout, dma_dataout, { 10'b0, disk_ccw, wc }, wc);

	    s_write1:
	       if (busgrantin)
		 $display("disk: s_write1; bd_data_out %o, dma_addr %o",
			  bd_data_out, { 10'b0, disk_ccw, wc });

	    s_write2:
	      if (bd_iordy)
		$display("disk: s_write2; wc=%x", wc);

	    s_last0: $display("disk: s_last0");
	    s_last1: $display("disk: s_last1");
	    s_last2: $display("disk: s_last2; more_ccws %b", more_ccws);

	    s_done0: $display("disk: s_done0, interrupt; %t", $time);
	    s_done1: $display("disk: s_done1, da=%o, done", disk_da);
	      
	  endcase
     end
`endif
   
endmodule

