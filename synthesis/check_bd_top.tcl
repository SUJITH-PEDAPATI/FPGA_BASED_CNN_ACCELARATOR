open_project E:/QUANTA_VLSI/success_test_1/success_test_1.xpr
open_bd_design [get_files *vlsi_design.bd]
validate_bd_design
set_property top vlsi_design_wrapper [current_fileset]
update_compile_order -fileset sources_1
puts "TOP_MODULE: [get_property top [current_fileset]]"
puts "VALIDATE_BD_PASSED"
close_project
