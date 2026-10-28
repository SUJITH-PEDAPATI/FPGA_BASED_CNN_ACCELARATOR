create_project -in_memory -part xc7z020clg484-1
read_verilog -library xil_defaultlib {
  F:/QUANTA_2/rtl/argmax.v
  F:/QUANTA_2/rtl/conv_layer.v
  F:/QUANTA_2/rtl/fully_connected.v
  F:/QUANTA_2/rtl/quantization.v
  F:/QUANTA_2/tb/cnn_top_vivado.v
}
read_xdc F:/QUANTA_2/synthesis/vlsi_constr.xdc
synth_design -top cnn_top -part xc7z020clg484-1
report_utilization -file F:/QUANTA_2/synthesis/utilization_synth.rpt
report_io -file F:/QUANTA_2/synthesis/io_synth.rpt