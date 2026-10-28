open_project E:/QUANTA_VLSI/success_test_1/success_test_1.xpr
puts "=== PROJECT RUNS ==="
foreach r [get_runs] {
    puts "RUN: $r | STATUS: [get_property STATUS $r] | PROGRESS: [get_property PROGRESS $r] | NEEDS_REFRESH: [get_property NEEDS_REFRESH $r]"
}
puts "=== BD FILES ==="
set bd [get_files *vlsi_design.bd]
puts "BD: $bd"
puts "SYNTH_CHECKPOINT_MODE: [get_property synth_checkpoint_mode $bd]"
close_project
