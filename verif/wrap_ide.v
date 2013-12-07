module wrap_ide(clk, ide_data_in, ide_data_out,
		ide_dior, ide_diow, ide_cs, ide_da);

   input clk;
   input [15:0]  ide_data_in;
   output [15:0] ide_data_out;
   input 	 ide_dior;
   input 	 ide_diow;
   input [1:0] 	 ide_cs;
   input [2:0] 	 ide_da;
		
   import "DPI-C" function void dpi_ide(input integer data_in,
					output integer data_out,
				        input integer dior,
				        input integer diow,
				        input integer cs,
				        input integer da);

   integer dbi, dbo;
   wire [31:0] dboo;
      
   assign dbi = {16'b0, ide_data_in};
   assign dboo = dbo;

   assign ide_data_out = dboo[15:0];

   always @(posedge clk)
     begin
	dpi_ide(dbi,
		dbo,
		{31'b0, ide_dior}, 
		{31'b0, ide_diow},
		{30'b0, ide_cs},
		{29'b0, ide_da});

`ifdef debug_ide
	if (ide_dior == 0)
	  begin
	     $display("wrap_ide: read (%b %b) %x %x %x %x",
		      ide_dior, ide_diow, dbo, dboo, dboo[15:0], ide_data_out);
	  end
	if (ide_diow == 0)
	  begin
	     $display("wrap_ide: write (%b %b) %x %x %x",
		      ide_dior, ide_diow, dbo, dboo, ide_data_out);
	  end
`endif
     end

endmodule

