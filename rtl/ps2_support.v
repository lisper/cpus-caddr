//

module ps2_support(clk, reset,
		   kb_ps2_clk_in, kb_ps2_data_in,
		   ms_ps2_clk_in, ms_ps2_data_in,
		   ms_ps2_clk_out, ms_ps2_data_out, ms_ps2_dir,
		   kb_data, kb_ready,
		   ms_x, ms_y, ms_button, ms_ready);

   input clk;
   input reset;

   input kb_ps2_clk_in;
   input kb_ps2_data_in;

   input ms_ps2_clk_in;
   input ms_ps2_data_in;

   output ms_ps2_clk_out;
   output ms_ps2_data_out;
   output ms_ps2_dir;

   output [15:0] kb_data;
   reg [15:0] 	 kb_data;
   output 	 kb_ready;
   reg 		 kb_ready;
   
   output [11:0]  ms_x, ms_y;
   output [2:0]   ms_button;
   output 	  ms_ready;

   reg [11:0] 	  ms_x, ms_y;
   reg [2:0] 	  ms_button;
   reg 		  ms_ready;

   
`ifdef null
   assign ms_ps2_dir = 0;
   assign ms_ps2_data_out = 0;
   assign ms_ps2_clk_out = 0;

   assign kb_ready = 0;
   assign kb_data = 16'b0;
   
   assign ms_ready = 0;
   assign ms_x = 12'b0;
   assign ms_y = 12'b0;
   assign ms_button = 3'b0;
`else

   wire [15:0] kb_bits;
   wire        kb_strobe;
   
   keyboard keyboard(
		     .clk(clk),
		     .reset(reset),
		     .ps2_clk(kb_ps2_clk_in),
		     .ps2_data(kb_ps2_data_in),
		     .data(kb_bits),
		     .strobe(kb_strobe)
		     );

   always @(posedge clk)
     if (reset)
       begin
	  kb_data <= 0;
	  kb_ready <= 0;
       end
     else
       begin
	  kb_data <= kb_bits;
	  kb_ready <= kb_strobe;
       end

   wire [11:0] m_x;
   wire [11:0] m_y;
   wire [2:0]  m_button;
   wire        m_ready;
   
   mouse mouse(
	       .clk(clk),
	       .reset(reset),
	       .ps2_clk_in(ms_ps2_clk_in),
	       .ps2_data_in(ms_ps2_data_in),
	       .ps2_clk_out(ms_ps2_clk_out),
	       .ps2_data_out(ms_ps2_data_out),
	       .ps2_dir(ms_ps2_dir),
	       .button_l(m_button[2]),
	       .button_m(m_button[1]),
	       .button_r(m_button[0]),
	       .x(m_x),
	       .y(m_y),
	       .strobe(m_ready)
	       );
   
   always @(posedge clk)
     if (reset)
       begin
	  ms_x <= 0;
	  ms_y <= 0;
	  ms_button <= 0;
	  ms_ready <= 0;
       end
     else
       begin
	  ms_x <= m_x;
	  ms_y <= m_y;
	  ms_button <= m_button;
	  ms_ready <= m_ready;
       end

`endif
   
endmodule

