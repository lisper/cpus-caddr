/*
PB0GB0
PB0GB01
PB0GB012
PB1GB1
PB1GB12
PB1GB123
PB2GB2
PB2GB23
PB3GB3

CNB
CNBGB0
CNBGB01
CNBGB012

GB0123
*/
/****************************************************************************
 *                                                                          *
 *  VERILOG HIGH-LEVEL DESCRIPTION OF THE TI 74182 CIRCUIT                  *
 *                                                                          *
 *  Function: Carry Lookahead Generator                                     *
 *                                                                          *
 *  Written by: Mark C. Hansen                                              *
 *                                                                          *
 *  Last modified: Dec 10, 1997                                             *
 *                                                                          *
 ****************************************************************************/

module ic_74S182 (CIN_N, X, Y, XOUT, YOUT, COUT0_N, COUT1_N, COUT2_N);

  input[3:0]    X, Y;
  input	        CIN_N;
  output	XOUT, YOUT, COUT0_N, COUT1_N, COUT2_N;
	
  TopLevel74182 Ckt74182 (CIN_N, X, Y, XOUT, YOUT, COUT0_N, COUT1_N, COUT2_N);

endmodule /* Circuit74182 */

/*************************************************************************/

module TopLevel74182 (CN, PB, GB, PBo, GBo, CNX, CNY, CNZ);

  input[3:0]	PB, GB;
  input         CN;

  output	PBo, GBo, CNX, CNY, CNZ;

   wire 	PB0GB0, PB0GB01, PB0GB012;
   wire 	PB1GB1, PB1GB12, PB1GB123;
   wire 	PB2GB2, PB2GB23, PB3GB3;
   wire 	CNB, CNBGB0, CNBGB01, CNBGB012;
   wire 	GB0123;

  not CNBgate(CNB, CN);

  and PB0GB0gate(PB0GB0, PB[0], GB[0]);
  and CNBGB0gate(CNBGB0, CNB, GB[0]);

  and PB1GB1gate(PB1GB1, PB[1], GB[1]);
  and PB0GB01gate(PB0GB01, PB[0], GB[0], GB[1]);
  and CNBGB01gate(CNBGB01, CNB, GB[0], GB[1]);

  and PB2GB2gate(PB2GB2, PB[2], GB[2]);
  and PB1GB12gate(PB1GB12, PB[1], GB[1], GB[2]);
  and PB0GB012gate(PB0GB012, PB[0], GB[0], GB[1], GB[2]);
  and CNBGB012gate(CNBGB012, CNB, GB[0], GB[1], GB[2]);

  and PB3GB3gate(PB3GB3, PB[3], GB[3]);
  and PB2GB23gate(PB2GB23, PB[2], GB[2], GB[3]);
  and PB1GB123gate(PB1GB123, PB[1], GB[1], GB[2], GB[3]);
  and GB0123gate(GB0123, GB[0], GB[1], GB[2], GB[3]);

  or PBogate(PBo,PB[0],PB[1],PB[2],PB[3]);

  or GBogate(GBo,PB3GB3,PB2GB23,PB1GB123,GB0123);

  nor CNZgate(CNZ,PB2GB2,PB1GB12,PB0GB012,CNBGB012);

  nor CNYgate(CNY,PB1GB1,PB0GB01,CNBGB01);

  nor CNXgate(CNX,PB0GB0,CNBGB0);


endmodule /* TopLevel74182 */

