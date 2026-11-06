# test_open_project.tcl
puts "=== Opening F:/QUANTA_2/testfor9/vivado_project/cnn_accelerator.xpr ==="
open_project F:/QUANTA_2/testfor9/vivado_project/cnn_accelerator.xpr

puts "=== Reporting Project Sources ==="
foreach f [get_files -of_objects [get_filesets sources_1]] {
    puts "SRC: $f"
}
foreach f [get_files -of_objects [get_filesets constrs_1]] {
    puts "CONSTR: $f"
}
foreach f [get_files -of_objects [get_filesets sim_1]] {
    puts "SIM: $f"
}

puts "=== Checking Block Design ==="
open_bd_design [get_files *vlsi_design.bd]
puts "BD_CELLS: [get_bd_cells]"
validate_bd_design
puts "=== BD Validation Succeeded ==="

close_project
puts "=== SUCCESS: Project opened and validated without errors ==="
exit

