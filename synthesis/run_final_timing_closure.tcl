# =============================================================================
# run_final_timing_closure.tcl
# QUANTA_2 -- Final timing closure with hardware DSP mapping and Explore flow
# =============================================================================

set proj_path "E:/QUANTA_VLSI/success_test_1/success_test_1.xpr"
puts "INFO: Opening project $proj_path"
open_project $proj_path

# Refresh IP catalog so file changes are detected
puts "INFO: Refreshing IP catalog"
update_ip_catalog -rebuild -scan_changes

# Reset the CNN top OOC synthesis run so it re-synthesizes with DSP48 multipliers
puts "INFO: Resetting vlsi_design_cnn_top_0_0_synth_1"
reset_run vlsi_design_cnn_top_0_0_synth_1

# Reset top-level synth and impl runs
puts "INFO: Resetting synth_1 and impl_1"
reset_run synth_1

# Configure impl_1 with Performance_ExplorePostRoutePhysOpt
puts "INFO: Configuring impl_1 with Performance_ExplorePostRoutePhysOpt"
set_property strategy "Performance_ExplorePostRoutePhysOpt" [get_runs impl_1]

# Launch full flow through bitstream generation
puts "INFO: Launching full flow with write_bitstream (jobs 8)..."
launch_runs impl_1 -to_step write_bitstream -jobs 8

puts "INFO: Waiting for impl_1 to complete..."
wait_on_run impl_1

set impl_status [get_property STATUS [get_runs impl_1]]
set impl_progress [get_property PROGRESS [get_runs impl_1]]
puts "IMPL_STATUS: $impl_status"
puts "IMPL_PROGRESS: $impl_progress"

# Report routed timing summary
set rpt_files [glob -nocomplain "E:/QUANTA_VLSI/success_test_1/success_test_1.runs/impl_1/*timing_summary_routed.rpt"]
if {[llength $rpt_files] > 0} {
    set rpt [lindex $rpt_files 0]
    puts "TIMING_REPORT_FOUND: $rpt"
} else {
    puts "NO_ROUTED_TIMING_REPORT"
}

# Save a permanent backup copy in F:/QUANTA_2/
set bit_file "E:/QUANTA_VLSI/success_test_1/success_test_1.runs/impl_1/vlsi_design_wrapper.bit"
if {[file exists $bit_file]} {
    file copy -force $bit_file "F:/QUANTA_2/vlsi_design_wrapper.bit"
    puts "BITSTREAM_BACKUP_SAVED: F:/QUANTA_2/vlsi_design_wrapper.bit"
}
set ltx_file "E:/QUANTA_VLSI/success_test_1/success_test_1.runs/impl_1/debug_nets.ltx"
if {[file exists $ltx_file]} {
    file copy -force $ltx_file "F:/QUANTA_2/debug_nets.ltx"
    puts "LTX_BACKUP_SAVED: F:/QUANTA_2/debug_nets.ltx"
}

close_project
puts "DONE_FINAL_TIMING_CLOSURE_RUN"
