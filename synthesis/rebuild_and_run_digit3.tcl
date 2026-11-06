# rebuild_and_run_digit3.tcl
set proj_path "E:/QUANTA_VLSI/success_test_1/success_test_1.xpr"
puts "=== Opening project $proj_path ==="
open_project $proj_path

puts "=== Updating IP Catalog ==="
update_ip_catalog -rebuild -scan_changes

puts "=== Resetting and running vlsi_design_pixel_controller_0_0_synth_1 ==="
reset_run vlsi_design_pixel_controller_0_0_synth_1
launch_runs vlsi_design_pixel_controller_0_0_synth_1 -jobs 8
wait_on_run vlsi_design_pixel_controller_0_0_synth_1

set pc_status [get_property STATUS [get_runs vlsi_design_pixel_controller_0_0_synth_1]]
puts "=== Pixel controller synth status: $pc_status ==="

puts "=== Resetting top-level synthesis and implementation ==="
reset_run synth_1

puts "=== Configuring impl_1 strategy ==="
set_property strategy "Performance_ExplorePostRoutePhysOpt" [get_runs impl_1]

puts "=== Launching impl_1 through write_bitstream ==="
launch_runs impl_1 -to_step write_bitstream -jobs 8
wait_on_run impl_1

set impl_status [get_property STATUS [get_runs impl_1]]
puts "=== Implementation status: $impl_status ==="

set bit_file "E:/QUANTA_VLSI/success_test_1/success_test_1.runs/impl_1/vlsi_design_wrapper.bit"
set ltx_file "E:/QUANTA_VLSI/success_test_1/success_test_1.runs/impl_1/debug_nets.ltx"

if {[file exists $bit_file]} {
    file copy -force $bit_file "F:/QUANTA_2/vlsi_design_wrapper_digit3.bit"
    file copy -force $bit_file "F:/QUANTA_2/vlsi_design_wrapper.bit"
    puts "=== Copied bitstream to F:/QUANTA_2/vlsi_design_wrapper_digit3.bit ==="
} else {
    puts "ERROR: Bitstream file was not created!"
    exit 1
}

if {[file exists $ltx_file]} {
    file copy -force $ltx_file "F:/QUANTA_2/debug_nets_digit3.ltx"
    file copy -force $ltx_file "F:/QUANTA_2/debug_nets.ltx"
    puts "=== Copied debug nets to F:/QUANTA_2/debug_nets_digit3.ltx ==="
}

close_project
puts "=== Project build complete ==="
exit

