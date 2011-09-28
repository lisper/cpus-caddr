// mouse.v

module mouse(clk,
	     reset,
	     ps2_clk_in,
	     ps2_data_in,
	     ps2_clk_out,
	     ps2_data_out,
	     ps2_dir,
	     button_l,
	     button_m,
	     button_r,
	     x,
	     y,
	     strobe);

   input clk;
   input reset;
   input ps2_clk_in;
   input ps2_data_in;

   output ps2_clk_out;
   output ps2_data_out;
   output ps2_dir;
   
   output button_l;
   output button_m;
   output button_r;
   
   output [11:0] x;
   output [11:0] y;
   
   output 	 strobe;

   // ---------------------------------------------------------
   
   reg [4:0] 	 m_state;
   wire [4:0] 	 m_state_next;

   parameter [4:0]
		M_IDLE = 0,
		M_POLL1 = 1,
		M_POLL2 = 2,
		M_RX1A = 3,
		M_RX1B = 4,
		M_RX2A = 5,
		M_RX2B = 6,
		M_RX3A = 7,
		M_RX3B = 8,
		M_RX4A = 9,
		M_RX4B = 10;
   
   wire 	  m_rdy;
   wire 	  m_bsy;
   wire [7:0] 	  m_code;
   wire 	  m_err;
   
   reg 		  m_full;
   
   ps2 ps2_in(.clk(clk),
	   .reset(reset),
	   .ps2_clk(ps2_clk_in),
	   .ps2_data(ps2_data_out),
	   .code(m_code),
	   .parity(),
	   .busy(m_bsy),
	   .rdy(m_rdy),
	   .error(m_err)
	   );

   wire [7:0] m_out_code;
   wire       m_out_send;
   wire       m_out_busy;
   wire       m_out_rdy;
   
   ps2_send ps2_out(.clk(clk),
		    .reset(reset),
		    .ps2_clk(ps2_clk_out),
		    .ps2_data(ps2_data_out),
		    .code(m_out_code),
		    .send(m_out_send),
		    .busy(m_out_busy),
		    .rdy(m_out_rdy)
		    );

   assign m_out_code = 8'h3b;
   assign m_out_send = m_state == M_POLL1;
   
   assign ps2_dir = m_out_busy;

   //
   // send 0xeb read command and then collect 4 bytes
   //
   always @(posedge clk)
     if (reset)
       m_state <= 0;
     else
       m_state <= m_state_next;

   assign m_state_next =
			m_err ? M_IDLE :
			(m_state == M_IDLE && ~m_full) ? M_POLL1 :
			(m_state == M_POLL1 && ~m_out_rdy) ? M_POLL2 :
			(m_state == M_POLL2 && m_out_rdy) ? M_RX1A :

			(m_state == M_RX1A && m_rdy) ? M_RX1B :
			(m_state == M_RX1B && ~m_rdy) ? M_RX2A: 

			(m_state == M_RX2A && m_rdy) ? M_RX2B :
			(m_state == M_RX2B && ~m_rdy) ? M_RX3A: 

			(m_state == M_RX3A && m_rdy) ? M_RX3B :
			(m_state == M_RX3B && ~m_rdy) ? M_RX4A: 

			(m_state == M_RX4A && m_rdy) ? M_RX4B :
			(m_state == M_RX4B && ~m_rdy) ? M_IDLE:

			m_state;

   reg [7:0] m_b1, m_b2, m_b3, m_b4;
   
   always @(posedge clk)
     if (reset)
       begin
	  m_b1 <= 0;
	  m_b2 <= 0;
	  m_b3 <= 0;
	  m_b4 <= 0;
       end
     else
       if (m_rdy)
	 case (m_state)
	   M_RX1A: m_b1 <= m_code;
	   M_RX2A: m_b2 <= m_code;
	   M_RX3A: m_b3 <= m_code;
	   M_RX4A: m_b4 <= m_code;
	 endcase

   always @(posedge clk)
     if (reset)
       m_full <= 0;
     else
       if (m_state == M_RX4B)
	 m_full <= 1;
       else
	 m_full <= 0;

   assign strobe = m_full;

   assign button_l = m_b2[0];
   assign button_r = m_b2[1];
   assign button_m = m_b2[2];
   assign x = { m_b2[4], m_b2[4], m_b2[4], m_b2[4], m_b3 };
   assign y = { m_b2[5], m_b2[5], m_b2[5], m_b2[5], m_b4 };
   
endmodule
