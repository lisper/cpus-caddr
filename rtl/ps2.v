// ps2.v

/*
 * Monitor the serial datastream and clock from a PS/2 keyboard or mouse
 * and output each byte received.
 *
 * The clock from the PS/2 keyboard is sampled at
 * the frequency of the main clock input; edges are extracted,
 * The main clock must be substantially faster than
 * the 10 KHz PS/2 clock - 200 KHz or more.
 *
 * The code is only valid when the ready signal is high.  The scancode
 * should be registered by an external circuit on the first clock edge
 * after the ready signal goes high.
 *
 * The error flag is set whenever the PS/2 clock stops pulsing and the
 * PS/2 clock is either at a low level or less than 11 bits of serial
 * data have been received (start + 8 data + parity + stop).
 */

module ps2(clk,		// main clock
	   reset,	// asynchronous reset
	   ps2_clk,	// clock from keyboard
	   ps2_data,	// data from keyboard
	   code,	// received byte
	   parity,	// parity bit for scancode
	   busy,	// busy receiving scancode
	   rdy,		// scancode ready pulse
	   error	// error receiving scancode
	   );
   
   input clk, reset;
   input ps2_clk;
   input ps2_data;
   output [7:0] code;
   output 	parity;
   output 	busy;
   output 	rdy;
   output 	error;


   parameter FREQ = 50000; // frequency of the main clock (KHz)
//   parameter FREQ = 25000; // frequency of the main clock (KHz)
//   parameter FREQ = 12500; // frequency of the main clock (KHz)
   parameter PS2_FREQ = 10;  // keyboard clock frequency (KHz)
   parameter TIMEOUT  = FREQ / PS2_FREQ;  // ps2_clk quiet timeout
//   parameter [7:0] KEY_RELEASE = 8'b11110000;  // sent when key is rel'd

   reg [13:0]  timer_r;		// time since last PS/2 clock edge
   wire [13:0] timer_c;

   reg [3:0]   bitcnt_r;	// number of received scancode bits
   wire [3:0]  bitcnt_c;

   reg [4:0]   ps2_clk_r;	// PS/2 clock sync / edge detect
   wire [4:0]  ps2_clk_c;

   reg [9:0]   sc_r;	 	// scancode shift register
   wire [9:0]  sc_c;

   reg 	       rdy_r;	 	// set when scancode ready
   wire        rdy_c;

   reg 	       error_r;	 	// set when an error occurs
   wire        error_c;

   wire        ps2_clk_fall_edge; // on falling edge of PS/2 clock
   wire        ps2_clk_rise_edge; // on rising edge of PS/2 clock
   wire        ps2_clk_edge;	 // on either edge of PS/2 clock
   wire        ps2_clk_quiet;	 // when no edges on PS/2 clock for TIMEOUT
   wire        scancode_rdy;	 // when scancode has been received


   // sample ps/2 clock
   assign ps2_clk_c = {ps2_clk_r[3:0], ps2_clk};

   // find ps/2 clock edges
   assign ps2_clk_fall_edge = ps2_clk_r[4:1] == 4'b1100;
   assign ps2_clk_rise_edge = ps2_clk_r[4:1] == 4'b0011;
   assign ps2_clk_edge      = ps2_clk_fall_edge || ps2_clk_rise_edge;

   // sample ps/2 data line on falling edge of ps/2 clock
   assign sc_c = ps2_clk_fall_edge ? {ps2_data, sc_r[9:1]} : sc_r;

   // clear edge timer when we see a clock edge
   assign timer_c = ps2_clk_edge ? 0 : (timer_r + 1);

   // notice when ps/2 clock is idle
   assign ps2_clk_quiet = timer_r == TIMEOUT && ps2_clk_r[1];

   // incr bit counter on falling edge of the ps/2 clock.
   // reset bit counter if the ps/2 clock is idle or
   // there was an error receiving the scancode.
   assign bitcnt_c = ps2_clk_fall_edge ? (bitcnt_r + 1) :
		     (ps2_clk_quiet || error_r) ? 0 :
		     bitcnt_r;

   // detect ready - bit counter = 11 & ps/2 clock idle
   assign scancode_rdy = bitcnt_r == 4'd11 && ps2_clk_quiet;

   assign rdy_c = scancode_rdy;

   // detect error - clock low too long or idle during scancode rx
   assign error_c = (timer_r == TIMEOUT && ps2_clk_r[1] == 0) ||
		    (ps2_clk_quiet && bitcnt_r != 4'd11 && bitcnt_r != 4'd0) ?
//		    1 : error_r;
		    1 : (ps2_clk_quiet ? 0 : error_r);

   // outputs
   assign code     = sc_r[7:0];		// scancode
   assign parity   = sc_r[8];		// parity bit for the scancode
   assign busy     = bitcnt_r != 4'd0;	// busy when recv'ing scancode
   assign rdy      = rdy_r;		// scancode ready flag
   assign error    = error_r;		// error flag

   // update the various registers
   always @(posedge clk)
     if (reset)
       begin
	  ps2_clk_r <= 5'b11111;  // assume PS/2 clock has been high
	  sc_r      <= 0;
	  rdy_r     <= 0;
	  timer_r   <= 0;
	  bitcnt_r  <= 0;
	  error_r   <= 0;
       end
     else
       begin
	  ps2_clk_r <= ps2_clk_c;
	  sc_r      <= sc_c;
	  rdy_r     <= rdy_c;
	  timer_r   <= timer_c;
	  bitcnt_r  <= bitcnt_c;
	  error_r   <= error_c;
       end
   
endmodule
