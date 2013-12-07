//
// ide_block_dev.v
// $Id$
//

//`define debug
//`define debug_state

module ide_block_dev(clk, reset,
		     bd_cmd, bd_start, bd_bsy, bd_rdy, bd_err, bd_addr,
		     bd_data_in, bd_data_out, bd_rd, bd_wr, bd_iordy,
		     ide_data_in, ide_data_out, ide_dior, ide_diow, ide_cs, ide_da
		     );

   input clk;
   input reset;

   input [1:0] bd_cmd;
   input       bd_start;
   output      bd_bsy;
   output      bd_rdy;
   output      bd_err;
   input [23:0] bd_addr;
   input [15:0] bd_data_in;
   output [15:0] bd_data_out;
   input 	 bd_rd;
   input 	 bd_wr;
   output 	 bd_iordy;

   input [15:0]  ide_data_in;
   output [15:0] ide_data_out;
   output 	 ide_dior;
   output 	 ide_diow;
   output [1:0]  ide_cs;
   output [2:0]  ide_da;

`ifdef debug
   integer debug/* verilator public_flat */;

   initial
     debug = 1;
`endif
   
   /* generic block device interface */

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

   reg        clear_err;
   reg        set_err;
   reg        clear_wc;
   reg        inc_wc;

   wire [23:0] lba;
   
   // disk state
   parameter [5:0]
		s_idle = 0,
		s_busy = 1,
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
		s_write0 = 21,
		s_write1 = 22,
      		s_last0 = 24,
      		s_last1 = 25,
      		s_done0 = 27,
		s_reset = 29,
		s_reset0 = 30,
		s_reset1 = 31,
		s_reset2 = 32,
		s_reset3 = 33,
		s_reset4 = 34,
		s_reset5 = 35,
		s_reset6 = 36;

   reg [5:0] state;
   reg [5:0] state_next;

   reg [1:0] bd_cmd_hold;
   reg 	     err;
   
   //
   ide ide(.clk(clk), .reset(reset),
	   .ata_rd(ata_rd), .ata_wr(ata_wr), .ata_addr(ata_addr),
	   .ata_in(ata_in), .ata_out(ata_out), .ata_done(ata_done),
	   .ide_data_in(ide_data_in), .ide_data_out(ide_data_out),
	   .ide_dior(ide_dior), .ide_diow(ide_diow),
	   .ide_cs(ide_cs), .ide_da(ide_da));

   //
   assign bd_iordy = (state == s_read1) ||
		     (state == s_write1 && ata_done);

   assign bd_rdy =
		  (state == s_idle) ||
		  (state == s_read0) || (state == s_read1) ||
		  (state == s_write0) || (state == s_write1) ||
		  (state == s_done0);

   //
   reg [15:0] data_hold;
   reg [15:0] ata_hold;
   
   // grab the dma'd data, later used by ide
   always @(posedge clk)
     if (reset)
       data_hold <= 0;
     else
     if (state == s_write0 && bd_wr)
       data_hold <= bd_data_in;

   // grab the ide data, later used by dma
   always @(posedge clk)
     if (reset)
       ata_hold <= 0;
     else
     if (state == s_read0 && ata_done)
       ata_hold <= ata_out;

   assign bd_data_out = ata_hold;

   // word cound
   reg [8:0]   wc;
   
   always @(posedge clk)
     if (reset)
       begin
	  wc <= 9'b0;
       end
     else
       if (clear_wc)
	 wc <= 9'b0;
       else
	 if (inc_wc)
	   wc <= wc + 9'b1;

   //
   assign bd_bsy = state != s_idle ? 1'b1 : 1'b0;
   assign bd_err = err;
   assign lba = bd_addr;

   //
   reg [1:0] r_bd_cmd;
   reg 	     r_bd_start;
   
   always @(posedge clk)
     if (reset)
       begin
	  r_bd_cmd <= 0;
	  r_bd_start <= 0;
       end
     else
       begin
	  r_bd_cmd <= bd_cmd;
	  r_bd_start <= bd_start;
       end

   //   
   always @(posedge clk)
     if (reset)
       bd_cmd_hold <= 0;
     else
       if (bd_start)
	 bd_cmd_hold <= bd_cmd;

   always @(posedge clk)
     if (reset)
       err <= 1'b0;
     else
       if (clear_err)
	 err <= 1'b0;
       else
	 if (set_err)
	   err <= 1'b1;

   // disk state machine
   always @(posedge clk)
     if (reset)
       state <= s_idle;
     else
       begin
	  state <= state_next;
`ifdef debug_state
	  if (state_next != 0 && state != state_next)
	    $display("ide_block_dev: state %d", state_next);
`endif
       end

   // combinatorial logic based on state
   always @(state or r_bd_cmd or bd_cmd_hold or r_bd_start or bd_rd or bd_wr or ata_done or ata_out or ata_hold)
     begin
	state_next = state;

	ata_rd = 0;
	ata_wr = 0;
	ata_addr = 0;
	ata_in = 0;

	clear_wc = 0;
	inc_wc = 0;

	case (state)
	  s_idle:
	    begin
	       if (r_bd_start)
		 begin
		    case (r_bd_cmd)
		      2'b00:
			begin
			   state_next = s_reset;
			end
		      2'b01:
			begin
			   state_next = s_init0;
			end
		      2'b10:
			begin
			   state_next = s_init0;
			end
		      2'b11:
			;
		    endcase
`ifdef debug
		    if (debug != 0) 
		      $display("ide_block_dev: bd_start! bd_cmd %b", r_bd_cmd);
`endif
		 end
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
		 $display("ide_block_dev: s_init0, status %x; %t", ata_out, $time);
`endif
	    end

	  s_init1:
	    begin
`ifdef debug_disk
	       $display("ide_block_dev: s_init1");
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
	       $display("ide_block_dev: lba %d", lba);
	       
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
	       ata_in = bd_cmd_hold == 2'b10 ? ATA_CMD_WRITE :
			bd_cmd_hold == 2'b01 ? ATA_CMD_READ :
			16'b0;
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
		    
		    if (bd_cmd_hold == 2'b10 && ata_done && ata_out[IDE_STATUS_DRQ])
		      state_next = s_write0;
		    else
		    if (bd_cmd_hold == 2'b01 && ata_done && ata_out[IDE_STATUS_DRQ])
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
	       if (bd_rd)
		 begin
		    inc_wc = 1;
		    if (wc == 9'h1ff)
		      state_next = s_last0;
		    else
		      state_next = s_read0;
		 end
	    end

	  s_write0:
	    begin
	       if (bd_wr)
		 state_next = s_write1;
	    end

	  s_write1:
	    begin
	       ata_wr = 1;
	       ata_addr = ATA_DATA;
	       ata_in = data_hold;

	       if (ata_done)
		 begin
		    inc_wc = 1;
		    if (wc == 9'h1ff)
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

		    state_next = s_done0;
		 end
	    end

	  s_done0:
	    begin
`ifdef debug
	       $display("ide_block_dev: s_done0");
`endif
	       state_next = s_idle;
	       clear_err = 1;
	    end
	
	  default:
	    begin
	    end
	  
	endcase
     end

   
endmodule // ide_block_dev
