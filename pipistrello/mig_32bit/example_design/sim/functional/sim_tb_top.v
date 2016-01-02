//*****************************************************************************
// (c) Copyright 2009 Xilinx, Inc. All rights reserved.
//
// This file contains confidential and proprietary information
// of Xilinx, Inc. and is protected under U.S. and
// international copyright and other intellectual property
// laws.
//
// DISCLAIMER
// This disclaimer is not a license and does not grant any
// rights to the materials distributed herewith. Except as
// otherwise provided in a valid license issued to you by
// Xilinx, and to the maximum extent permitted by applicable
// law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
// WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
// AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
// BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
// INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
// (2) Xilinx shall not be liable (whether in contract or tort,
// including negligence, or under any other theory of
// liability) for any loss or damage of any kind or nature
// related to, arising under or in connection with these
// materials, including for any direct, or any indirect,
// special, incidental, or consequential loss or damage
// (including loss of data, profits, goodwill, or any type of
// loss or damage suffered as a result of any action brought
// by a third party) even if such damage or loss was
// reasonably foreseeable or Xilinx had been advised of the
// possibility of the same.
//
// CRITICAL APPLICATIONS
// Xilinx products are not designed or intended to be fail-
// safe, or for use in any application requiring fail-safe
// performance, such as life-support or safety devices or
// systems, Class III medical devices, nuclear facilities,
// applications related to the deployment of airbags, or any
// other applications that could lead to death, personal
// injury, or severe property or environmental damage
// (individually and collectively, "Critical
// Applications"). Customer assumes the sole risk and
// liability of any use of Xilinx products in Critical
// Applications, subject only to applicable laws and
// regulations governing limitations on product liability.
//
// THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
// PART OF THIS FILE AT ALL TIMES.
//
//*****************************************************************************
//   ____  ____
//  /   /\/   /
// /___/  \  /   Vendor             : Xilinx
// \   \   \/    Version            : 3.92
//  \   \        Application        : MIG
//  /   /        Filename           : sim_tb_top.v
// /___/   /\    Date Last Modified : $Date: 2011/06/02 07:17:22 $
// \   \  /  \   Date Created       : Mon Mar 2 2009
//  \___\/\___\
//
// Device      : Spartan-6
// Design Name : DDR/DDR2/DDR3/LPDDR
// Purpose     : This is the simulation testbench which is used to verify the
//               design. The basic clocks and resets to the interface are
//               generated here. This also connects the memory interface to the
//               memory model.
//*****************************************************************************

