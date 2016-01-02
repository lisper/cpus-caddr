//
//
//

module niox_spy(
		input 		  clk,
		input 		  reset,

		input [15:0] 	  spy_in,
		output reg [15:0] spy_out,
		input [3:0] 	  spy_reg,
		input 		  spy_rd,
		input 		  spy_wr,
		
		output [1:0] 	  bd_cmd,
		output 		  bd_start,
		input 		  bd_bsy,
		input 		  bd_rdy,
		input 		  bd_err,
		output [23:0] 	  bd_addr,
		input [15:0] 	  bd_data_in,
		output [15:0] 	  bd_data_out,
		output 		  bd_rd,
		output 		  bd_wr,
		input 		  bd_iordy,
		input [15:0] 	  bd_state
		);


   reg [15:0] bd_reg;
   reg [15:0] bd_data;
   
   always @(posedge clk)
     if (reset)
       spy_out <= 0;
     else
       if (spy_rd)
	 begin
`ifdef debug
	    $display("niox_spy: read spy_reg %x bd_data_in %x", spy_reg, bd_data_in);
`endif
	    spy_out <= 
		       (spy_reg == 0) ? { bd_state[11:0], bd_bsy, bd_rdy, bd_err, bd_iordy} :
		       (spy_reg == 1) ? bd_data_in :
		       (spy_reg == 2) ? bd_reg :
		       16'h1234;
	 end

   always @(posedge clk)
     if (reset)
       bd_reg <= 0;
     else
       begin
	  if (spy_wr)
	    begin
`ifdef debug
	       $display("niox_spy: write spy_reg %x spy_in %x %t", spy_reg, spy_in, $time);
`endif
	       if (spy_reg == 1)
		 bd_data <= spy_in;
	       else
		 if (spy_reg == 2)
		   bd_reg <= spy_in;
	    end
       end
   
   assign bd_cmd = bd_reg[1:0];
   assign bd_start = bd_reg[2];
   assign bd_rd = (bd_pulse == 1) & bd_reg[3];
   assign bd_wr = (bd_pulse == 1) & bd_reg[4];
   assign bd_data_out = bd_data;

   reg [1:0] bd_pulse;
   
   always @(posedge clk)
     if (reset)
       bd_pulse <= 2'b00;
     else
       begin
	  case (bd_pulse)
	    0: if (bd_reg[3] | bd_reg[4]) bd_pulse <= 1;
	    1: bd_pulse <= 2;
	    2: if (~bd_reg[3] & ~bd_reg[4]) bd_pulse <= 0;
	    default: bd_pulse <= bd_pulse;
	  endcase
       end

`ifdef debug
   always @(posedge clk)
     if (bd_pulse != 0)
       $display("niox_spy: bd_pulse %d %t", bd_pulse, $time);
`endif
  
   assign bd_addr = 0;
   
endmodule // nios_spy
