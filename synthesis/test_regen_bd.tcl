open_project E:/QUANTA_VLSI/success_test_1/success_test_1.xpr
open_bd_design [get_files *vlsi_design.bd]

puts "=== EXPORT IP USER FILES ==="
export_ip_user_files -of_objects [get_files *vlsi_design.bd] -no_script -sync -force -quiet

puts "=== GENERATE TARGET ALL ==="
generate_target all [get_files *vlsi_design.bd]

puts "=== CREATE / UPDATE HDL WRAPPER ==="
make_wrapper -files [get_files *vlsi_design.bd] -top -import -force
update_compile_order -fileset sources_1

puts "=== RESET SUB RUNS ==="
reset_run [get_runs -filter {NAME =~ *cnn_top* && IS_SYNTHESIS}]
reset_run [get_runs -filter {NAME =~ *ila* && IS_SYNTHESIS}]
reset_run synth_1

puts "=== RUN STATUS AFTER RESET ==="
foreach r [get_runs] {
    puts "RUN: $r | STATUS: [get_property STATUS $r]"
}

close_project
puts "SUCCESSFULLY REGENERATED TARGETS"
