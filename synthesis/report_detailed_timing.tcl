open_checkpoint E:/QUANTA_VLSI/success_test_1/success_test_1.runs/impl_1/vlsi_design_wrapper_routed.dcp
report_timing -nworst 20 -file F:/QUANTA_2/synthesis/top20_timing.rpt
report_timing -group sys_clk -nworst 20 -file F:/QUANTA_2/synthesis/sysclk_top20.rpt
report_timing -group **async_default** -nworst 20 -file F:/QUANTA_2/synthesis/async_top20.rpt
puts "DONE_REPORTING"
