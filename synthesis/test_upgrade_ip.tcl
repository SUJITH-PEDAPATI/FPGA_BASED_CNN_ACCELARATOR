open_project E:/QUANTA_VLSI/success_test_1/success_test_1.xpr
open_bd_design [get_files *vlsi_design.bd]
upgrade_ip [get_ips {vlsi_design_cnn_top_0_0 vlsi_design_pixel_controller_0_0}]
report_ip_status
close_project
