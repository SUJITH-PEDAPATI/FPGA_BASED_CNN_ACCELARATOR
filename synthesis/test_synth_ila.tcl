open_project E:/QUANTA_VLSI/success_test_1/success_test_1.xpr
puts "=== LAUNCHING ILA SYNTHESIS SUB-RUN ==="
launch_runs vlsi_design_ila_0_0_synth_1 -jobs 4
wait_on_run vlsi_design_ila_0_0_synth_1
set ila_status [get_property STATUS [get_runs vlsi_design_ila_0_0_synth_1]]
puts "ILA_SYNTH_STATUS: $ila_status"
close_project
