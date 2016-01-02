//
//
//

module niox_rom (
		 input clk_i,
		 input rst_i,
		 input [31:0] addr_i,
		 input sel_i,
		 output [31:0] data_o,
		 output ack_o
		 ); 

   reg [31:0] mem[0:4095]; 
   reg [31:0] dato;
   reg ack; 
    
   always @(posedge clk_i) 
     if (rst_i)
       ack <= 0;
     else
       begin
	  if (sel_i)
	    begin
	       if (ack)
		 ack <= 1'b0;
	       else
		 ack <= 1'b1;
	    end
	  else
	    ack <= 1'b0;
       end
 
   assign ack_o = ack; 

   always @(posedge clk_i)
     if (rst_i)
       dato <= 32'b0;
     else 
       if (sel_i)
	 begin
	    dato <= mem[ addr_i[31:2] ];
`ifdef debug
	    if (ack)
	    $display("rom: addr %x => data %x", addr_i, mem[ addr_i[31:2] ]);
`endif
	 end

   assign data_o = dato;
 
`ifdef never
   initial 
     begin 
	$readmemh("niox_irom.hex",mem); 
     end 
`else
   integer r, file, i;

   initial
     begin
	$display("READING instr rom...");
	$readmemh("niox_irom.hex", mem);
	r = 0;
	if (r) begin
	   $display("can't read niox_irom.bin");
	   $finish;
	end

	$display("READING instr rom done");
	$display("irom mem[0] = %x", mem[0]);
	$display("irom mem[1] = %x", mem[1]);
     end
`endif

 
endmodule 
 
