open_hw_manager
connect_hw_server -url localhost:3121
puts "TARGETS: [get_hw_targets]"
foreach t [get_hw_targets] {
    puts "TARGET: $t | OPEN: [get_property IS_OPEN $t]"
}
close_hw_manager

