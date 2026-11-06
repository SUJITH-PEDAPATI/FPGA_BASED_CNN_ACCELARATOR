# ============================================================
# QUANTA_2 CNN Accelerator
# Target:  Digilent ZedBoard - Zynq-7000 (xc7z020clg484-1)
# Top:     vlsi_design_wrapper (Block Design with VIO + ILA)
#
# Physical pin: Onboard 100 MHz oscillator (pin Y9, LVCMOS33)
# Note: clk_0 is the external port for vlsi_design_wrapper;
#       clk is the standalone port for cnn_top.
# ============================================================

# 100 MHz PL clock on ZedBoard pin Y9
set_property -dict { PACKAGE_PIN Y9 IOSTANDARD LVCMOS33 } [get_ports -quiet {clk_0 clk}]
create_clock -name sys_clk -period 10.000 -waveform {0.000 5.000} [get_ports -quiet {clk_0 clk}]