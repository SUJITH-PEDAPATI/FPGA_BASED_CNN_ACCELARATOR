open_checkpoint F:/QUANTA_2/testfor8/impl_1/vlsi_design_wrapper_postroute_physopt.dcp
set_property BITSTREAM.General.UnconstrainedPins {Allow} [current_design]
write_bitstream -force F:/QUANTA_2/testfor8/success_test_for_digit_8/bitstreams/vlsi_design_wrapper.bit
puts "BITSTREAM GENERATED SUCCESSFULLY!"
exit 0

