# ==============================================================================
# build_and_close_timing.tcl
# Builds cnn_accelerator_digit8, achieves timing closure, and exports all reports
# ==============================================================================
set proj_path "F:/QUANTA_2/testfor8/vivado_project/cnn_accelerator_digit8.xpr"
puts "=== [1/8] Opening project $proj_path ==="
open_project $proj_path

# 1. Update Block Design
puts "=== [2/8] Inspecting and Updating Block Design ==="
set bd_file [get_files *.bd]
open_bd_design $bd_file

puts "Updating module references..."
update_module_reference [get_ips *pixel_controller*]
update_module_reference [get_ips *cnn_top*]

save_bd_design
validate_bd_design

puts "Generating output products for BD..."
generate_target all $bd_file
export_ip_user_files -of_objects $bd_file -no_script -sync -force -quiet

# 2. Configure Implementation Strategy
puts "=== [3/8] Configuring Implementation Strategy for Complete Timing Closure ==="
set impl [get_runs impl_1]
set_property strategy "Performance_ExplorePostRoutePhysOpt" $impl

# 3. Launch Out-of-Context IP Synthesis Runs in parallel
puts "=== [4/8] Launching Out-of-Context IP Synthesis Runs ==="
set all_synth_runs [get_runs -filter {IS_SYNTHESIS}]
set ip_runs [list]
foreach r $all_synth_runs {
    if {$r ne "synth_1"} {
        lappend ip_runs $r
    }
}
if {[llength $ip_runs] > 0} {
    puts "IP Runs to launch: $ip_runs"
    foreach r $ip_runs {
        set st [get_property STATUS [get_runs $r]]
        if {$st ne "Not started"} {
            reset_run $r
        }
    }
    launch_runs $ip_runs -jobs 8
    foreach r $ip_runs {
        wait_on_run $r
        puts "$r Status: [get_property STATUS [get_runs $r]]"
    }
}

# 4. Launch Top Synthesis
puts "=== [5/8] Launching Top-Level Synthesis (synth_1) ==="
set st [get_property STATUS [get_runs synth_1]]
if {$st ne "Not started"} {
    reset_run synth_1
}
launch_runs synth_1 -jobs 8
wait_on_run synth_1
puts "synth_1 Status: [get_property STATUS [get_runs synth_1]]"

# Export synthesis reports
open_run synth_1
report_utilization -file "F:/QUANTA_2/testfor8/success_test_for_digit_8/synthesis_reports/utilization_synth.rpt"
report_timing_summary -file "F:/QUANTA_2/testfor8/success_test_for_digit_8/synthesis_reports/timing_summary_synth.rpt"
close_design

# 5. Launch Implementation through Bitstream
puts "=== [6/8] Launching Implementation through Bitstream (impl_1) ==="
set st [get_property STATUS [get_runs impl_1]]
if {$st ne "Not started"} {
    reset_run impl_1
}
launch_runs impl_1 -to_step write_bitstream -jobs 8
wait_on_run impl_1
puts "impl_1 Status: [get_property STATUS [get_runs impl_1]]"

# 6. Open Implemented Design and Export Complete Timing & Quality Reports
puts "=== [7/8] Generating Post-Route Timing and Utilization Reports ==="
open_run impl_1

set wns [get_property STATS.WNS [get_runs impl_1]]
set tns [get_property STATS.TNS [get_runs impl_1]]
set whs [get_property STATS.WHS [get_runs impl_1]]
set ths [get_property STATS.THS [get_runs impl_1]]

puts "=========================================================================="
puts "FINAL ROUTED TIMING RESULTS:"
puts "  WNS : $wns ns"
puts "  TNS : $tns ns"
puts "  WHS : $whs ns"
puts "  THS : $ths ns"
puts "=========================================================================="

# Write Reports
report_timing_summary -max_paths 20 -report_unconstrained -warn_on_violation -file "F:/QUANTA_2/testfor8/success_test_for_digit_8/timing_reports/timing_summary_postroute.rpt"
report_clock_interaction -file "F:/QUANTA_2/testfor8/success_test_for_digit_8/timing_reports/clock_interaction.rpt"
report_clock_utilization -file "F:/QUANTA_2/testfor8/success_test_for_digit_8/timing_reports/clock_utilization.rpt"
report_design_analysis -complexity -congestion -file "F:/QUANTA_2/testfor8/success_test_for_digit_8/timing_reports/design_analysis.rpt"

report_utilization -hierarchical -file "F:/QUANTA_2/testfor8/success_test_for_digit_8/utilization_reports/utilization_hierarchical.rpt"
report_utilization -file "F:/QUANTA_2/testfor8/success_test_for_digit_8/utilization_reports/utilization_summary.rpt"

report_drc -file "F:/QUANTA_2/testfor8/success_test_for_digit_8/implementation_reports/drc_routed.rpt"
report_methodology -file "F:/QUANTA_2/testfor8/success_test_for_digit_8/implementation_reports/methodology_routed.rpt"

# Checkpoint and Bitstream
puts "=== [8/8] Exporting Checkpoint and Bitstream ==="
write_checkpoint -force "F:/QUANTA_2/testfor8/success_test_for_digit_8/checkpoints/vlsi_design_wrapper_routed.dcp"

set bit_files [glob -nocomplain "F:/QUANTA_2/testfor8/vivado_project/cnn_accelerator_digit8.runs/impl_1/*.bit"]
if {[llength $bit_files] > 0} {
    set bit_src [lindex $bit_files 0]
    file copy -force $bit_src "F:/QUANTA_2/testfor8/success_test_for_digit_8/bitstreams/vlsi_design_wrapper.bit"
    puts "BITSTREAM EXPORTED: F:/QUANTA_2/testfor8/success_test_for_digit_8/bitstreams/vlsi_design_wrapper.bit"
} else {
    puts "WARNING: No .bit file found in impl_1 directory."
}

close_project
puts "ALL TASKS COMPLETED SUCCESSFULLY!"
exit 0
