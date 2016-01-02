
`timescale 1ps/1ps

module serdes_5_to_1 (ioclk, serdesstrobe, reset, gclk, datain, iob_data_out) ;

   input 	ioclk ;		// IO Clock network
   input 	serdesstrobe ;	// Parallel data capture strobe
   input 	reset ;		// Reset
   input 	gclk ;		// Global clock
   input [4:0] 	datain ;  	// Data for output
   output 	iob_data_out ;	// output data
   
   wire 	cascade_di;
   wire 	cascade_do;
   wire 	cascade_ti;
   wire 	cascade_to;
   wire [8:0] 	mdatain;

   assign mdatain = { 4'b0, datain };

OSERDES2 #(
	.DATA_WIDTH     	(5), 			// SERDES word width.  This should match the setting is BUFPLL
	.DATA_RATE_OQ      	("SDR"), 		// <SDR>, DDR
	.DATA_RATE_OT      	("SDR"), 		// <SDR>, DDR
	.SERDES_MODE    	("MASTER"), 		// <DEFAULT>, MASTER, SLAVE
	.OUTPUT_MODE 		("DIFFERENTIAL"))
oserdes_m (
	.OQ       		(iob_data_out),
	.OCE     		(1'b1),
	.CLK0    		(ioclk),
	.CLK1    		(1'b0),
	.IOCE    		(serdesstrobe),
	.RST     		(reset),
	.CLKDIV  		(gclk),
	.D4  			(mdatain[7]),
	.D3  			(mdatain[6]),
	.D2  			(mdatain[5]),
	.D1  			(mdatain[4]),
	.TQ  			(),
	.T1 			(1'b0),
	.T2 			(1'b0),
	.T3 			(1'b0),
	.T4 			(1'b0),
	.TRAIN    		(1'b0),
	.TCE	   		(1'b1),
	.SHIFTIN1 		(1'b1),			// Dummy input in Master
	.SHIFTIN2 		(1'b1),			// Dummy input in Master
	.SHIFTIN3 		(cascade_do),		// Cascade output D data from slave
	.SHIFTIN4 		(cascade_to),		// Cascade output T data from slave
	.SHIFTOUT1 		(cascade_di),		// Cascade input D data to slave
	.SHIFTOUT2 		(cascade_ti),		// Cascade input T data to slave
	.SHIFTOUT3 		(),			// Dummy output in Master
	.SHIFTOUT4 		()) ;			// Dummy output in Master

OSERDES2 #(
	.DATA_WIDTH     	(5), 			// SERDES word width.  This should match the setting is BUFPLL
	.DATA_RATE_OQ      	("SDR"), 		// <SDR>, DDR
	.DATA_RATE_OT      	("SDR"), 		// <SDR>, DDR
	.SERDES_MODE    	("SLAVE"), 		// <DEFAULT>, MASTER, SLAVE
	.OUTPUT_MODE 		("DIFFERENTIAL"))
oserdes_s (
	.OQ       		(),
	.OCE     		(1'b1),
	.CLK0    		(ioclk),
	.CLK1    		(1'b0),
	.IOCE    		(serdesstrobe),
	.RST     		(reset),
	.CLKDIV  		(gclk),
	.D4  			(mdatain[3]),
	.D3  			(mdatain[2]),
	.D2  			(mdatain[1]),
	.D1  			(mdatain[0]),
	.TQ  			(),
	.T1 			(1'b0),
	.T2 			(1'b0),
	.T3  			(1'b0),
	.T4  			(1'b0),
	.TRAIN 			(1'b0),
	.TCE	 		(1'b1),
	.SHIFTIN1 		(cascade_di),		// Cascade input D from Master
	.SHIFTIN2 		(cascade_ti),		// Cascade input T from Master
	.SHIFTIN3 		(1'b1),			// Dummy input in Slave
	.SHIFTIN4 		(1'b1),			// Dummy input in Slave
	.SHIFTOUT1 		(),			// Dummy output in Slave
	.SHIFTOUT2 		(),			// Dummy output in Slave
	.SHIFTOUT3 		(cascade_do),   	// Cascade output D data to Master
	.SHIFTOUT4 		(cascade_to)) ; 	// Cascade output T data to Master

endmodule
