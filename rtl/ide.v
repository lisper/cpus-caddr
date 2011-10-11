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

   reg [2:0] ata_state;

   parameter [2:0]
		s0 = 3'd0,
		s1 = 3'd1,
		s2 = 3'd2,
		s3 = 3'd3,
   		s4 = 3'd4,
   		s5 = 3'd5;

   wire [2:0] ata_state_next;

   parameter [4:0]
//`ifdef SIMULATION
//		ATA_DELAY = 2;
//`else
//		ATA_DELAY = 14;
//`endif
		ATA_DELAY = 20;
     
   reg [4:0] ata_count;
   
   wire      assert_cs;
   wire      assert_rw;

   wire      ide_start, ide_busy, ide_stop;

   // register ide data from drive
   reg [15:0] reg_ide_data_in;
   reg [15:0] reg_ata_in;

   assign c_cs = ata_addr[4:3];
   assign c_da = ata_addr[2:0];
   assign c_dior = ata_rd ? 1'b0 : 1'b1;
   assign c_diow = ata_wr ? 1'b0 : 1'b1;

   // send back done pulse at end
   assign ata_done = ata_state == s3;
   
   always @(posedge clk)
     if (reset)
       ata_state <= s0;
     else
       ata_state <= ata_state_next;

   assign ata_state_next =
			  (ata_state == s0 && (ata_rd || ata_wr)) ? s1 :
			  (ata_state == s1) ? s2 :
			  (ata_state == s2 && ata_count == ATA_DELAY) ? s3 :
			  (ata_state == s3) ? s0 :
//			  (ata_state == s3) ? s4 :
//			  (ata_state == s4) ? s0 :
			  ata_state;

   
   assign ide_start = ata_state == s1;
   assign ide_busy = ata_state == s2;
   assign ide_stop = ata_state == s3;
   
   always @(posedge clk)
     if (reset)
       reg_ata_in <= 0;
     else
       if (ide_start)
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
       if (ide_start)
	 begin
	    ide_cs <= c_cs;
	    ide_da <= c_da;
	    ide_data_out <= ata_in;
	 end
       else
	 if (ide_stop)
	   begin
	      ide_dior <= 1'b1;
	      ide_diow <= 1'b1;
	      ide_cs <= 2'b11;
	      ide_da <= 3'b111;
	   end
	 else
	   if (ide_busy)
	     begin
		if (ata_count == 0)
		  begin
		     ide_dior <= c_dior;
		     ide_diow <= c_diow;
		  end
		
		reg_ide_data_in <= ide_data_in;
	     end

endmodule // ide
