/*
 * $Id: xbus-disk.v 138 2012-08-20 17:53:40Z brad $
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
		  ide_data_in, ide_data_out,
		  ide_dior, ide_diow, ide_cs, ide_da,
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
   
   input [15:0]  ide_data_in;
   output [15:0] ide_data_out;
   output 	 ide_dior;
   output 	 ide_diow;
   output [1:0]  ide_cs;
   output [2:0]  ide_da;
   
   output [4:0]  disk_state;
   
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
	       DISK_CMD_CLEAR = 10'o0405,
	       DISK_CMD_IDE_R = 10'o1333;
	       
   wire 	 addr_match;
   wire 	 decode;
   reg [1:0]	 ack_delayed;

   wire 	 active;
   reg 		 err;
   
   wire [31:0] 	 disk_status;

   // disk state
   parameter [5:0]
		s_idle = 0,
		s_busy = 1,
		s_read_ccw = 2,
		s_read_ccw_done = 3,
		s_init0 = 4,
		s_init1 = 5,
		s_wait0 = 6,
		s_init2 = 7,
		s_init3 = 8,
		s_init4 = 9,
		s_init5 = 10,
		s_init6 = 11,
		s_init7 = 12,
		s_init8 = 13,
		s_init9 = 14,
		s_wait1 = 15,
		s_init10 = 16,
		s_init11 = 17,
		s_read0 = 18,
		s_read1 = 19,
		s_read2 = 20,
		s_write0 = 21,
		s_write1 = 22,
      		s_write2 = 23,
      		s_last0 = 24,
      		s_last1 = 25,
		s_last2 = 26,
      		s_done0 = 27,
      		s_done1 = 28,
		s_reset = 29,
		s_reset0 = 30,
		s_reset1 = 31,
		s_reset2 = 32,
		s_reset3 = 33,
		s_reset4 = 34,
		s_reset5 = 35,
		s_reset6 = 36,
   		s_ide_rd0 = 40,
   		s_ide_rd1 = 41;
		      
   reg [5:0] state;
   reg [5:0] state_next;

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
   
   parameter
       ATA_ALTER   = 5'b01110,
       ATA_DEVCTRL = 5'b01110, /* bit [2] is a nIEN */
       ATA_DATA    = 5'b10000,
       ATA_ERROR   = 5'b10001,
       ATA_FEATURE = 5'b10001,
       ATA_SECCNT  = 5'b10010,
       ATA_SECNUM  = 5'b10011, /* LBA[7:0] */
       ATA_CYLLOW  = 5'b10100, /* LBA[15:8] */
       ATA_CYLHIGH = 5'b10101, /* LBA[23:16] */
       ATA_DRVHEAD = 5'b10110, /* LBA + DRV + LBA[27:24] */
       ATA_STATUS  = 5'b10111,
       ATA_COMMAND = 5'b10111;

   parameter
       IDE_STATUS_BSY =  7,
       IDE_STATUS_DRDY = 6,
       IDE_STATUS_DWF =  5,
       IDE_STATUS_DSC =  4,
       IDE_STATUS_DRQ =  3,
       IDE_STATUS_CORR = 2,
       IDE_STATUS_IDX =  1,
       IDE_STATUS_ERR =  0;
   
   parameter
       ATA_CMD_READ = 16'h0020,
       ATA_CMD_WRITE = 16'h0030;

   reg 	    ata_rd;
   reg 	    ata_wr;
   reg [4:0] ata_addr;
   reg [15:0] ata_in;
   wire [15:0] ata_out;
   wire        ata_done;

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

   reg [15:0] dbg_ide_reg;
   reg [15:0] dbg_ide_data;
   
