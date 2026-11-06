# run_vivado_sim.tcl
puts "=== Opening Vivado project cnn_accelerator ==="
open_project F:/QUANTA_2/testfor9/vivado_project/cnn_accelerator.xpr

puts "=== Configuring Simulation Settings ==="
set_property top tb_vivado_mnist [get_filesets sim_1]
set_property top_lib xil_defaultlib [get_filesets sim_1]
set_property -name {xsim.simulate.runtime} -value {7500us} -objects [get_filesets sim_1]

puts "=== Launching Vivado Behavioral Simulation ==="
launch_simulation -simset sim_1 -mode behavioral

puts "=== Running Simulation for 7500us ==="
run 7500us

puts "=== Simulation Finished ==="
close_sim
close_project
exit

