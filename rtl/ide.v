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
   reg [15:0] 	 ata_out;
   output 	 ata_done;

   input [15:0]  ide_data_in;
   output [15:0] ide_data_out;
   output 	 ide_dior;
   output 	 ide_diow;
   output [1:0]  ide_cs;
   output [2:0]  ide_da;

   
   reg [2:0] ata_state;

   parameter [2:0]
		s0 = 3'd0,
		s1 = 3'd1,
		s2 = 3'd2,
		s3 = 3'd3,
   		s4 = 3'd4,
   		s5 = 3'd5;

   parameter [3:0]
`ifdef SIMULATION
		ATA_DELAY = 1;
`else
		ATA_DELAY = 15;
`endif
     
   reg [3:0] ata_count;
   
   wire      assert_cs;
   wire      assert_rw;

   wire [2:0] ata_state_next;

   reg [15:0] ide_data_in_reg;

   //
   always @(posedge clk)
     if (reset)
       ide_data_in_reg <= 0;
     else
       ide_data_in_reg <= ide_data_in;
  
   // if write, drive ide_bus
   reg [15:0] 	 reg_ata_in;

   always @(posedge clk)
     reg_ata_in <= ata_in;
   
   assign ide_data_out = (ata_wr && (ata_state != s0)) ? reg_ata_in : 16'b0;
   
   // assert cs & da during r/w cycle
   assign assert_cs = (ata_rd || ata_wr) && ata_state != s0;
   
   assign ide_cs = assert_cs ? ata_addr[4:3] : 2'b11;
   assign ide_da = assert_cs ? ata_addr[2:0] : 3'b111;

   // assert r/w one cycle sort
   assign assert_rw = ata_state == s2;

   assign ide_dior = (assert_rw && ata_rd) ? 1'b0 : 1'b1;
   assign ide_diow = (assert_rw && ata_wr) ? 1'b0 : 1'b1;

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
			  (ata_state == s3) ? s4 :
			  (ata_state == s4) ? s5 :
			  (ata_state == s5) ? s0 :
			  ata_state;
   
   always @(posedge clk)
     if (reset)
       ata_count <= 0;
     else
       if (ata_state == s1)
	 ata_count <= 0;
       else
	 if (ata_state == s2)
	   ata_count <= ata_count + 1;
   
   always @(posedge clk)
     if (reset)
       ata_out <= 0;
     else
       if (ata_state == s2 && ata_rd)
	 ata_out <= ide_data_in_reg;

endmodule // ide
