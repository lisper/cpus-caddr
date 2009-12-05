// LM-2 clocks

`timescale 1ns / 1ns

module lm2clock;

reg OSC50MHZ;
wire OSC0, HIFREQ1, HIFREQ2, \-HF , HFDLYD, HFTOMM;
wire \-CLK , \-MCLK , TPCLK, \-TPCLK , LCLK, \-LCLK , WP, \-LWP ;
wire TSE, LTSE, \-LTSE ;
wire \-TPR0 , TPR0A, TPR0D, \-TPR0D ;
wire TPR1A, \-TPR1D ;
wire TPWP, \-SONE , \-TPREND ;

reg TPR1, \-TPR1 , FF1D  ;
reg \-TPR6 , TPR5, \-TPR5 , TPR4, \-TPR4 , TPR3, \-TPR3 , TPR2, \-TPR2 ;
reg TPW0, \-TPW0 , TPW1, \-TPW1 , TPW2, \-TPW2 , TPW3, \-TPW3 ;

wire TPWPOR1, TPWPIRAM;
wire TPTSE, TPTSEF, \-TPTSEF , MASKC, FF1, \-FF1 ;
reg \-TENDLY , \-HANG , \-HANGS , \-CRBS ;
wire MACHRUNA, \-IWE , IWRITED;
reg \-MACHRUNA ;
wire HI, HI3;

reg SPEED0A, SPEED1A, SSPEED0A, SSPEED1A;

wire SPEED0, SPEED1, \-ILONG ;
reg \-CLOCK.RESET.B ;

assign HI = 1;
assign HI3 = 1;

assign SPEED0 = 1;
assign SPEED1 = 1;
assign \-ILONG = 1;
assign IWRITED = 0;

assign \-MCLK = \-TPCLK & HI;
assign \-CLK = \-TPCLK & MACHRUNA;

assign LCLK = ! \-CLK ;
assign \-LCLK = ! LCLK ;
assign \-LTSE = ! TPTSE ;
assign TSE = ! \-LTSE ;
assign \-LWP = ! TPWP ;
assign WP = ! \-LWP ;

assign TPR0A = ! \-TPR0 ;
assign \-TPR0D = ! TPR0A;
assign TPR1A = ! \-TPR1 ;
assign \-TPR1D = ! TPR1A ;
assign MACHRUNA = ! \-MACHRUNA ;

assign TPWP = TPW1 & \-CRBS & MACHRUNA;
// ?? TPWPOR1
assign TPWPIRAM = TPWPOR1 & \-CRBS & MACHRUNA;

assign TPTSEF = ! ( \-TPR1D & \-CRBS & \-TPTSEF );
assign \-IWE = ! ( IWRITED & HI3 & TPWPIRAM );
assign \-TPCLK = ! (\-TPW0 & \-CRBS & TPCLK );

always @(posedge HIFREQ1)
  begin
    \-TPR6 <= TPR5;
    TPW3 <= TPW2;
    \-TPW3 <= !TPW2;
    TPW2 <= TPW1;
    \-TPW2 <= !TPW1;
    TPW1 <= TPW0;
    \-TPW1 <= !TPW0;

    TPR5 <= TPR4;
    \-TPR5 <= !TPR4;

    TPR4 <= TPR3;
    \-TPR4 <= !TPR3;

    TPR3 <= TPR2;
    \-TPR3 <= !TPR2;

    \-TPR2 <= \-SONE ;
    TPR2 <= !\-SONE ;
  end

//
//assign -RESET = RESET;
//assign -TSE = TPTSE;
//assign -WP = TPWP;
//assign CLK2 = -LCLK;
//assign CLK1 = -LCLK;
//assign CLKN = -CLK;
//

assign MASKC = ! ( \-TENDLY & \-TPR1 );
assign \-FF1 = ! ( \-TPR1 & FF1 );
assign TPCLK = ! ( \-TPCLK & \-TPR0 );
assign \-TPTSEF = ! ( \-TPR0D & TPTSEF );

assign TPWPOR1 = ! ( \-TPW0 & \-TPW1 );
assign TPTSE = ! (\-TPTSEF & MACHRUNA );

assign OSC0 = ! OSC50MHZ;
assign HIFREQ1 = ! OSC0;
assign HIFREQ2 = ! OSC0;
assign \-HF = ! HIFREQ2;
assign HFDLYD = ! \-HF ;
assign HFTOMM = ! HFDLYD;

always @(posedge HIFREQ1)
  begin
    FF1D <= FF1;
    \-TPR1 <= \-TPR0 ;
    TPR1 <= !\-TPR0 ;
  end

assign FF1 = ! ( \-TPW2 & \-CRBS & \-FF1 );
assign \-TPR0 = ! ( FF1D & \-HANGS & \-CRBS );
assign \-SONE = ! ( TPR1 & \-TPR3 & \-TPR4 );

assign \-TPREND = ! (
  ( { SSPEED1A, SSPEED0A, \-ILONG } == 3'b000 ) ? \-TPR6 :
  ( { SSPEED1A, SSPEED0A, \-ILONG } == 3'b001 ) ? \-TPR5 :
  ( { SSPEED1A, SSPEED0A, \-ILONG } == 3'b010 ) ? \-TPR5 :
  ( { SSPEED1A, SSPEED0A, \-ILONG } == 3'b011 ) ? \-TPR4 :
  ( { SSPEED1A, SSPEED0A, \-ILONG } == 3'b100 ) ? \-TPR4 :
  ( { SSPEED1A, SSPEED0A, \-ILONG } == 3'b101 ) ? \-TPR3 :
  ( { SSPEED1A, SSPEED0A, \-ILONG } == 3'b110 ) ? \-TPR4 :
    \-TPR2 );

always @(posedge TPR1)
  if (\-CLOCK.RESET.B )
    begin
      SPEED1A <= SPEED1;
      SPEED0A <= SPEED0;
      SSPEED1A <= SPEED1A;
      SSPEED0A <= SPEED0A;
    end

always @(\-CLOCK.RESET.B )
  if (\-CLOCK.RESET.B == 0)
  begin
    SPEED1A = 0;
    SPEED0A = 0;
    SSPEED1A = 0;
    SSPEED0A = 0;
  end

always @(posedge HFDLYD)
  \-TENDLY <= \-TPREND ;

always @(posedge HIFREQ2)
  begin
    \-TPW0 <= MASKC;
    TPW0 <= !MASKC;

    \-HANGS <= \-HANG ;
    \-CRBS <= \-CLOCK.RESET.B ;
  end



initial
  begin
    FF1D = 0;
    \-CRBS = 0;
    \-TPW2 = 0;
  end

endmodule

module test;
  lm2clock lm2clock ();

  initial
    begin
      $dumpfile("lm2clock.vcd");
      $dumpvars(0, test.lm2clock);
    end

  initial
    begin
      lm2clock.OSC50MHZ = 0;
      lm2clock.\-CLOCK.RESET.B = 1;
      lm2clock.\-MACHRUNA = 0;
      lm2clock.\-HANG = 1;

      #1 lm2clock.\-CLOCK.RESET.B = 0;

      #250 lm2clock.\-CLOCK.RESET.B = 1;

      #500 $finish;
    end

  // 50mhz clock
  always
    begin
      #10 lm2clock.OSC50MHZ = 0;
      #10 lm2clock.OSC50MHZ = 1;
    end

endmodule
