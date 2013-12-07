
module wrap_mmc(clk, mmc_cs, mmc_di, mmc_do, mmc_sclk);

   input clk;
   input mmc_cs;
   input mmc_di;
   output mmc_do;
   input  mmc_sclk;
		
   import "DPI-C" function void dpi_mmc(input integer  m_di,
					output integer m_do,
				        input integer  m_cs,
				        input integer  m_sclk);

   integer ddo;
   wire [31:0] ddoo;
      
   assign ddoo = ddo;
   assign mmc_do = ddoo[0];

   always @(posedge clk)
     begin
	dpi_mmc({31'b0, mmc_di},
		ddo,
		{31'b0, mmc_cs}, 
		{31'b0, mmc_sclk});
     end

endmodule

