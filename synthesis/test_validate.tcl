open_project E:/QUANTA_VLSI/success_test_1/success_test_1.xpr
open_bd_design [get_files *vlsi_design.bd]
puts "=== VALIDATING BD ==="
set val_res [validate_bd_design]
puts "VALIDATION RESULT: $val_res"
save_bd_design
close_project
