open_project E:/QUANTA_VLSI/success_test_1/success_test_1.xpr
open_bd_design [get_files *vlsi_design.bd]
write_bd_tcl -force E:/QUANTA_VLSI/success_test_2/vlsi_design.tcl
puts "BD_TCL_WRITTEN_SUCCESSFULLY"
close_project

