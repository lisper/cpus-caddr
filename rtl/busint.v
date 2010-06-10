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
 *   17377760 tv
 *   17377770 disk
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
	      addr, busin, busout, spy, 
	      req, ack, write, load,
	      interrupt,
	      ide_data_bus, ide_dior, ide_diow, ide_cs, ide_da);

   input mclk;
   input reset;
   input [21:0] addr;
   input [31:0] busin;
   inout [15:0] spy;
   
   output [31:0] busout;
   input 	 req, write;
   output 	 ack, load, interrupt;
   
   inout [15:0] ide_data_bus;
   output 	ide_dior;
   output 	ide_diow;
   output [1:0] ide_cs;
   output [2:0] ide_da;

   //
   parameter 	 BUS_IDLE  = 4'b0000,
 		   BUS_REQ   = 4'b0001,
 		   BUS_WAIT  = 4'b0010,
 		   BUS_SLAVE = 4'b0100;

   reg [3:0] 	state;
   wire [3:0] 	next_state;
   
   //
   wire 	decode_ok;
   wire 	decode_dram, decode_disk, decode_tv, decode_io, decode_unibus;

   wire 	ack;
   wire 	ack_dram, ack_disk, ack_tv, ack_io, ack_unibus;

   wire 	interrupt;
   wire 	interrupt_disk, interrupt_tv, interrupt_io, interrupt_unibus;
   
   wire 	grantin_disk;
   wire 	dram_reqin;
   wire 	dram_writein;

   wire [21:0] 	dram_addr;
   wire [31:0] 	dram_datain;
   wire [31:0] 	disk_datain;

   xbus_ram dram (
		  .reset(reset),
		  .clk(mclk),
		  .addr(dram_addr),
		  .datain(dram_datain),
		  .dataout(dataout_dram),
		  .req(dram_reqin),
		  .write(dram_writein),
		  .ack(ack_dram),
		  .decode(decode_dram)
		  );

   xbus_disk disk (
		   .reset(reset),
		   .clk(mclk),
		   .addrin(addr),
		   .addrout(addrout_disk),
		   .datain(datain_disk),
		   .dataout(dataout_disk),
		   .reqin(req),
		   .reqout(reqout_disk),
		   .grantin(grantin_disk),
		   .ackout(ack_disk),
		   .writein(write),
		   .writeout(writeout_disk),
		   .decodein(decodein_disk),
		   .decodeout(decode_disk),
		   .interrupt(interrupt_disk),
		   .ide_data_bus(ide_data_bus),
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
	       .interrupt(interrupt_tv)
	       );

   xbus_io io (
	       .reset(reset),
	       .clk(mclk),
	       .addr(addr),
	       .datain(busin),
	       .dataout(dataout_io),
	       .req(req),
	       .write(write),
	       .ack(ack_io),
	       .decode(decode_io),
	       .interrupt(interrupt_io)
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
	       .interrupt(interrupt_unibus)
	       );

   assign 	decode_ok = decode_dram | decode_disk | decode_tv |
			    decode_io | decode_unibus;
   
   assign 	ack = decode_ok &
		      (ack_dram | ack_disk | ack_tv | ack_io | ack_unibus);
   
   assign 	interrupt = interrupt_disk | interrupt_tv |
			    interrupt_io | interrupt_unibus;
   

   //
   assign busout =
		  (req & decode_dram & ~write) ? dataout_dram :
		  (req & decode_disk & ~write) ? dataout_disk :
		  (req & decode_tv & ~write) ? dataout_tv :
		  (req & decode_io & ~write) ? dataout_io :
		  32'hffffffff;
   
  always @(posedge mclk)
    begin
       if (req)
	 if (write)
	   begin
              #1 $display("xbus: write @%o, %t", addr, $time);
	   end
	 else
	   begin
              #1 $display("xbus: read @%o, %t", addr, $time);
	   end
    end

   //
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
		 BUS_REQ:   $display("%t BUS_REQ   addr %o", $time, dram_addr);
		 BUS_WAIT:  $display("%t BUS_WAIT  addr %o", $time, dram_addr);
		 BUS_SLAVE: $display("%t BUS_SLAVE addr %o", $time, dram_addr);
		 BUS_IDLE:  $display("%t BUS_IDLE  addr %o", $time, dram_addr);
	       endcase
	    end
`endif
       end

   // basic bus arbiter
   assign next_state =
		      (state == BUS_IDLE && req) ? BUS_REQ :
		      (state == BUS_IDLE && reqout_disk) ? BUS_SLAVE :
		      (state == BUS_REQ && ack) ? BUS_WAIT :
		      (state == BUS_REQ && ~req) ? BUS_IDLE :		      
		      (state == BUS_WAIT && ~req) ? BUS_IDLE :
		      (state == BUS_WAIT && req) ? BUS_WAIT :
		      (state == BUS_SLAVE && ack_dram) ? BUS_IDLE :
		      (state == BUS_SLAVE && ~ack_dram) ? BUS_SLAVE :
		      BUS_IDLE;
		      
   assign grantin_disk = state == BUS_SLAVE && next_state == BUS_IDLE;
   assign load = state == BUS_WAIT;

   // allow disk to drive dram
   assign dram_addr = state == BUS_SLAVE ? addrout_disk : addr;
   assign dram_reqin = state == BUS_SLAVE ? reqout_disk : req;
   assign dram_writein = state == BUS_SLAVE ? writeout_disk : write;
   assign dram_datain = state == BUS_SLAVE ? dataout_disk : busin;

   assign datain_disk = state == BUS_SLAVE ? dataout_dram : busin;
   assign decodein_disk = grantin_disk & decode_dram;
   
endmodule
     