`timescale 1ps/1ps
module sim_tb_top;

// ========================================================================== //
// Parameters                                                                 //
// ========================================================================== //
   parameter DEBUG_EN                = 0;
   localparam DBG_WR_STS_WIDTH       = 32;
   localparam DBG_RD_STS_WIDTH       = 32;
   	parameter C3_MEMCLK_PERIOD     = 5000;
   parameter C3_RST_ACT_LOW        = 0;
   parameter C3_INPUT_CLK_TYPE     = "SINGLE_ENDED";
   parameter C3_NUM_DQ_PINS        = 16;
   parameter C3_MEM_ADDR_WIDTH     = 13;
   parameter C3_MEM_BANKADDR_WIDTH = 2;
   parameter C3_MEM_ADDR_ORDER     = "ROW_BANK_COLUMN"; 
      parameter C3_P0_MASK_SIZE       = 4;
   parameter C3_P0_DATA_PORT_SIZE  = 32;  
   parameter C3_P1_MASK_SIZE       = 4;
   parameter C3_P1_DATA_PORT_SIZE  = 32;
   parameter C3_CALIB_SOFT_IP      = "TRUE";
   parameter C3_SIMULATION      = "TRUE";
   parameter C3_HW_TESTING      = "FALSE";

// ========================================================================== //
// Signal Declarations                                                        //
// ========================================================================== //
 // Clocks
   reg                              c3_sys_clk;
   wire                             c3_sys_clk_p;
   wire                             c3_sys_clk_n;
// System Reset
   reg                              c3_sys_rst;
   wire                             c3_sys_rst_i;

// Design-Top Port Map
   wire [C3_MEM_ADDR_WIDTH-1:0]     mcb3_dram_a; 
   wire [C3_MEM_BANKADDR_WIDTH-1:0] mcb3_dram_ba;   
   wire                             mcb3_dram_ck;  
   wire                             mcb3_dram_ck_n;
   wire [C3_NUM_DQ_PINS-1:0]        mcb3_dram_dq;   
   wire                             mcb3_dram_dqs;  
   wire                             mcb3_dram_dm; 
   wire                             mcb3_dram_ras_n; 
   wire                             mcb3_dram_cas_n; 
   wire                             mcb3_dram_we_n;  
   wire                             mcb3_dram_cke; 

   wire                              mcb3_dram_udqs;    // for X16 parts
   wire                             mcb3_dram_udm;     // for X16 parts

// Error & Calib Signals
   wire                             error;
   wire                             calib_done;
   wire				    rzq3;
      
   
// ========================================================================== //
// Clocks Generation                                                          //
// ========================================================================== //

   initial
      c3_sys_clk = 1'b0;
   always
      #(C3_MEMCLK_PERIOD/2) c3_sys_clk = ~c3_sys_clk;

   assign                c3_sys_clk_p = c3_sys_clk;
   assign                c3_sys_clk_n = ~c3_sys_clk;

// ========================================================================== //
// Reset Generation                                                           //
// ========================================================================== //

   initial begin
      c3_sys_rst = 1'b0;		
      #20000;
      c3_sys_rst = 1'b1;
   end
   assign c3_sys_rst_i = C3_RST_ACT_LOW ? c3_sys_rst : ~c3_sys_rst;

// ========================================================================== //
// Error Grouping                                                           //
// ========================================================================== //



   

   PULLDOWN rzq_pulldown3 (.O(rzq3));
      

// ========================================================================== //
// DESIGN TOP INSTANTIATION                                                    //
// ========================================================================== //



example_top #(

.C3_P0_MASK_SIZE       (C3_P0_MASK_SIZE      ),
.C3_P0_DATA_PORT_SIZE  (C3_P0_DATA_PORT_SIZE ),
.C3_P1_MASK_SIZE       (C3_P1_MASK_SIZE      ),
.C3_P1_DATA_PORT_SIZE  (C3_P1_DATA_PORT_SIZE ),
.C3_MEMCLK_PERIOD      (C3_MEMCLK_PERIOD),
.C3_RST_ACT_LOW        (C3_RST_ACT_LOW),
.C3_INPUT_CLK_TYPE     (C3_INPUT_CLK_TYPE),

 
.DEBUG_EN              (DEBUG_EN),

.C3_MEM_ADDR_ORDER     (C3_MEM_ADDR_ORDER    ),
.C3_NUM_DQ_PINS        (C3_NUM_DQ_PINS       ),
.C3_MEM_ADDR_WIDTH     (C3_MEM_ADDR_WIDTH    ),
.C3_MEM_BANKADDR_WIDTH (C3_MEM_BANKADDR_WIDTH),

.C3_HW_TESTING         (C3_HW_TESTING),
.C3_SIMULATION         (C3_SIMULATION),
.C3_CALIB_SOFT_IP      (C3_CALIB_SOFT_IP )
)
design_top (

    .c3_sys_clk           (c3_sys_clk),
  .c3_sys_rst_i           (c3_sys_rst_i),                        

  .mcb3_dram_dq           (mcb3_dram_dq),  
  .mcb3_dram_a            (mcb3_dram_a),  
  .mcb3_dram_ba           (mcb3_dram_ba),
  .mcb3_dram_ras_n        (mcb3_dram_ras_n),                        
  .mcb3_dram_cas_n        (mcb3_dram_cas_n),                        
  .mcb3_dram_we_n         (mcb3_dram_we_n),                          
  .mcb3_dram_cke          (mcb3_dram_cke),                          
  .mcb3_dram_ck           (mcb3_dram_ck),                          
  .mcb3_dram_ck_n         (mcb3_dram_ck_n),                          
    .calib_done                               (calib_done),
  .error                                    (error),	
  .mcb3_dram_udqs         (mcb3_dram_udqs),    // for X16 parts
  .mcb3_dram_udm          (mcb3_dram_udm),     // for X16 parts
  .mcb3_dram_dm           (mcb3_dram_dm),
  
  .mcb3_rzq               (rzq3),
               
  .mcb3_dram_dqs          (mcb3_dram_dqs)
);      



// ========================================================================== //
// Memory model instances                                                     // 
// ========================================================================== //

   generate
   if(C3_NUM_DQ_PINS == 16) begin : MEM_INST3
     lpddr_model_c3 u_mem3(
      .Dq    (mcb3_dram_dq),
      .Dqs   ({mcb3_dram_udqs,mcb3_dram_dqs}),
      .Addr  (mcb3_dram_a),
      .Ba    (mcb3_dram_ba),
      .Clk   (mcb3_dram_ck),
      .Clk_n (mcb3_dram_ck_n),
      .Cke   (mcb3_dram_cke),
      .Cs_n  (1'b0),
      .Ras_n (mcb3_dram_ras_n),
      .Cas_n (mcb3_dram_cas_n),
      .We_n  (mcb3_dram_we_n),
      .Dm    ({mcb3_dram_udm,mcb3_dram_dm})
      );
   end else begin
     lpddr_model_c3 u_mem3(
      .Dq    (mcb3_dram_dq),
      .Dqs   (mcb3_dram_dqs),
      .Addr  (mcb3_dram_a),
      .Ba    (mcb3_dram_ba),
      .Clk   (mcb3_dram_ck),
      .Clk_n (mcb3_dram_ck_n),
      .Cke   (mcb3_dram_cke),
      .Cs_n  (1'b0),
      .Ras_n (mcb3_dram_ras_n),
      .Cas_n (mcb3_dram_cas_n),
      .We_n  (mcb3_dram_we_n),
      .Dm    (mcb3_dram_dm)
      );
  end
endgenerate

// ========================================================================== //
// Reporting the test case status 
// ========================================================================== //
   initial
   begin : Logging
      fork
         begin : calibration_done
            wait (calib_done);
            $display("Calibration Done");
            #50000000;
            if (!error) begin
               $display("TEST PASSED");
            end   
            else begin
               $display("TEST FAILED: DATA ERROR");		 
            end
            disable calib_not_done;
	    $finish;
         end	 
         
         begin : calib_not_done
            #200000000;
            if (!calib_done) begin
               $display("TEST FAILED: INITIALIZATION DID NOT COMPLETE");
            end
            disable calibration_done;
	    $finish;
         end
      join	 
   end      

endmodule
