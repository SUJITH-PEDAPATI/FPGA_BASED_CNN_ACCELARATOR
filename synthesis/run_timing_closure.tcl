# =============================================================================
# run_timing_closure.tcl
# QUANTA_2 -- Re-synthesize cnn_top OOC module and run full implementation
# =============================================================================

set proj_path "E:/QUANTA_VLSI/success_test_1/success_test_1.xpr"
puts "INFO: Opening project $proj_path"
open_project $proj_path

# Update IP catalog so file changes are detected
puts "INFO: Refreshing IP catalog"
update_ip_catalog -rebuild -scan_changes

# Reset the CNN top OOC synthesis run so it incorporates our RTL changes
puts "INFO: Resetting vlsi_design_cnn_top_0_0_synth_1"
reset_run vlsi_design_cnn_top_0_0_synth_1

# Reset top-level synth and impl runs
puts "INFO: Resetting synth_1 and impl_1"
reset_run synth_1

# Launch implementation through bitstream generation
puts "INFO: Launching implementation with write_bitstream..."
launch_runs impl_1 -to_step write_bitstream -jobs 8

puts "INFO: Waiting for implementation to complete..."
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
puts "DONE_TIMING_CLOSURE_RUN"
