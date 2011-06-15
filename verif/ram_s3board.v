//
// // simulate IS61LV25616AL-10T on s3board
// debug only
//

//`define use_dpi_ram
//`define debug_ram_low
//`define debug_s3ram

`ifndef use_dpi_ram
module ram_256kx16(addr, in, out, ce_n, ub_n, lb_n, we_n, oe_n);
   input [17:0] addr;
   input [15:0] in;
   output [15:0] out;
   input 	ce_n;
   input 	ub_n;
   input 	lb_n;
   input 	we_n;
   input 	oe_n;

   reg [7:0] ram_h[262143:0];
   reg [7:0] ram_l[262143:0];

   assign out = { (oe_n | ub_n) ? 8'b0 : ram_h[addr],
		  (oe_n | lb_n) ? 8'b0 : ram_l[addr] };

   always @(we_n or ce_n or ub_n or lb_n or addr or in)
     if (~we_n && ~ce_n)
       begin
	  if (0)
	    $display("ram_256kx16: %t ce_n %b ub_n %b lb_n %b we_n %b oe_n %b",
		     $time, ce_n, ub_n, lb_n, we_n, oe_n);
		   
`ifdef debug_ram_low
	  if (~ub_n && ~lb_n) $display("ram_256kx16: %t write %o <- %o",
				       $time, addr, in);
	  else
	    if (~ub_n) $display("ram_256kx16: writeh %o <- %o", addr, in);
	    else
	      if (~lb_n) $display("ram_256kx16: writel %o <- %o", addr, in);
`endif
	  
	  if (~ub_n) ram_h[addr] = in[15:8];
	  if (~lb_n) ram_l[addr] = in[7:0];
       end

`ifdef debug_ram_low
   always @(we_n or ce_n or ub_n or lb_n or addr or in)
     if (we_n && ~ce_n)
       begin
	  if (0)
	    $display("ram_256kx16: %t ce_n %b ub_n %b lb_n %b we_n %b oe_n %b",
		     $time, ce_n, ub_n, lb_n, we_n, oe_n);

	  if (~ub_n && ~lb_n) $display("ram_256kx16: read %o -> %o", addr, out);
	  else
	    if (~ub_n) $display("ram_256kx16: readh %o -> %o", addr, out[7:0]);
	    else
	      if (~lb_n) $display("ram_256kx16: readl %o -> %o", addr, out[7:0]);
       end
`endif

endmodule
`endif //  `ifdef never

`ifdef use_dpi_ram
module ram_256kx16(addr, in, out, ce_n, ub_n, lb_n, we_n, oe_n);
   input [17:0] addr;
   input [15:0] in;
   output [15:0] out;
   input 	ce_n;
   input 	ub_n;
   input 	lb_n;
   input 	we_n;
   input 	oe_n;

   import "DPI-C" function void dpi_ram(input integer a,
					input integer r,
					input integer w,
					input integer u,
					input integer l,
					input integer in,
					output integer out);

      integer a, r, w, u, l, l_in, l_out;
      
      assign l_out = (oe_n | ub_n) ? 16'b0 : out[15:0];
      assign l_in[15:0] = in;

      assign a = { 14'b0, addr };
      assign r = ( we_n && ~ce_n) ? 1 : 0;
      assign w = (~we_n && ~ce_n) ? 1 : 0;      
      assign u = ub_n ? 0 : 1;
      assign l = lb_n ? 0 : 1;
      
      always @(a or r or w or u or l or l_in or l_out)
	begin
	   dpi_ram(a, r, w, u, l, l_in, l_out);
	end
   
endmodule // ram_256kx16
`endif //  `ifdef use_dpi_ram

