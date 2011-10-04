// scancode_convert.v
//
// simple AT style keyboard scancode to lispm keyboard convertion
//  inputs AT scancodes and outputs lispm keyboard code
//

module scancode_convert(clk,
			reset,
			strobe_in,
			code_in,
			strobe_out,
			keycode);
   
   input clk;
   input reset;
   input strobe_in;
   input [7:0] code_in;

   output strobe_out;

   output [15:0] keycode;
   reg [15:0] 	keycode;
   
   //
   wire [7:0] 	rom_data;
   reg 		f0_prefix;
   reg 		e0_prefix;
   reg [7:0] 	sc;


   scancode_rom scancode_rom(.addr({e0_prefix, sc}),
			     .data(rom_data));

   // state machine
   parameter [2:0]
		S_IDLE = 0,
		S_E0 = 1,
		S_F0 = 2,
		S_E0F0 = 3,
		S_CONVERT_DOWN = 4,
		S_CONVERT_UP = 5,
   		S_STROBE = 6;

`ifdef debug
   task dumpstate;
      begin
	 if (state != next_state)
	 case (state)
	   S_E0: $display("S_E0");
	   S_F0: $display("S_F0");
	   S_E0F0: $display("S_E0F0");
	   S_CONVERT_UP: $display("S_CONVERT_UP");
	   S_CONVERT_DOWN: $display("S_CONVERT_DOWN");
   	   S_STROBE: $display("S_STROBE");
	 endcase
      end
   endtask
`endif

   reg [2:0] state;
   wire [2:0] next_state;
   
   always @(posedge clk)
     if (reset)
       state <= 0;
     else
       begin
`ifdef debug
	  dumpstate;
`endif
	  state <= next_state;
       end
   
   assign next_state =
      (state == S_IDLE && strobe_in && code_in == 8'he0) ? S_E0 :
      (state == S_IDLE && strobe_in && code_in == 8'hf0) ? S_F0 :
      (state == S_IDLE && strobe_in) ? S_CONVERT_DOWN :
      (state == S_F0 && strobe_in) ? S_CONVERT_UP :
      (state == S_E0 && strobe_in && code_in == 8'hf0) ? S_E0F0 :
      (state == S_E0 && strobe_in && code_in != 8'hf0) ? S_CONVERT_DOWN :
      (state == S_E0F0 && strobe_in) ? S_CONVERT_UP :
      (state == S_CONVERT_DOWN) ? S_STROBE :
      (state == S_CONVERT_UP) ? S_STROBE : 
      (state == S_STROBE) ? S_IDLE :
      state;

   assign strobe_out = state == S_STROBE;

   // modifier state
   always @(posedge clk)
     if (reset)
       begin
	  sc <= 0;
	  keycode <= 0;
	  f0_prefix <= 0;
	  e0_prefix <= 0;
       end
     else
       begin
	  if (strobe_in)
	    begin
	       sc <= code_in;
	    end
	  else
	    case (state)
	      S_E0: e0_prefix <= 1;
	      S_CONVERT_DOWN:
		begin
		   keycode <= { 7'b0, 1'b0, rom_data };
		   f0_prefix <= 0;
		   e0_prefix <= 0;
		end
	      
	      S_CONVERT_UP:
		begin
		   keycode <= { 7'b0, 1'b1, rom_data };
		   f0_prefix <= 0;
		   e0_prefix <= 0;
		end
	    endcase
       end

endmodule
