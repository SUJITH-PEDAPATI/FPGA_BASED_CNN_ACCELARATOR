open_hw_manager
connect_hw_server -url localhost:3121
set target [lindex [get_hw_targets] 0]
puts "TARGET: $target"
if { [catch {open_hw_target $target} errmsg] } {
    puts "OPEN_ERROR: $errmsg"
} else {
    puts "DEVICES: [get_hw_devices]"
    close_hw_target
}
close_hw_manager