module ram_s3board(ram_a, ram_oe_n, ram_we_n,
		   ram1_in, ram1_out, ram1_ce_n, ram1_ub_n, ram1_lb_n,
		   ram2_in, ram2_out, ram2_ce_n, ram2_ub_n, ram2_lb_n);
		   
   input [17:0] ram_a;
   input 	ram_oe_n, ram_we_n;
   input [15:0]  ram1_in;
   output [15:0] ram1_out;
   input [15:0]  ram2_in;
   output [15:0] ram2_out;
   input 	ram1_ce_n, ram1_ub_n, ram1_lb_n;
   input 	ram2_ce_n, ram2_ub_n, ram2_lb_n;

   // synthesis translate_off
   integer 	 i;
   reg [15:0] 	 v;
   reg [63:0] file;
   reg [1023:0]  str;
   reg [1023:0]  testfilename;
   integer 	 n;

`ifndef use_dpi_ram
   initial
     begin
	$display("ram_s3board.v: init ram array");
	for (i = 0; i < 262143/*131072*//*8192*/; i=i+1)
	  begin
             ram1.ram_h[i] = 8'b0;
	     ram1.ram_l[i] = 8'b0;
             ram2.ram_h[i] = 8'b0;
	     ram2.ram_l[i] = 8'b0;
	  end

	n = 0;
	v = 0;
	
`ifdef verilator
 `define no_scan
`endif

`ifdef __ICARUS__
       n = $value$plusargs("test=%s", testfilename);
`endif
       
`ifdef __CVER__
       n = $scan$plusargs("test=", testfilename);
`endif

`ifdef xxx
	if (n == 0)
	  begin
	     testfilename = "ram.mem";
	     $display("ram_s3board: using default ram file");
	     n = 1;
	  end
	
	if (n > 0)
	  begin
	     $display("ram_s3board: code filename: %0s", testfilename);
	     file = $fopen(testfilename, "r");

	     if (file != 0)
	       begin
		  while ($fscanf(file, "%o %o\n", i, v) > 0)
		    begin
		       //$display("ram_s3board[%0o] <- %o", i, v);
		       ram1.ram_h[i] = v[15:8];
		       ram1.ram_l[i] = v[7:0];
		    end

		  $fclose(file);
	       end
	  end
`endif
     end
`endif
   
`ifdef debug_s3ram
   always @(ram_a or ram_oe_n or ram1_ce_n or ram_we_n or ram1_in)
     begin
	if (0)
	  $display("ram_s3board: ce_n %b ub_n %b lb_n %b we_n %b oe_n %b",
		   ram1_ce_n, ram1_ub_n, ram1_lb_n, ram_we_n, ram_oe_n);

	if (ram_oe_n == 0 && ram_we_n == 1)
	  $display("ram_s3board: read1  [%o] -> %o %t", ram_a, ram1_out, $time);
	if (ram_oe_n == 1 && ram_we_n == 0)
	  $display("ram_s3board: write1 [%o] <- %o %t", ram_a, ram1_in, $time);
     end

   always @(ram_a or ram_oe_n or ram2_ce_n or ram_we_n or ram2_in)
     begin
	if (ram_oe_n == 0 && ram_we_n == 1)
	  $display("ram_s3board: read2  [%o] -> %o %t", ram_a, ram2_out, $time);
	if (ram_oe_n == 1 && ram_we_n == 0)
	  $display("ram_s3board: write2 [%o] <- %o %t", ram_a, ram2_in, $time);
     end
`endif

   // synthesis translate_on

   ram_256kx16 ram1(.addr(ram_a), .in(ram1_in), .out(ram1_out),
		    .ce_n(ram1_ce_n), .ub_n(ram1_ub_n), .lb_n(ram1_lb_n),
		    .we_n(ram_we_n), .oe_n(ram_oe_n));

   ram_256kx16 ram2(.addr(ram_a), .in(ram2_in), .out(ram2_out),
		    .ce_n(ram2_ce_n), .ub_n(ram2_ub_n), .lb_n(ram2_lb_n),
		    .we_n(ram_we_n), .oe_n(ram_oe_n));


endmodule
