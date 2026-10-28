set proj_path "E:/QUANTA_VLSI/success_test_1/success_test_1.xpr"
open_project $proj_path

# Ensure output products are generated
generate_target all [get_files *vlsi_design.bd]
export_ip_user_files -of_objects [get_files *vlsi_design.bd] -no_script -sync -force -quiet

# Reset and launch runs
reset_run synth_1
launch_runs impl_1 -to_step write_bitstream -jobs 8
wait_on_run impl_1

puts "IMPL_STATUS: [get_property STATUS [get_runs impl_1]]"
puts "IMPL_PROGRESS: [get_property PROGRESS [get_runs impl_1]]"

# Check if timing summary report exists
set rpt_file [glob -nocomplain "E:/QUANTA_VLSI/success_test_1/success_test_1.runs/impl_1/*timing_summary_routed.rpt"]
if {[llength $rpt_file] > 0} {
    puts "TIMING_REPORT_FOUND: [lindex $rpt_file 0]"
} else {
    puts "NO_ROUTED_TIMING_REPORT"
}

close_project
