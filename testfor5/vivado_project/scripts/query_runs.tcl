open_project F:/QUANTA_2/testfor5/vivado_project/cnn_accelerator_digit5.xpr
foreach r [get_runs] {
    puts "RUN $r : STATUS=[get_property STATUS $r] NEEDS_REFRESH=[get_property NEEDS_REFRESH $r]"
}
exit 0

