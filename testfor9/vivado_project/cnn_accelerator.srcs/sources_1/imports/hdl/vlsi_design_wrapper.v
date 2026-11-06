//Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
//Copyright 2022-2026 Advanced Micro Devices, Inc. All Rights Reserved.
//--------------------------------------------------------------------------------
//Tool Version: Vivado v.2026.1 (win64) Build 6511674 Tue Jun 16 11:02:23 MDT 2026
//Date        : Tue Oct 27 19:05:33 2026
//Host        : DESKTOP-RNBVV56 running 64-bit major release  (build 9200)
//Command     : generate_target vlsi_design_wrapper.bd
//Design      : vlsi_design_wrapper
//Purpose     : IP block netlist
//--------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

module vlsi_design_wrapper
   (clk_0);
  input clk_0;

  wire clk_0;

  vlsi_design vlsi_design_i
       (.clk_0(clk_0));
endmodule
