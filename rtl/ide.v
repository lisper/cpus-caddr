//
// ide.v
// simple state machine to do proper read & write cycles to ATA IDE device
//

`include "defines.vh"

module ide(clk, reset, ata_rd, ata_wr, ata_addr, ata_in, ata_out, ata_done,
	   ide_data_in, ide_data_out, ide_dior, ide_diow, ide_cs, ide_da);

   input clk;
   input reset;
   
   input ata_rd;
   input ata_wr;
   input [4:0]   ata_addr;
   input [15:0]  ata_in;

   output [15:0] ata_out;
   output 	 ata_done;

   input [15:0]  ide_data_in;
   output [15:0] ide_data_out;

   output 	 ide_dior;
   output 	 ide_diow;
   output [1:0]  ide_cs;
   output [2:0]  ide_da;

   reg [15:0] 	 ide_data_out;
   reg 		 ide_dior;
   reg 		 ide_diow;
   reg [1:0] 	 ide_cs;
   reg [2:0] 	 ide_da;
   
   //
   wire 	 c_dior;
   wire 	 c_diow;
   wire [1:0] 	 c_cs;
   wire [2:0] 	 c_da;

   reg [3:0] ata_state;

   parameter [3:0]
		s0 = 4'd0,
		s1 = 4'd1,
		s2 = 4'd2,
		s3 = 4'd3,
   		s4 = 4'd4,
   		s5 = 4'd5,
   		s6 = 4'd6,
   		s7 = 4'd7,
   		s8 = 4'd8,
   		s9 = 4'd9;

   wire [3:0] ata_state_next;

   parameter [5:0]
//`ifdef SIMULATION
//		ATA_DELAY = 2;
//`else
		ATA_DELAY = 10;
//`endif
     
   reg [5:0] ata_count;
   
   wire      assert_cs;
   wire      assert_rw;

   wire      ide_begin, ide_start, ide_busy, ide_stop, ide_end;

   // register ide data from drive
   reg [15:0] reg_ide_data_in;
   reg [15:0] reg_ata_in;

   assign c_cs = ata_addr[4:3];
   assign c_da = ata_addr[2:0];
   assign c_dior = ata_rd ? 1'b0 : 1'b1;
   assign c_diow = ata_wr ? 1'b0 : 1'b1;

   always @(posedge clk)
     if (reset)
       ata_state <= s0;
     else
       ata_state <= ata_state_next;

   assign ata_state_next =
			  (ata_state == s0 && (ata_rd || ata_wr)) ? s1 :
			  (ata_state == s1) ? s2 :
			  (ata_state == s2 && ata_count == ATA_DELAY) ? s3 :
			  (ata_state == s3) ? s4 :
			  (ata_state == s4) ? s5 :
			  (ata_state == s5) ? s6 :
			  (ata_state == s6) ? s7 :
			  (ata_state == s7) ? s8 :
			  (ata_state == s8) ? s9 :
			  (ata_state == s9) ? s0 :
			  ata_state;
   
   assign ide_begin = ata_state == s0 && (ata_rd || ata_wr);
   assign ide_start = ata_state == s1;
   assign ide_busy  = ata_state == s2;
   assign ide_stop  = ata_state == s3;
   assign ide_end   = ata_state == s4;
   
   // send back done pulse when data valid
   assign ata_done = ata_state == s3;
   
   always @(posedge clk)
     if (reset)
       reg_ata_in <= 0;
     else
       if (ata_state == s0 && (ata_rd || ata_wr))
	 reg_ata_in <= ata_in;
   
   assign ata_out = reg_ide_data_in;

   always @(posedge clk)
     if (reset)
       ata_count <= 0;
     else
       if (ata_state == s1)
	 ata_count <= 0;
       else
	 if (ata_state == s2)
	   ata_count <= ata_count + 1;
   
   /* register all the ide signals */
   always @(posedge clk)
     if (reset)
       begin
	  ide_dior <= 1'b1;
	  ide_diow <= 1'b1;
	  ide_cs <= 2'b11;
	  ide_da <= 3'b111;
	  ide_data_out <= 0;
	  reg_ide_data_in <= 0;
       end
     else
       if (ide_begin)
	 begin
	    ide_cs <= c_cs;
	    ide_da <= c_da;
	    ide_data_out <= ata_in;
	 end
       else
	 if (ide_start)
	   begin
	      ide_dior <= c_dior;
	      ide_diow <= c_diow;
	   end
	 else
	 if (ide_stop)
	   begin
	      ide_dior <= 1'b1;
	      ide_diow <= 1'b1;
	   end
	 else
	   if (ide_end)
	     begin
		ide_cs <= 2'b11;
		ide_da <= 3'b111;
	     end
	   else
	     if (ide_busy)
	       begin
		  reg_ide_data_in <= ide_data_in;
	       end

endmodule // ide
