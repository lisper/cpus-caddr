// keyboard.v

/*
 keyboard - new keyboard
*/

module keyboard(clk,
		reset,
		ps2_clk,
		ps2_data,
		data,
		strobe);

   input clk;
   input reset;
   input ps2_clk;
   input ps2_data;

   output [15:0] data;
   reg [15:0] 	 data;

   output 	 strobe;
   reg 		 strobe;

   // ---------------------------------------------------------
   
   wire 	  kb_scan_rdy;
   wire 	  kb_bsy;
   wire [7:0] 	  kb_scancode;
   
   wire 	  kb_out_rdy;
   wire [15:0] 	  kb_out_keycode;


   ps2 ps2(.clk(clk),
	   .reset(reset),
	   .ps2_clk(ps2_clk),
	   .ps2_data(ps2_data),
	   .code(kb_scancode),
	   .parity(),
	   .busy(kb_bsy),
	   .rdy(kb_scan_rdy),
	   .error()
	   );

   scancode_convert scancode_convert(.clk(clk),
				     .reset(reset),
				     .strobe_in(kb_scan_rdy),
				     .code_in(kb_scancode),
				     .strobe_out(kb_out_rdy),
				     .keycode(kb_out_keycode));

   always @(posedge clk)
     if (reset)
       begin
	  data <= 0;
	  strobe <= 0;
       end
     else
       begin
	  data <= kb_out_keycode;
	  strobe <= kb_out_rdy;
`ifdef debug
	  if (kb_scan_rdy)
	    $display("keyboard: kb_scan_rdy, kb_scancode 0x%x %o",
		     kb_scancode, kb_scancode);
`endif
       end
   
endmodule // keyboard
