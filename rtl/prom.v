/*
 * $Id$
 */

`define ROM_DELAY 10

/* dmask prom */

module part_32x8prom ( clk, addr, q );

   input clk;
   input [4:0] addr;
   output [7:0] q;
   reg [7:0] 	q;

  always @(posedge clk)
    case (addr)
     5'h00: q = 8'h00;
     5'h01: q = 8'h01;
     5'h02: q = 8'h03;
     5'h03: q = 8'h07;
     5'h04: q = 8'h0f;
     5'h05: q = 8'h1f;
     5'h06: q = 8'h3f;
     5'h07: q = 8'h7f;
     default: q = 8'h00;
    endcase
endmodule

/* left mask prom */

module part_32x32prom_maskleft( clk, addr, q );

   input clk;
   input [4:0] addr;
   output [31:0] q;
   reg [31:0] 	 q;

  always @(posedge clk)
    case (addr)
      5'h00: q = 32'h00000001;
      5'h01: q = 32'h00000003;
      5'h02: q = 32'h00000007;
      5'h03: q = 32'h0000000f;
      5'h04: q = 32'h0000001f;
      5'h05: q = 32'h0000003f;
      5'h06: q = 32'h0000007f;
      5'h07: q = 32'h000000ff;
      5'h08: q = 32'h000001ff;
      5'h09: q = 32'h000003ff;
      5'h0a: q = 32'h000007ff;
      5'h0b: q = 32'h00000fff;
      5'h0c: q = 32'h00001fff;
      5'h0d: q = 32'h00003fff;
      5'h0e: q = 32'h00007fff;
      5'h0f: q = 32'h0000ffff;
      5'h10: q = 32'h0001ffff;
      5'h11: q = 32'h0003ffff;
      5'h12: q = 32'h0007ffff;
      5'h13: q = 32'h000fffff;
      5'h14: q = 32'h001fffff;
      5'h15: q = 32'h003fffff;
      5'h16: q = 32'h007fffff;
      5'h17: q = 32'h00ffffff;
      5'h18: q = 32'h01ffffff;
      5'h19: q = 32'h03ffffff;
      5'h1a: q = 32'h07ffffff;
      5'h1b: q = 32'h0fffffff;
      5'h1c: q = 32'h1fffffff;
      5'h1d: q = 32'h3fffffff;
      5'h1e: q = 32'h7fffffff;
      5'h1f: q = 32'hffffffff;
  endcase

endmodule

/* right mask prom */

module part_32x32prom_maskright( clk, addr, q );

   input clk;
   input [4:0] addr;
   output [31:0] q;
   reg [31:0] 	 q;

  always @(posedge clk)
    case (addr)
      5'h00: q = 32'hffffffff;
      5'h01: q = 32'hfffffffe;
      5'h02: q = 32'hfffffffc;
      5'h03: q = 32'hfffffff8;
      5'h04: q = 32'hfffffff0;
      5'h05: q = 32'hffffffe0;
      5'h06: q = 32'hffffffc0;
      5'h07: q = 32'hffffff80;
      5'h08: q = 32'hffffff00;
      5'h09: q = 32'hfffffe00;
      5'h0a: q = 32'hfffffc00;
      5'h0b: q = 32'hfffff800;
      5'h0c: q = 32'hfffff000;
      5'h0d: q = 32'hffffe000;
      5'h0e: q = 32'hffffc000;
      5'h0f: q = 32'hffff8000;
      5'h10: q = 32'hffff0000;
      5'h11: q = 32'hfffe0000;
      5'h12: q = 32'hfffc0000;
      5'h13: q = 32'hfff80000;
      5'h14: q = 32'hfff00000;
      5'h15: q = 32'hffe00000;
      5'h16: q = 32'hffc00000;
      5'h17: q = 32'hff800000;
      5'h18: q = 32'hff000000;
      5'h19: q = 32'hfe000000;
      5'h1a: q = 32'hfc000000;
      5'h1b: q = 32'hf8000000;
      5'h1c: q = 32'hf0000000;
      5'h1d: q = 32'he0000000;
      5'h1e: q = 32'hc0000000;
      5'h1f: q = 32'h80000000;
    endcase

endmodule

