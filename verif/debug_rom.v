/* boot prom */

module part_512x49prom( clk, addr, q );

   input clk;
   input [8:0] addr;
   output [48:0] q;
   reg [48:0] 	 q;

   // synthesis translate_off
   integer 	 i;
   reg [7:0] 	 ch1, ch2;
   reg [48:0] 	 v;
   reg [63:0] 	 file;
   reg [1023:0]  str;
   reg [1023:0]  memfilename;
   reg [1023:0]  patchfilename;
   reg [1023:0]  line;
   integer 	 n1, n2;
   integer 	 r1, r2;

   reg [48:0] 	 rom[511:0];

   reg [8:0] 	 inv_a;
   
   initial
   begin
      for (i = 0; i < 512; i = i + 1)
	rom[i] = 0;

`ifdef __CVER__
      n1 = $scan$plusargs("rom=", memfilename);
      n2 = $scan$plusargs("patch=", patchfilename);
`else
      n1 = $value$plusargs("rom=%s", memfilename);
      n2 = $value$plusargs("patch=%s", patchfilename);
`endif
     
      $display("n1 %d n2 %d", n1, n2);
 
      if (n1 == 0)
	begin
	   $display("using default mem file");

	   memfilename = "bootrom.mem";
	   n1 = 1;
	end

      if (n2 == 0)
	begin
	   patchfilename = "patch-bootrom.mem";
	   n2 = 1;
	end

      if (n1 > 0)
	begin
	   $display("debug_rom: rom filename: %0s", memfilename);
	   file = $fopen(memfilename, "r");

	   if (file != 0)
	     begin
		// skip first 1 line but notice 2nd line's 1st char
		ch1 = $fgetc(file);
		r1 = $fgets(line, file);
		ch2 = $fgetc(file);
		r2 = $fgets(line, file);
		
		if (ch2 == 104)
		  while ($fscanf(file, "%x %x\n", i, v) > 0)
		    begin
		       rom[i] = v;
		       //$display("hex %o %o", i, v);
		    end
		else
		  while ($fscanf(file, "%o %o\n", i, v) > 0)
		    begin
		       rom[i] = v;
		       //$display("oct %o %o", i, v);
		    end

		$fclose(file);
		$display("debug_rom: rom read");
	     end
	end

      if (n2 > 0)
	begin
	   $display("debug_rom: patch filename: %0s", patchfilename);
	   file = $fopen(patchfilename, "r");

	   if (file != 0)
	     begin
		ch1 = $fgetc(file);
		r1 = $fgets(line, file);
		ch2 = $fgetc(file);
		r2 = $fgets(line, file);

		if (ch2 == 104)
		  while ($fscanf(file, "%x %x\n", i, v) > 0)
		    begin
		       inv_a = ~i[8:0];
		       rom[inv_a] = v;
		       $display("patch hex %0o %o", i, v);
		    end
		else
		  while ($fscanf(file, "%o %o\n", i, v) > 0)
		    begin
		       inv_a = ~i[8:0];
		       rom[inv_a] = v;
		       $display("patch oct %0o %o", i, v);
		    end
		$fclose(file);
		$display("debug_rom: patch read");
	     end
	end

   end
      
  always @(posedge clk)
    begin
       q <= rom[addr];
    end
   
`ifdef debug_prom
  always @(posedge clk)
    $display("prom: prom[%o] -> %o; %t", addr, q, $time);
`endif
  
endmodule


