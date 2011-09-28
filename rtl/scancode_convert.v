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
   output [7:0] keycode;

   reg [7:0] 	keycode;
   
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
		S_TOGGLE = 3,
		S_CONVERT = 4,		
   		S_STROBE = 5;

`ifdef debug
   task dumpstate;
      begin
	 if (state != next_state)
	 case (state)
	   S_E0: $display("S_E0");
	   S_F0: $display("S_F0");
	   S_TOGGLE: $display("S_TOGGLE");
	   S_CONVERT: $display("S_CONVERT");
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
	      (state == S_IDLE && strobe_in) ? S_CONVERT :
	      (state == S_F0 && strobe_in) ? S_TOGGLE :
	      (state == S_E0 && strobe_in && code_in == 8'hf0) ? S_TOGGLE :
	      (state == S_E0 && strobe_in && code_in != 8'hf0) ? S_CONVERT :
	      (state == S_TOGGLE) ? S_IDLE :		      
	      (state == S_CONVERT) ? S_STROBE :
	      (state == S_STROBE) ? S_IDLE :
	      state;

   assign strobe_out = state == S_STROBE;

   wire   down, up;

   assign down = ~f0_prefix;
   assign up = f0_prefix;
   
   // modifier state
   always @(posedge clk)
     if (reset)
       begin
	  f0_prefix <= 0;
	  e0_prefix <= 0;
	  sc <= 0;
	  keycode <= 0;
       end
     else
       begin
	  if (strobe_in)
	    begin
	       sc <= code_in;
	    end
	  else
	    begin
	       case (state)
		 S_E0:
		   e0_prefix <= 1;
		 S_CONVERT:
		   begin
		      f0_prefix <= 0;
		      e0_prefix <= 0;
		      keycode <= rom_data;
		   end
		 S_TOGGLE:
		   f0_prefix <= 1;
	       endcase
	    end
       end

endmodule
