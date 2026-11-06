open_project F:/QUANTA_2/testfor8/vivado_project/cnn_accelerator_digit8.xpr
set impl [get_runs impl_1]
set_property strategy "Performance_ExplorePostRoutePhysOpt" $impl
puts "Strategy: [get_property STRATEGY $impl]"
puts "post_route enabled: [get_property STEPS.POST_ROUTE_PHYS_OPT_DESIGN.IS_ENABLED $impl]"
close_project
exit 0

