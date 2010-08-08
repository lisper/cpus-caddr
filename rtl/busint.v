/*
 * busint.v
 * $Id$
 *
 * caddr bus interface
 * interface to peripherals
 * does basic arbitration; allows disk to be a bus master
 *
 * 22 bit address space
 *   00000000-
 *   16777777  dram
 *
 *   17000000-
 *   17377777  xbus
 * 
 *   17400000-
 *   17777777  unibus
 *
 * ------------------------
 *
 * xbus:
 *   17000000- tv frame buffer
 *   17051777
 *
 *   17200000  tv color frame buffer
 *
 *   17377760 tv
 *   17377770 disk
 *
 *   17740000 unknown
 *
 *   17772000 i/o board
 *   17773000 unibus
 *
 *   17777700 unknown
 *
 * unibus:
 *   17400000  color?
 *   17760000  tv
 *
 *   17764000-
 *   17764077  i/o board
 *   17764140 chaos
 *
 *   17766000-
 *   17766036  spy
 *
 *   17766012 mode register
 *
 *   17766040 unibus int status
 *   17766044 unibus err status
 *
 *   17766100-
 *   17766110  two machine lashup
 *
 *   17766140-
 *   17766176  unibus map
 * 
 * ------------------------
 * 
 */

module busint(mclk, reset,
	      addr, busin, busout, spyin, spyout,
	      req, ack, write, load,
	      interrupt,

	      sdram_addr, sdram_data_in, sdram_data_out,
	      sdram_req, sdram_ready, sdram_write, sdram_done,

	      vram_addr, vram_data_in, vram_data_out,
	      vram_req, vram_ready, vram_write, vram_done,

	      ide_data_in, ide_data_out, ide_dior, ide_diow, ide_cs, ide_da,

	      promdisable);

   input mclk;
   input reset;
   input [21:0] addr;

   input [31:0] busin;
   input [15:0] spyin;
   
   output [31:0] busout;
   output [15:0] spyout;

   input 	 req, write;
   output 	 ack, load, interrupt;
   
   input [15:0]  ide_data_in;
   output [15:0] ide_data_out;
   output 	 ide_dior;
   output 	 ide_diow;
   output [1:0]  ide_cs;
   output [2:0]  ide_da;

   output 	 promdisable;
   
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
   
   //
   parameter 	 BUS_IDLE  = 4'b0000,
 		   BUS_REQ   = 4'b0001,
 		   BUS_WAIT  = 4'b0010,
 		   BUS_SLAVE = 4'b0100,
    		   BUS_SWAIT = 4'b1000;

   reg [3:0] 	state;
   wire [3:0] 	next_state;

   reg [4:0] 	timeout_count;
 	
   //
   wire 	decode_ok;
   wire 	decode_dram, decode_disk, decode_tv, decode_io, decode_unibus;

   wire 	ack;
   wire 	ack_dram, ack_disk, ack_tv, ack_io, ack_unibus;

   wire 	interrupt;
   wire 	interrupt_disk, interrupt_tv, interrupt_io, interrupt_unibus;
   
   wire 	busreqout_disk;
   wire 	busgrantin_disk;

   wire 	dram_reqin;
   wire 	dram_writein;

   wire [21:0] 	dram_addr;
   wire [31:0] 	dram_datain;
   wire [31:0] 	disk_datain;

   wire [31:0] 	dataout_dram;
   wire [31:0] 	dataout_disk;
   wire [31:0] 	dataout_tv;
   wire [31:0] 	dataout_io;
   wire [31:0] 	dataout_unibus;

   
   wire [21:0] 	addrout_disk;
   
   wire 	device_ack;

   wire 	timed_out;

   wire [7:0] 	vector;

   xbus_ram dram (
		  .clk(mclk),
		  .reset(reset),
		  .addr(dram_addr),
		  .datain(dram_datain),
		  .dataout(dataout_dram),
		  .req(dram_reqin),
		  .write(dram_writein),
		  .ack(ack_dram),
		  .decode(decode_dram),

		  .sdram_addr(sdram_addr),
		  .sdram_data_in(sdram_data_in),
		  .sdram_data_out(sdram_data_out),
		  .sdram_req(sdram_req),
		  .sdram_ready(sdram_ready),
		  .sdram_write(sdram_write),
		  .sdram_done(sdram_done)
		  );


   wire 	ackin_disk;
   wire 	writeout_disk;
   wire 	reqout_disk;
   wire 	decodein_disk;
   
   xbus_disk disk (
		   .reset(reset),
		   .clk(mclk),

		   .addrin(addr),
		   .datain(disk_datain),
		   .dataout(dataout_disk),
		   .reqin(req),
		   .writein(write),
		   .ackout(ack_disk),
		   .decodeout(decode_disk),
		   .interrupt(interrupt_disk),

	   .busreqout(busreqout_disk),
	   .busgrantin(busgrantin_disk),
		   .addrout(addrout_disk),
		   .reqout(reqout_disk),
	   .ackin(ackin_disk),
		   .writeout(writeout_disk),
		   .decodein(decodein_disk),

		   .ide_data_in(ide_data_in),
		   .ide_data_out(ide_data_out),
		   .ide_dior(ide_dior),
		   .ide_diow(ide_diow),
		   .ide_cs(ide_cs),
		   .ide_da(ide_da)
		  );

   xbus_tv tv (
	       .clk(mclk),
	       .reset(reset),
	       .addr(addr),
	       .datain(busin),
	       .dataout(dataout_tv),
	       .req(req),
	       .write(write),
	       .ack(ack_tv),
	       .decode(decode_tv),
	       .interrupt(interrupt_tv),

	       .vram_addr(vram_addr),
	       .vram_data_in(vram_data_in),
	       .vram_data_out(vram_data_out),
	       .vram_req(vram_req),
	       .vram_ready(vram_ready),
	       .vram_write(vram_write),
	       .vram_done(vram_done)
	       );

   xbus_io io (
	       .clk(mclk),
	       .reset(reset),
	       .addr(addr),
	       .datain(busin),
	       .dataout(dataout_io),
	       .req(req),
	       .write(write),
	       .ack(ack_io),
	       .decode(decode_io),
	       .interrupt(interrupt_io),
	       .vector(vector)
	       );

   xbus_unibus unibus (
		       .reset(reset),
		       .clk(mclk),
		       .addr(addr),
		       .datain(busin),
		       .dataout(dataout_unibus),
		       .req(req),
		       .write(write),
		       .ack(ack_unibus),
		       .decode(decode_unibus),
		       .interrupt(interrupt_unibus),
		       .promdisable(promdisable),
		       .timeout(timed_out)
		       );

   assign decode_ok = decode_dram | decode_disk | decode_tv |
		      decode_io | decode_unibus;
   
   
   assign device_ack = ack_dram | ack_disk | ack_tv | ack_io | ack_unibus |
		       timed_out;
   
   assign ack = state == BUS_REQ && device_ack;

   // disk - xbus
   // iob, 60hz clock - xbus
   // iob - unibus
   assign interrupt = interrupt_disk | interrupt_tv |
		      interrupt_io | interrupt_unibus;
   

   //
   assign busout =
		  (req & decode_dram & ~write) ? dataout_dram :
		  (req & decode_disk & ~write) ? dataout_disk :
		  (req & decode_tv & ~write) ? dataout_tv :
		  (req & decode_io & ~write) ? dataout_io :
		  (req & decode_unibus & ~write) ? dataout_unibus :
		  (req & timed_out & ~write) ? 32'h00000000 :
		  32'hffffffff;

