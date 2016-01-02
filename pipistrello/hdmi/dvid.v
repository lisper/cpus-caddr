// original vhdl from Mike Field <hamster@snap.net.nz>
// DVI-D
// Converts VGA signals into DVID bitstreams.
//
//    'clk' and 'clk_n' should be 5x clk_pixel.
//
//    'blank' should be asserted during the non-display portions of the frame

module dvid(input 	clk_pixel,
	    input 	clk_pixel2x,
	    input 	clk_pixel10x,
	    input 	reset,
	    input 	serdes_strobe,
	    input 	serdes_reset,
            input [7:0] red_p,
            input [7:0] green_p,
            input [7:0] blue_p,
            input 	blank,
            input 	hsync,
            input 	vsync,
            output 	red_s,
            output 	green_s,
            output 	blue_s,
            output 	clock_s);

   wire [9:0] encoded_red, encoded_green, encoded_blue;

   wire [1:0] c_red;
   wire [1:0] c_green;
   wire [1:0] c_blue;

   assign c_red = 0;
   assign c_green = 0;
   assign c_blue = { vsync, hsync };

`ifdef never
   TDMS_encoder TDMS_encoder_red(.clk(clk_pixel),
				  .data(red_p),
				  .c(c_red),
				  .blank(blank),
				  .encoded(encoded_red));
   
   TDMS_encoder TDMS_encoder_green(.clk(clk_pixel),
				  .data(green_p),
				  .c(c_green),
				  .blank(blank),
				  .encoded(encoded_green));
   
   TDMS_encoder TDMS_encoder_blue(.clk(clk_pixel),
				  .data(blue_p),
				  .c(c_blue),
				  .blank(blank),
				  .encoded(encoded_blue));
`else
   encode TDMS_encoder_red(.clkin(clk_pixel),
			    .rstin(reset),
			    .din(red_p),
			    .c0(1'b0), .c1(1'b0),
			    .de(~blank),
			    .dout(encoded_red));
   
   encode TDMS_encoder_green(.clkin(clk_pixel),
			    .rstin(reset),
			      .din(green_p),
			      .c0(1'b0), .c1(1'b0),
			      .de(~blank),
			      .dout(encoded_green));
   
   encode TDMS_encoder_blue(.clkin(clk_pixel),
			     .rstin(reset),
			     .din(blue_p),
			     .c0(hsync),
			     .c1(vsync),
			     .de(~blank),
			     .dout(encoded_blue));
`endif
   
   // 5-bit busses converted from 10-bit
   wire [4:0] tmds_data0;
   wire [4:0] tmds_data1;
   wire [4:0] tmds_data2;

   wire [29:0] s_data = {encoded_red[9:5], encoded_green[9:5], encoded_blue[9:5],
			 encoded_red[4:0], encoded_green[4:0], encoded_blue[4:0]};

   convert_30to15_fifo pixel2x (
				.rst     (reset),
				.clk     (clk_pixel),
				.clkx2   (clk_pixel2x),
				.datain  (s_data),
				.dataout ({tmds_data2, tmds_data1, tmds_data0}));
   
   serdes_5_to_1 oserdes_blue (
			       .ioclk(clk_pixel10x),
			       .serdesstrobe(serdes_strobe),
			       .reset(serdes_reset),
			       .gclk(clk_pixel2x),
			       .datain(tmds_data0),
			       .iob_data_out(blue_s)) ;

   serdes_5_to_1 oserdes_green (
				.ioclk(clk_pixel10x),
				.serdesstrobe(serdes_strobe),
				.reset(serdes_reset),
				.gclk(clk_pixel2x),
				.datain(tmds_data1),
				.iob_data_out(green_s)) ;

   serdes_5_to_1 oserdes_red (
			      .ioclk(clk_pixel10x),
			      .serdesstrobe(serdes_strobe),
			      .reset(serdes_reset),
			      .gclk(clk_pixel2x),
			      .datain(tmds_data2),
			      .iob_data_out(red_s)) ;

   //
   reg [4:0] tmdsclkint = 5'b00000;
   reg toggle = 1'b0;

   always @ (posedge clk_pixel2x or posedge serdes_reset) 
     begin
	if (serdes_reset)
	  toggle <= 1'b0;
	else
	  toggle <= ~toggle;
     end

  always @ (posedge clk_pixel2x)
    begin
       if (toggle)
	 tmdsclkint <= 5'b11111;
       else
	 tmdsclkint <= 5'b00000;
    end

  serdes_5_to_1 oserdes_clock (
			       .ioclk        (clk_pixel10x),
			       .serdesstrobe (serdes_strobe),
			       .reset        (serdes_reset),
			       .gclk         (clk_pixel2x),
			       .datain       (tmdsclkint),
			       .iob_data_out (clock_s));

endmodule // dvid
