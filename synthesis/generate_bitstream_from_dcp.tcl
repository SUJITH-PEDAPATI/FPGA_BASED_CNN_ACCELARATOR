# generate_bitstream_from_dcp.tcl
puts "=== Opening postroute physopt checkpoint ==="
open_checkpoint {E:/QUANTA_VLSI/success_test_2/success_test_2.runs/impl_1/vlsi_design_wrapper_postroute_physopt.dcp}

puts "=== Applying physical pin constraints to clk_0 ==="
set_property PACKAGE_PIN Y9 [get_ports clk_0]
set_property IOSTANDARD LVCMOS33 [get_ports clk_0]

puts "=== Routing clock net to pin Y9 ==="
route_design

puts "=== Writing debug probes ==="
write_debug_probes -force {F:/QUANTA_2/debug_nets_digit3.ltx}

puts "=== Writing bitstream ==="
write_bitstream -force {F:/QUANTA_2/vlsi_design_wrapper_digit3.bit}

puts "=== Bitstream and debug nets generated successfully ==="
exit
