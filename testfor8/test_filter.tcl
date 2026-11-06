open_project F:/QUANTA_2/testfor8/vivado_project/cnn_accelerator_digit8.xpr
set all_synth_runs [get_runs -filter {IS_SYNTHESIS}]
puts "All synth runs: $all_synth_runs"
set ip_runs [list]
foreach r $all_synth_runs {
    if {$r ne "synth_1"} {
        lappend ip_runs $r
    }
}
puts "IP synth runs: $ip_runs"
close_project
exit 0

