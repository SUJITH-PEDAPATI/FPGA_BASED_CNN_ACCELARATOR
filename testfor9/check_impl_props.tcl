open_project F:/QUANTA_2/testfor9/vivado_project/cnn_accelerator.xpr
set run [get_runs impl_1]
puts "=== IMPL_1 PROPERTIES ==="
puts "STATUS:       [get_property STATUS $run]"
puts "PROGRESS:     [get_property PROGRESS $run]"
puts "STATS.WNS:    [get_property STATS.WNS $run]"
puts "STATS.TNS:    [get_property STATS.TNS $run]"
puts "STATS.WHS:    [get_property STATS.WHS $run]"
puts "STATS.THS:    [get_property STATS.THS $run]"
puts "STRATEGY:     [get_property STRATEGY $run]"
close_project
exit

