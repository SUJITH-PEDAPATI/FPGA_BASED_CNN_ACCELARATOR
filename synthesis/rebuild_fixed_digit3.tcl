# rebuild_fixed_digit3.tcl
set proj_path "E:/QUANTA_VLSI/success_test_2/success_test_2.xpr"
puts "=== Opening project $proj_path ==="
open_project $proj_path

set bd_file [get_files *vlsi_design.bd]
open_bd_design $bd_file

puts "=== Updating Module Reference for pixel_controller ==="
update_module_reference [get_ips *pixel_controller*]
save_bd_design

puts "=== Generating targets ==="
generate_target all $bd_file
export_ip_user_files -of_objects $bd_file -no_script -sync -force -quiet

puts "=== Resetting runs and launching implementation to bitstream ==="
reset_run synth_1
set_property strategy "Performance_ExplorePostRoutePhysOpt" [get_runs impl_1]
launch_runs impl_1 -to_step write_bitstream -jobs 8
wait_on_run impl_1

set impl_status [get_property STATUS [get_runs impl_1]]
set impl_progress [get_property PROGRESS [get_runs impl_1]]
puts "=== Implementation Status: $impl_status ($impl_progress) ==="

set bit_file [glob -nocomplain "E:/QUANTA_VLSI/success_test_2/success_test_2.runs/impl_1/*.bit"]
if {[llength $bit_file] > 0} {
    puts "BITSTREAM_SUCCESS: [lindex $bit_file 0]"
    file copy -force [lindex $bit_file 0] "F:/QUANTA_2/vlsi_design_wrapper_digit3.bit"
    puts "COPIED_TO: F:/QUANTA_2/vlsi_design_wrapper_digit3.bit"
} else {
    puts "NO_BITSTREAM_GENERATED"
}

close_project