`ifdef debug_xbus
  always @(posedge mclk)
    begin
       if (req)
	 if (write)
	   begin
              `DBG_DLY $display("xbus: write @%o <- %o; %t",
				addr, busin, $time);
	   end
	 else
	   begin
              `DBG_DLY $display("xbus: read @%o -> %o; %t",
				addr, busout, $time);
	   end
    end
`endif

   // bus control state machine
   always @ (posedge mclk)
     if (reset)
       begin
	  state <= BUS_IDLE;
       end
     else
       begin
	  state <= next_state;

`ifdef debug_detail
	  if (next_state != state)
	    begin
	       case (next_state)
		 BUS_REQ:   $display("busint: BUS_REQ   addr %o; %t",
				     dram_addr, $time);
		 BUS_WAIT:  $display("busint: BUS_WAIT  addr %o; %t",
				     dram_addr, $time);
		 BUS_SLAVE: $display("busint: BUS_SLAVE addr %o; %t",
				     dram_addr, $time);
		 BUS_IDLE:  $display("busint: BUS_IDLE  addr %o; %t",
				     dram_addr, $time);
		 default:   $display("busint: ??");
	       endcase
	    end

	  if (next_state == BUS_REQ)
	    $display("busint: REQ req %b write %b decode_dram %b",
		     req, write, decode_dram);

	  if (next_state == BUS_REQ)
	    $display("busint: REQ req %b dram_reqin %b dram_writein %b",
		     req, dram_reqin, dram_writein);

	  if (next_state == BUS_REQ)
	    $display("busint: REQ req %b ack %b; acks %b %b %b %b %b",
		     req, device_ack, 
		     ack_dram, ack_disk, ack_tv, ack_io, ack_unibus);

	  if (next_state == BUS_WAIT)
	    $display("busint: WAIT req %b ack %b; acks %b %b %b %b %b",
		     req, device_ack, 
		     ack_dram, ack_disk, ack_tv, ack_io, ack_unibus);

	  if (next_state == BUS_SLAVE)
	    begin
	       $display("busint: BUS_SLAVE addr %o; %t", dram_addr, $time);

	       $display("busint: slave req %b ack %b; ack_dram %b",
			req, device_ack, ack_dram);
	    end
`endif

       end

   // basic bus arbiter
   assign next_state =
		      (state == BUS_IDLE && req) ? BUS_REQ :
		      (state == BUS_IDLE && busreqout_disk) ? BUS_SLAVE :
		      (state == BUS_REQ && device_ack) ? BUS_WAIT :
		      (state == BUS_REQ && ~device_ack) ? BUS_REQ :
		      (state == BUS_WAIT && ~req) ? BUS_IDLE :
		      (state == BUS_WAIT && req) ? BUS_WAIT :
