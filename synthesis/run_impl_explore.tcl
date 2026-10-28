# =============================================================================
# run_impl_explore.tcl
# QUANTA_2 -- Run implementation with Performance_ExplorePostRoutePhysOpt
# To close residual -0.943 ns setup slack and achieve timing closure at 100 MHz
# =============================================================================

set proj_path "E:/QUANTA_VLSI/success_test_1/success_test_1.xpr"
puts "INFO: Opening project $proj_path"
open_project $proj_path

# Set strategy to Performance_ExplorePostRoutePhysOpt
puts "INFO: Configuring impl_1 with Performance_ExplorePostRoutePhysOpt"
set_property strategy "Performance_ExplorePostRoutePhysOpt" [get_runs impl_1]

# Reset impl_1 (synth_1 is already up-to-date and completed)
puts "INFO: Resetting impl_1"
reset_run impl_1

# Launch implementation through bitstream generation
puts "INFO: Launching impl_1 with write_bitstream (jobs 8)..."
launch_runs impl_1 -to_step write_bitstream -jobs 8

puts "INFO: Waiting for impl_1 to complete..."
wait_on_run impl_1

set impl_status [get_property STATUS [get_runs impl_1]]
set impl_progress [get_property PROGRESS [get_runs impl_1]]
puts "IMPL_STATUS: $impl_status"
puts "IMPL_PROGRESS: $impl_progress"

# Check routed timing summary
set rpt_files [glob -nocomplain "E:/QUANTA_VLSI/success_test_1/success_test_1.runs/impl_1/*timing_summary_routed.rpt"]
if {[llength $rpt_files] > 0} {
    set rpt [lindex $rpt_files 0]
    puts "TIMING_REPORT_FOUND: $rpt"
} else {
    puts "NO_ROUTED_TIMING_REPORT"
}

close_project
puts "DONE_EXPLORE_IMPL_RUN"
