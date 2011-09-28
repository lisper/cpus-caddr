// ps2_send.v

module ps2_send(clk,		// main clock
		reset,		// asynchronous reset
		ps2_clk,	// clock from keyboard
		ps2_data,	// data from keyboard
		code,		// send byte
		send,
		parity,		// parity bit for scancode
		busy,		// busy sending scancode
		rdy		// ready pulse
		);
   
   input clk, reset;
   input [7:0] code;
   input       send;
   input       parity;
   output      busy;
   output      rdy;

   output      ps2_clk;
   output      ps2_data;

endmodule

