open_project F:/QUANTA_2/testfor9/vivado_project/cnn_accelerator.xpr
puts "=================== ALL RUNS ==================="
foreach r [get_runs] {
    set st [get_property STATUS $r]
    set wns [get_property -quiet STATS.WNS $r]
    set tns [get_property -quiet STATS.TNS $r]
    set whs [get_property -quiet STATS.WHS $r]
    puts [format "%-40s | %-35s | WNS: %-8s | TNS: %-8s | WHS: %-8s" $r $st $wns $tns $whs]
}
puts "================================================"
close_project
exit 0

