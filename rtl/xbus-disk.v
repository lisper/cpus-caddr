/*
 * $Id$
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
	  00 read
	  10 read compare
	  11 write
	  02 read all
	  13 write all
	  04 seek
	  05 at ease
	  1005 recalibreate
	  405 fault clear
	  06 offset clear
	  16 stop,reset

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

	  CLP (command list pointer) points to list of CCW's
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


*/
  
module xbus_disk (
		  reset,
		  clk,
		  addrin,
		  addrout,
		  datain,
		  dataout,
		  reqin,
		  reqout,
		  grantin,
		  ackout,
		  writein,
		  writeout,
		  decodein,
		  decodeout,
		  interrupt
		);

   input reset;
   input clk;
   input [21:0] addrin;		/* request address */
   input [31:0] datain;		/* request data */
   input 	reqin;		/* request */
   input 	grantin;	/* grant from bus arbiter */
   input 	writein;	/* request read#/write */
   input 	decodein;	/* decode ok from bus arbiter */
   
   output [21:0] addrout;
   output [31:0] dataout;
   reg [31:0] 	 dataout;
   output 	 reqout;
   output 	 ackout;	/* request done */
   output 	 writeout;
   output 	 decodeout;	/* request addr ok */
   output 	 interrupt;
 	 
   //
   reg [31:0] 	 disk_ma, disk_da, disk_ecc;
   reg [11:0] 	 disk_cmd;
 	 
   wire 	 addr_match;
   wire 	 decode;
   reg 		 ack_delayed;

   wire 	 active;
   
   //
   assign 	 addr_match = { addrin[21:3], 3'b0 } == 22'o17377770 ?
			      1'b1 : 1'b0;
   
   assign 	 decode = (reqin && addr_match) ? 1'b1 : 1'b0;

   assign 	 decodeout = decode;
   assign 	 ackout = ack_delayed;

   always @(posedge clk)
     if (reset)
       ack_delayed <= 0;
     else
       ack_delayed <= decode;

   assign reqout = 0;
   assign writeout = 0;
   assign interrupt = 0;
   
   always @(posedge clk)
     if (reset)
       begin
          disk_cmd <= 0;
          disk_ma <= 0;
          disk_da <= 0;
          disk_ecc <= 0;
	  dataout <= 0;
       end
     else
       if (decode)
	 begin
`ifdef debug_xxx
	    $display("disk: decode %b, addrin %o, writein %b", decode, addrin, writein);
`endif
	  if (~writein)
	    begin
	      case (addrin[2:0])
		3'o0, 3'o4:
		  begin
		     dataout <= { 28'b0, interrupt, 2'b0, active };
		     $display("disk: read status %o", { 28'b0, interrupt, 2'b0, active });
		  end
		3'o5: dataout <= disk_ma;
		3'o6: dataout <= disk_da;
		3'o7: dataout <= disk_ecc;
	      endcase
	   end

	 if (writein)
	   begin
	      case (addrin[2:0])
		3'o4:
		  begin
		     $display("disk: load cmd %o", datain);
		     disk_cmd <= datain;
		  end
		3'o5:
		  begin
		     $display("disk: load clp %o", datain);
		     disk_ma <= datain;
		  end
		3'o6:
		  begin
		     $display("disk: load da %o", datain);
		     disk_da <= datain;
		  end
		3'o7:
		  begin
		     $display("disk: start!");
		     //disk_ecc <= datain;
		  end
	      endcase
	   end
      end

   reg [4:0] state;
   
   assign active = state == 0;
   
   always @(posedge clk or posedge reset)
     if (reset)
       state <= 0;
     else
       state = next_state;

   wire [4:0] next_state;

   assign next_state =
		      0;
   
endmodule

