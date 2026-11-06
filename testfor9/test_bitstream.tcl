open_checkpoint F:/QUANTA_2/testfor9/vivado_project/cnn_accelerator.runs/impl_1/vlsi_design_wrapper_postroute_physopt.dcp
set_property BITSTREAM.General.UnconstrainedPins {Allow} [current_design]
write_bitstream -force F:/QUANTA_2/testfor9/vivado_project/cnn_accelerator.runs/impl_1/vlsi_design_wrapper.bit
puts "Bitstream generated successfully!"
exit 0