//		      (state == BUS_SLAVE && ack_dram) ? BUS_IDLE :
      		      (state == BUS_SLAVE && ack_dram) ? BUS_SWAIT :
		      (state == BUS_SLAVE && ~ack_dram) ? BUS_SLAVE :
      		      (state == BUS_SWAIT && busreqout_disk) ? BUS_SWAIT :
		      (state == BUS_SWAIT && ~busreqout_disk) ? BUS_IDLE :
		      BUS_IDLE;
		      
   assign busgrantin_disk = state == BUS_SLAVE;
   assign load = req & ~write & (state == BUS_WAIT);

   // allow disk to drive dram
   assign dram_addr = state == BUS_SLAVE ? addrout_disk : addr;
   assign dram_reqin = state == BUS_SLAVE ? reqout_disk : (req && state == BUS_REQ);
   assign dram_writein = state == BUS_SLAVE ? writeout_disk : (write && state == BUS_REQ);
   assign dram_datain = state == BUS_SLAVE ? dataout_disk : busin;

   assign disk_datain = state == BUS_SLAVE ? dataout_dram : busin;
   assign decodein_disk = busgrantin_disk & decode_dram;
   assign ackin_disk = busgrantin_disk & ack_dram;
   

   // bus timeout
   always @(posedge mclk)
     if (reset)
       timeout_count <= 0;
     else
       if (state == BUS_REQ && ~timed_out)
	 timeout_count <= timeout_count + 5'd1;
       else
	 if (state == BUS_WAIT)
	   timeout_count <= 0;

   assign timed_out = timeout_count == 5'b11111;

`ifdef debug
   always @(posedge mclk)
     if (timed_out)
       $display("busint: timeout; addr %o; %t", addr, $time);
`endif

   assign spyout = 16'b0;
   
endmodule
     
