/****************************************************************************
 *                                                                          *
 *  VERILOG HIGH-LEVEL DESCRIPTION OF THE TI 74181 CIRCUIT                  *
 *                                                                          *
 *  Function: 4-bit ALU/Function Generator                                  *
 *                                                                          *
 *  Written by: Mark C. Hansen                                              *
 *                                                                          *
 *  Last modified: Dec 11, 1997                                             *
 *                                                                          *
 ****************************************************************************/

// note - AEB is open collector

module ic_74S181 (S, A, B, M, CIN_N, F, X, Y, COUT_N, AEB);

  input [3:0] A, B, S;
  input CIN_N, M; 
  output [3:0] F;
  output AEB, X, Y, COUT_N;
	
  TopLevel74181 Ckt74181 (S, A, B, M, CIN_N, F, X, Y, COUT_N, AEB);

endmodule /* Circuit74181 */

/*************************************************************************/

module TopLevel74181 (S, A, B, M, CNb, F, X, Y, CN4b, AEB);

  input [3:0] A, B, S;
  input CNb, M; 
  output [3:0] F;
  output AEB, X, Y, CN4b;
  wire [3:0] E, D, C, Bb;
  
  Emodule Emod1 (A, B, S, E, Bb);
  Dmodule Dmod2 (A, B, Bb, S, D);
  CLAmodule CLAmod3(E, D, CNb, C, X, Y, CN4b);
  Summodule Summod4(E, D, C, M, F, AEB);

endmodule /* TopLevel74181 */

/*************************************************************************/

module Emodule (A, B, S, E, Bb);

  input [3:0] A, B, S;
  output [3:0] E, Bb;
  wire [3:0]  ABS3, ABbS2;

  not Bb0gate(Bb[0], B[0]);
  not Bb1gate(Bb[1], B[1]);
  not Bb2gate(Bb[2], B[2]);
  not Bb3gate(Bb[3], B[3]);

  and ABS30gate(ABS3[0], A[0], B[0], S[3]);
  and ABS31gate(ABS3[1], A[1], B[1], S[3]);
  and ABS32gate(ABS3[2], A[2], B[2], S[3]);
  and ABS33gate(ABS3[3], A[3], B[3], S[3]);

  and ABbS20gate(ABbS2[0], A[0], Bb[0], S[2]);
  and ABbS21gate(ABbS2[1], A[1], Bb[1], S[2]);
  and ABbS22gate(ABbS2[2], A[2], Bb[2], S[2]);
  and ABbS23gate(ABbS2[3], A[3], Bb[3], S[2]);

  nor E0gate(E[0], ABS3[0], ABbS2[0]);
  nor E1gate(E[1], ABS3[1], ABbS2[1]);
  nor E2gate(E[2], ABS3[2], ABbS2[2]);
  nor E3gate(E[3], ABS3[3], ABbS2[3]);

endmodule /* Emodule */

/*************************************************************************/

module Dmodule (A, B, Bb, S, D);

  input [3:0] A, B, Bb, S;
  output [3:0] D;
  wire [3:0]  BbS1, BS0;  

  and BbS10gate(BbS1[0], Bb[0], S[1]);
  and BbS11gate(BbS1[1], Bb[1], S[1]);
  and BbS12gate(BbS1[2], Bb[2], S[1]);
  and BbS13gate(BbS1[3], Bb[3], S[1]);

  and BS00gate(BS0[0], B[0], S[0]);
  and BS01gate(BS0[1], B[1], S[0]);
  and BS02gate(BS0[2], B[2], S[0]);
  and BS03gate(BS0[3], B[3], S[0]);

  nor D0gate(D[0], BbS1[0], BS0[0], A[0]);
  nor D1gate(D[1], BbS1[1], BS0[1], A[1]);
  nor D2gate(D[2], BbS1[2], BS0[2], A[2]);
  nor D3gate(D[3], BbS1[3], BS0[3], A[3]);

endmodule /* Dmodule */

/*************************************************************************/

module CLAmodule(Gb, Pb, CNb, C, X, Y, CN4b);

  input [3:0] Gb, Pb;
  input CNb; 
  output [3:0] C;
  output X, Y, CN4b;

   wire  Pb0, Pb1, Pb2, Pb3;
   wire  Pb0Gb1, Pb1Gb2, Pb2Gb3;
   wire  Pb0Gb12, Pb1Gb23, Pb0Gb123;
   wire  CNbGb0, CNbGb01, CNbGb012;
   wire  XCNb;
   
  not C0gate(C[0], CNb);

  buf Pb0gate(Pb0, Pb[0]);
  and CNbGb0gate(CNbGb0, CNb, Gb[0]);

  buf Pb1gate(Pb1, Pb[1]);
  and Pb0Gb1gate(Pb0Gb1, Pb[0], Gb[1]);
  and CNbGb01gate(CNbGb01, CNb, Gb[0], Gb[1]);

  buf Pb2gate(Pb2, Pb[2]);
  and Pb1Gb2gate(Pb1Gb2, Pb[1], Gb[2]);
  and Pb0Gb12gate(Pb0Gb12, Pb[0], Gb[1], Gb[2]);
  and CNbGb012gate(CNbGb012, CNb, Gb[0], Gb[1], Gb[2]);

  buf Pb3gate(Pb3, Pb[3]);
  and Pb2Gb3gate(Pb2Gb3, Pb[2], Gb[3]);
  and Pb1Gb23gate(Pb1Gb23, Pb[1], Gb[2], Gb[3]);
  and Pb0Gb123gate(Pb0Gb123, Pb[0], Gb[1], Gb[2], Gb[3]);

  nand Xgate(X, Gb[0], Gb[1], Gb[2], Gb[3]);

  nor Ygate(Y, Pb3,Pb2Gb3,Pb1Gb23,Pb0Gb123);
  nand XCNbgate(XCNb, Gb[0], Gb[1], Gb[2], Gb[3], CNb);

  nand CN4bgate(CN4b, Y, XCNb);

  nor C3gate(C[3], Pb2, Pb1Gb2, Pb0Gb12, CNbGb012);

  nor C2gate(C[2], Pb1, Pb0Gb1, CNbGb01);

  nor C1gate(C[1], Pb0, CNbGb0);

endmodule /* CLAmodule */

/*************************************************************************/

module Summodule(E, D, C, M, F, AEB);

  input [3:0] E, D, C;
  input M; 
  output [3:0] F;
  output AEB;
  wire [3:0] EXD, CM;

  xor EXD0gate(EXD[0], E[0], D[0]);
  xor EXD1gate(EXD[1], E[1], D[1]);
  xor EXD2gate(EXD[2], E[2], D[2]);
  xor EXD3gate(EXD[3], E[3], D[3]);

  or CM0gate(CM[0], C[0], M);
  or CM1gate(CM[1], C[1], M);
  or CM2gate(CM[2], C[2], M);
  or CM3gate(CM[3], C[3], M);

  xor F0gate(F[0], EXD[0], CM[0]);
  xor F1gate(F[1], EXD[1], CM[1]);
  xor F2gate(F[2], EXD[2], CM[2]);
  xor F3gate(F[3], EXD[3], CM[3]);

//  and AEBgate(AEB, F[0], F[1], F[2], F[3]);
//  assign (strong0, weak1) AEB = F[0] & F[1] & F[2] & F[3];
   assign AEB = F[0] & F[1] & F[2] & F[3];

endmodule /* Summodule */
