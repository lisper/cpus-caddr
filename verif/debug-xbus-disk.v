/*
 * $Id$
 */

/*
 * generate continuoue dma traffic 
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
   
   // disk state
   parameter s_idle = 0,
	       s_init = 1,
	       s_read0 = 2,
	       s_read1 = 3,
	       s_read2 = 4,
	       s_write0 = 5,
	       s_write1 = 6,
      	       s_write2 = 7,
      	       s_last = 8,
      	       s_done = 9;
		      
   reg [4:0] state;
   reg [4:0] state_next;

   assign    interrupt = 0;

   reg [7:0] wc;
   reg 	     clear_wc;
   reg 	     inc_wc;
   
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

   assign disk_state = state;

   reg [31:0] dma_dataout;

   assign dataout = (state == s_read2 && busgrantin) ?
		    dma_dataout : 0;
   
   reg [31:0] dma_data_hold;
   
   // grab the dma'd data, later used by ide
   always @(posedge clk)
     if (reset)
       dma_data_hold <= 0;
     else
     if (state == s_write0 && busgrantin && ackin)
       dma_data_hold <= datain;

   reg 	      direction;
   wire       switch_direction;
   
   always @(posedge clk)
     if (reset)
       direction <= 0;
     else
       if (switch_direction)
	 direction <= ~direction;
       
   // combinatorial logic based on state
   always @(state or wc or busgrantin or ackin or dma_data_hold)
     begin
	state_next = state;

	switch_direction = 0;
	
	clear_wc = 0;
	inc_wc = 0;

	busreqout = 0;
	reqout = 0;
	writeout = 0;
	addrout = 0;
	dma_dataout = 0;

	case (state)
	  s_idle:
	    begin
	       state_next = s_init;
	    end

	  s_init:
	    begin
	       clear_wc = 1;
`ifdef debug
	       $display("disk: s_init, direction %b", direction);
`endif
	       if (direction)
		 state_next = s_read0;
	       else
		 state_next = s_write0;
	    end

	  s_read0:
	    begin
	       state_next = s_read1;
	    end
	  
	  s_read1:
	    begin
	       state_next = s_read2;
	    end
	  
	  s_read2:
	    begin
	       // mem write
	       busreqout = 1;
	       reqout = 1;
	       addrout = { 14'h0010, wc };

	       dma_dataout = { wc, wc, wc, wc };
	       
	       writeout = 1;
	       
`ifdef debug_disk
	       if (busgrantin) $display("s_read2: dma_addr %o", { 14'b0, wc });
`endif
			    
	       if (busgrantin && ackin)
		 begin
		    inc_wc = 1;
		    
		    if (wc == 8'hff)
		      state_next = s_last;
		    else
		      state_next = s_read0;
		 end
	    end

	  s_write0:
	    begin
	       //mem read
	       busreqout = 1;
	       reqout = 1;
	       addrout = { 14'h0010, wc };
	       
	       if (busgrantin && ackin)
		 state_next = s_write1;
	    end

	  s_write1:
	    begin
	       state_next = s_write2;
	    end

	  s_write2:
	    begin
	       inc_wc = 1;
	       if (wc == 8'hff)
		 state_next = s_last;
	       else
		 state_next = s_write0;
	    end
	  
	  s_last:
	    begin
		 state_next = s_done;
	    end
	  
	  s_done:
	    begin
	       switch_direction = 1;
	       state_next = s_idle;
`ifdef debug
	       $display("disk: s_done");
`endif
	    end
		 
	  default:
	    begin
	    end
	  
	endcase
     end

endmodule

