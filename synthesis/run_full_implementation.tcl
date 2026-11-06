# run_full_implementation.tcl
set proj_path "E:/QUANTA_VLSI/success_test_2/success_test_2.xpr"
puts "=== Opening project $proj_path ==="
open_project $proj_path

# Ensure cnn_top source is added
add_files -norecurse -fileset sources_1 {
    F:/QUANTA_2/tb/cnn_top_vivado.v
}
update_compile_order -fileset sources_1

set bd_file [get_files *vlsi_design.bd]
open_bd_design $bd_file

# Set image file to digit 3
puts "=== Configuring pixel_controller for Digit 3 ==="
set pc_cell [get_bd_cells pixel_controller_0]
set_property -dict [list CONFIG.IMAGE_FILE {F:/QUANTA_2/test/image_input_3.mem}] $pc_cell

validate_bd_design
save_bd_design

# Create HDL wrapper and generate targets
puts "=== Generating wrapper and all targets ==="
make_wrapper -files $bd_file -top -import -force
generate_target all $bd_file -force
export_ip_user_files -of_objects $bd_file -no_script -sync -force -quiet

set_property top vlsi_design_wrapper [current_fileset]
update_compile_order -fileset sources_1

# Launch implementation and write bitstream
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
