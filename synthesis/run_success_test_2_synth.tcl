# run_success_test_2_synth.tcl
# Automates source additions, top configuration, and synthesis for success_test_2

set proj_path "E:/QUANTA_VLSI/success_test_2/success_test_2.xpr"
puts "=== Opening project $proj_path ==="
open_project $proj_path

# Add missing design sources
puts "=== Adding design sources ==="
add_files -norecurse -fileset sources_1 {
    F:/QUANTA_2/tb/cnn_top_vivado.v
}

# Add constraints
puts "=== Adding constraints ==="
add_files -norecurse -fileset constrs_1 {
    F:/QUANTA_2/synthesis/vlsi_constr.xdc
}

# Add simulation testbench for digit 3
puts "=== Adding simulation sources ==="
add_files -norecurse -fileset sim_1 {
    F:/QUANTA_2/tb/tb_vivado_mnist_digit3.v
}

# Configure top modules
puts "=== Configuring Top Modules ==="
set_property top cnn_top [current_fileset]
set_property top tb_vivado_mnist_digit3 [get_filesets sim_1]
set_property xsim.simulate.runtime {7500us} [get_filesets sim_1]

# Update compile order
update_compile_order -fileset sources_1
update_compile_order -fileset sim_1

# Reset and Launch Synthesis
puts "=== Resetting and launching synth_1 ==="
reset_run synth_1
launch_runs synth_1 -jobs 8
wait_on_run synth_1

set synth_status [get_property STATUS [get_runs synth_1]]
set synth_progress [get_property PROGRESS [get_runs synth_1]]
puts "=== Synthesis Status: $synth_status ($synth_progress) ==="

if {[string match "*Complete*" $synth_status]} {
    puts "=== Generating Synthesis Reports ==="
    open_run synth_1 -name synth_1
    report_utilization -file "E:/QUANTA_VLSI/success_test_2/utilization_synth.rpt"
    report_timing_summary -file "E:/QUANTA_VLSI/success_test_2/timing_synth.rpt"
    close_design
    puts "SYNTHESIS_AND_REPORTING_COMPLETED_SUCCESSFULLY"
} else {
    puts "SYNTHESIS_FAILED_OR_INCOMPLETE"
}

close_project
