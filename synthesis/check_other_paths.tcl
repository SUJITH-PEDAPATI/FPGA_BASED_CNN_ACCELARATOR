open_checkpoint E:/QUANTA_VLSI/success_test_1/success_test_1.runs/impl_1/vlsi_design_wrapper_routed.dcp

puts "=== TOP 15 VIOLATING PATHS ==="
set paths [get_timing_paths -max_paths 15 -slack_less_than 0]
foreach p $paths {
    set sp [get_property STARTPOINT_PIN $p]
    set ep [get_property ENDPOINT_PIN $p]
    set slk [get_property SLACK $p]
    puts "FAILING_PATH: Slack=$slk From=$sp To=$ep"
}

puts "=== CONV1 TIMING ==="
set c1_paths [get_timing_paths -max_paths 3 -from [get_cells -hier -filter {NAME =~ *u_conv1*}] -to [get_cells -hier -filter {NAME =~ *u_conv1*}]]
foreach p $c1_paths {
    puts "CONV1: Slack=[get_property SLACK $p] From=[get_property STARTPOINT_PIN $p] To=[get_property ENDPOINT_PIN $p]"
}

puts "=== FC TIMING ==="
set fc_paths [get_timing_paths -max_paths 3 -from [get_cells -hier -filter {NAME =~ *u_fc*}] -to [get_cells -hier -filter {NAME =~ *u_fc*}]]
foreach p $fc_paths {
    puts "FC: Slack=[get_property SLACK $p] From=[get_property STARTPOINT_PIN $p] To=[get_property ENDPOINT_PIN $p]"
}

puts "DONE_OTHER_PATHS"