`ifdef debug
   integer debug/* verilator public_flat */;

   initial
     debug = 1;
`endif
   
   // -----------------------------------------------------------------
   

   assign interrupt = done_intr_enb & disk_interrupt;
   

   // bus address
   assign addr_match = { addrin[21:6], 6'b0 } == 22'o17377700 ?
		       1'b1 : 1'b0;
   
   assign decode = (reqin && addr_match) ? 1'b1 : 1'b0;

   assign decodeout = decode;
   assign ackout = ack_delayed[1];

   assign dataout = (state == s_read2 && busgrantin) ?
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

	  dbg_ide_reg <= 0;
       end
     else
       begin
	  deassert_int = 0;
	  disk_start = 0;

       if (decode)
	 begin
`ifdef debug_xxx
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
		     if (debug != 0) $display("disk: read status %o", disk_status);
`endif
		  end
		3'o1: reg_dataout = disk_ma;
		3'o2: reg_dataout = disk_da;
		3'o3: reg_dataout = { 8'h12, 3'b000, dbg_ide_reg[4:0], dbg_ide_data };
		3'o4:
		  begin
		     reg_dataout = disk_status;
`ifdef debug
		     if (debug != 0) $display("disk: read status %o", disk_status);
`endif
		  end
		3'o5: reg_dataout = { 8'b0, 2'b00, disk_clp };
		3'o6: reg_dataout = disk_da;
		3'o7: reg_dataout = 0;
	      endcase // case(addrin[2:0])
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
		3'o0, 3'o1, 3'o2:
		  begin
		  end

		3'o3:
		  begin
		     dbg_ide_reg <= datain[15:0];
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
   ide ide(.clk(clk), .reset(reset),
	   .ata_rd(ata_rd), .ata_wr(ata_wr), .ata_addr(ata_addr),
	   .ata_in(ata_in), .ata_out(ata_out), .ata_done(ata_done),
	   .ide_data_in(ide_data_in), .ide_data_out(ide_data_out),
	   .ide_dior(ide_dior), .ide_diow(ide_diow),
	   .ide_cs(ide_cs), .ide_da(ide_da));

   
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
`ifdef debug_state
	  if (state_next != 0 && state != state_next)
	    $display("disk: state %d", state_next);
`endif
       end

   assign disk_state = state[4:0];
   
   always @(posedge clk)
     if (reset)
       disk_interrupt <= 0;
     else
	  if (assert_int)
	    begin
`ifdef debug_state
	       $display("disk: assert interrupt\n");
`endif
	       disk_interrupt <= 1;
	    end
	  else
	    if (deassert_int)
	      begin
		 disk_interrupt <= 0;
`ifdef debug_state
		 $display("disk: deassert interrupt\n");
`endif
	      end

   reg [31:0] dma_data_hold;
   reg [15:0] ata_hold;
   
   // grab the dma'd data, later used by ide
   always @(posedge clk)
     if (reset)
       dma_data_hold <= 0;
     else
     if (state == s_write0 && busgrantin && ackin)
       dma_data_hold <= datain;

   // grab the ide data, later used by dma
   always @(posedge clk)
     if (reset)
       ata_hold <= 0;
     else
     if (state == s_read0 && ata_done)
       ata_hold <= ata_out;

   always @(posedge clk)
     if (reset)
       dbg_ide_data <= 16'ha55a;
     else
       if (state == s_ide_rd0 && ata_done)
	 dbg_ide_data <= ata_out;
   
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
	    if (debug != 0) $display("disk: grab ccw %o, %t", datain, $time);
`endif
	    disk_ccw <= datain[21:8];
	    more_ccws <= datain[0];
	 end

   //
   always @(posedge clk)
     if (reset)
       disk_ma <= 0;
     else
       if (state == s_read2 || state == s_write0)
	 disk_ma <= { 10'b0, addrout };

   //
   always @(posedge clk)
     if (reset)
   	addrout <= 0;
     else
       addrout <=
		 state_next == s_read_ccw ? { disk_clp } :
		 state_next == s_read2    ? { disk_ccw, wc } :
		 state_next == s_write0   ? { disk_ccw, wc } :
		 addrout;

   //
   always @(posedge clk)
     if (reset)
   	reqout <= 0;
     else
   	reqout <=
		 state_next == s_read_ccw ? 1 :
		 state_next == s_read2    ? 1 :
		 state_next == s_write0   ? 1 :
		 0;

   //
   always @(posedge clk)
     if (reset)
       busreqout <= 0;
     else
       busreqout <=
		   state_next == s_read_ccw ? 1 :
		   state_next == s_read2    ? 1 :
		   state_next == s_write0   ? 1 :
		   0;

   //
   always @(posedge clk)
     if (reset)
       writeout <= 0;
     else
       writeout <= state_next == s_read2    ? 1 : 0;
   
   // combinatorial logic based on state
   always @(state or disk_cmd or disk_da or disk_ccw or disk_clp or
	    lba or disk_start or wc or more_ccws or
            ata_done or ata_out or ata_hold or
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

	ata_rd = 0;
	ata_wr = 0;
	ata_addr = 0;
	ata_in = 0;

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

		   DISK_CMD_IDE_R:
		     state_next = s_ide_rd0;
		     
		   default:
		     begin
`ifdef debug
			if (debug != 0) 
			$display("disk: unhandled command %o", disk_cmd);
			$finish;
`endif
		     end
		 endcase
`ifdef debug
		 if (debug != 0) 
		 $display("disk: go! disk_cmd %o", disk_cmd);
`endif
	      end

	  s_busy:
	    begin
	       state_next = s_idle;
	    end
	  
	  s_reset:
	    begin
	       ata_wr = 1;
	       ata_addr = ATA_DRVHEAD;
	       ata_in = 16'h0040;
	       if (ata_done)
		 state_next = s_reset0;
	    end

	  s_reset0:
	    begin
	       ata_wr = 1;
	       ata_addr = ATA_SECNUM;
	       ata_in = 16'b0;
	       if (ata_done)
		 state_next = s_reset1;
	    end

	  s_reset1:
	    begin
	       ata_wr = 1;
	       ata_addr = ATA_CYLLOW;
	       ata_in = 16'b0;
	       if (ata_done)
		 state_next = s_reset2;
	    end

	  s_reset2:
	    begin
	       ata_wr = 1;
	       ata_addr = ATA_CYLHIGH;
	       ata_in = 16'b0;
	       if (ata_done)
		 state_next = s_reset3;
	    end

	  s_reset3:
	    begin
	       ata_wr = 1;
	       ata_addr = ATA_COMMAND;
	       ata_in = 16'h0070;
	       if (ata_done)
		 state_next = s_reset4;
	    end
	    
	  s_reset4:
	    begin
	       ata_rd = 1;
	       ata_addr = ATA_STATUS;
	       if (ata_done && ~ata_out[IDE_STATUS_BSY])
		 state_next = s_reset5;
	    end
	  
	  s_reset5:
	    begin
	       ata_wr = 1;
	       ata_addr = ATA_DEVCTRL;
	       ata_in = 16'h0002;
	       if (ata_done)
		 state_next = s_reset6;
	    end
	  
	  s_reset6:
	    begin
	       ata_rd = 1;
	       ata_addr = ATA_STATUS;
	       if (ata_done && ~ata_out[IDE_STATUS_BSY])
		 state_next = s_busy;
	    end
	  
	  s_read_ccw:
	    begin
	       /* busreqout = 1; */
	       /* reqout = 1; */
	       /* addrout <= disk_clk; */
	       
`ifdef debug_disk
	       $display("disk: dma clp @ %o", disk_clp);
`endif

	       if (busgrantin && ackin)
		 state_next = s_read_ccw_done;
	    end

	  s_read_ccw_done:
	    state_next = s_init0;

	  s_init0:
	    begin
	       ata_addr = ATA_STATUS;
	       ata_rd = 1;
	       if (ata_done &&
		   ~ata_out[IDE_STATUS_BSY] &&
		   ata_out[IDE_STATUS_DRDY])
		 state_next = s_init1;
`ifdef debug_disk
	       if (ata_done)
		 $display("disk: s_init0, status %x; %t", ata_out, $time);
`endif
	    end

	  s_init1:
	    begin
`ifdef debug_disk
	       $display("disk: init1");
`endif
	       ata_wr = 1;
	       ata_addr = ATA_DRVHEAD;
	       ata_in = 16'h00e0/*16'h0040*/;
	       if (ata_done)
		 state_next = s_wait0;
	    end

	  s_wait0:
	    begin
	       state_next = s_init2;
	    end

	  s_init2:
	    begin
	       ata_addr = ATA_STATUS;
	       ata_rd = 1;
	       if (ata_done &&
		   ~ata_out[IDE_STATUS_BSY] &&
		   ata_out[IDE_STATUS_DRDY])
		 state_next = s_init3;
	    end

	  s_init3:
	    begin
	       ata_wr = 1;
	       ata_addr = ATA_DEVCTRL;
	       ata_in = 16'h0002;		// nIEN
	       if (ata_done)
		 state_next = s_init4;
	    end
	  
	  s_init4:
	    begin
	       ata_wr = 1;
	       ata_addr = ATA_SECCNT;
	       ata_in = 16'd2;
	       if (ata_done)
		 state_next = s_init5;
	    end
	  
	  s_init5:
	    begin
`ifdef debug
	       if (debug != 0) 
	       $display("disk: da %o (unit%d cyl%d head%d block%d) lba %d",
			disk_da,
			disk_unit, disk_cyl, disk_head, disk_block,
			lba);
	       
`endif
	       ata_wr = 1;
	       ata_addr = ATA_SECNUM;
	       ata_in = {8'b0, lba[7:0]};	// LBA[7:0]
	       if (ata_done)
		 state_next = s_init6;
	    end

	  s_init6:
	    begin
	       ata_wr = 1;
	       ata_addr = ATA_CYLLOW;
	       ata_in = {8'b0, lba[15:8]};	// LBA[15:8]
	       if (ata_done)
		 state_next = s_init7;
	    end

	  
	  s_init7:
	    begin
	       ata_wr = 1;
	       ata_addr = ATA_CYLHIGH;
	       ata_in = {8'b0, lba[23:16]};	// LBA[23:16]
	       if (ata_done)
		 state_next = s_init8;
	    end

	  s_init8:
	    begin
//	       ata_wr = 1;
//	       ata_addr = ATA_DRVHEAD;
//	       ata_in = 16'h00e0/*16'h0040*/;		// LBA[27:24] + LBA
//	       if (ata_done)
		 state_next = s_init9;
	    end

	  s_init9:
	    begin
	       ata_wr = 1;
	       ata_addr = ATA_COMMAND;
	       ata_in = disk_cmd == DISK_CMD_WRITE ? ATA_CMD_WRITE :
			disk_cmd == DISK_CMD_RDCMP ? ATA_CMD_READ :
			disk_cmd == DISK_CMD_READ  ? ATA_CMD_READ : 16'b0;
	       if (ata_done)
		 state_next = s_wait1;
	    end

	  s_wait1:
	    begin
	       state_next = s_init10;
	    end
	  
	  s_init10:
	    begin
	       ata_rd = 1;
	       ata_addr = ATA_ALTER;
	       if (ata_done)
		 state_next = s_init11;
	    end
	  
	  s_init11:
	    begin
	       ata_rd = 1;
	       ata_addr = ATA_STATUS;

	       if (ata_done && ata_out[IDE_STATUS_ERR])
		 begin
		    set_err = 1;
		 end
	       
	       if (ata_done && ~ata_out[IDE_STATUS_BSY])
		 begin
		    clear_wc = 1;
		    
//		    if (disk_cmd == DISK_CMD_WRITE)
//		      state_next = s_write0;
//		    else
//		    if ((disk_cmd == DISK_CMD_READ ||
//			 disk_cmd == DISK_CMD_RDCMP) && ata_out[IDE_STATUS_DRQ])
//		      state_next = s_read0;

		    if (disk_cmd == DISK_CMD_WRITE && ata_done && ata_out[IDE_STATUS_DRQ])
		      state_next = s_write0;
		    else
		    if ((disk_cmd == DISK_CMD_READ ||
			 disk_cmd == DISK_CMD_RDCMP) && ata_done && ata_out[IDE_STATUS_DRQ])
		      state_next = s_read0;
		 end
	    end

	  s_read0:
	    begin
	       ata_rd = 1;
	       ata_addr = ATA_DATA;
	       if (ata_done)
		 state_next = s_read1;
	    end
	  
	  s_read1:
	    begin
	       ata_rd = 1;
	       ata_addr = ATA_DATA;
	       if (ata_done)
		 begin
		    state_next = s_read2;
		 end
	    end
	  
	  s_read2:
	    begin
	       // mem write
	       /* busreqout <= 1; */
	       /* reqout <= 1; */
	       /* addrout <= { disk_ccw, wc } */

	       dma_dataout = { ata_out, ata_hold };
	       
	       /* writeout <= 1; */
	       
`ifdef debug_disk
	       if (busgrantin) $display("s_read2: ata_out %o, dma_addr %o",
			       ata_out, { 10'b0, disk_ccw, wc });
`endif
			    
	       if (busgrantin && ackin)
		 begin
		    inc_wc = 1;
		    
		    if (wc == 8'hff)
		      state_next = s_last0;
		    else
		      state_next = s_read0;
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
	       ata_wr = 1;
	       ata_addr = ATA_DATA;
	       ata_in = dma_data_hold[15:0];

	       if (ata_done)
		 begin
		    state_next = s_write2;
		 end
	    end

	  s_write2:
	    begin
	       ata_wr = 1;
	       ata_addr = ATA_DATA;
	       ata_in = dma_data_hold[31:16];

	       if (ata_done)
		 begin
		    inc_wc = 1;
		    if (wc == 8'hff)
		      state_next = s_last0;
		    else
		      state_next = s_write0;
		 end
	    end
	  
	  s_last0:
	    begin
	       ata_rd = 1;
	       ata_addr = ATA_ALTER;
	       if (ata_done)
		 state_next = s_last1;
	    end
	  
	  s_last1:
	    begin
	       ata_rd = 1;
	       ata_addr = ATA_STATUS;

	       if (ata_done)
		 begin
		    if (ata_out[IDE_STATUS_ERR])
		      set_err = 1;

		    state_next = s_last2;
		 end
	    end

	  s_last2:
	    begin
`ifdef debug_disk
	       $display("disk: s_last2; more_ccws %b", more_ccws);
`endif
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
`ifdef debug
	       if (debug != 0) $display("disk: s_done0, interrupt; %t", $time);
`endif
	       
	       clear_err = 1;
	       state_next = s_done1;
	    end

	  s_done1:
	    begin
	       state_next = s_idle;
`ifdef debug
	       if (debug != 0) $display("disk: s_done1, da=%o, done", disk_da);
`endif
	    end

	  s_ide_rd0:
	    begin
	       ata_rd = 1;
	       ata_addr = dbg_ide_reg[4:0];

	       if (ata_done)
		 state_next = s_ide_rd1;
	    end
		 
	  s_ide_rd1:
	    state_next = s_idle;
		 
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
   
endmodule

