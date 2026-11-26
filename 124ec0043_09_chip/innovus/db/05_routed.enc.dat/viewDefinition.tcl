if {![namespace exists ::IMEX]} { namespace eval ::IMEX {} }
set ::IMEX::dataVar [file dirname [file normalize [info script]]]
set ::IMEX::libVar ${::IMEX::dataVar}/libs

create_library_set -name lib_fast\
   -timing\
    [list ${::IMEX::libVar}/mmmc/fast_vdd1v0_basicCells.lib]
create_library_set -name lib_slow\
   -timing\
    [list ${::IMEX::libVar}/mmmc/slow_vdd1v0_basicCells.lib]
create_op_cond -name op_worst -library_file (null) -P 1 -V 0.9 -T 125
create_op_cond -name op_best -library_file (null) -P 1 -V 1.1 -T 0
create_rc_corner -name rc_best\
   -preRoute_res 1\
   -postRoute_res 1\
   -preRoute_cap 1\
   -postRoute_cap 1\
   -postRoute_xcap 1\
   -preRoute_clkres 0\
   -preRoute_clkcap 0\
   -T 0\
   -qx_tech_file ${::IMEX::libVar}/mmmc/rc_best/qrcTechFile
create_rc_corner -name rc_worst\
   -preRoute_res 1\
   -postRoute_res 1\
   -preRoute_cap 1\
   -postRoute_cap 1\
   -postRoute_xcap 1\
   -preRoute_clkres 0\
   -preRoute_clkcap 0\
   -T 125\
   -qx_tech_file ${::IMEX::libVar}/mmmc/rc_best/qrcTechFile
create_delay_corner -name dc_worst\
   -library_set lib_slow\
   -opcond op_worst\
   -rc_corner rc_worst
create_delay_corner -name dc_best\
   -library_set lib_fast\
   -opcond op_best\
   -rc_corner rc_best
create_constraint_mode -name cm_func\
   -sdc_files\
    [list ${::IMEX::dataVar}/mmmc/modes/cm_func/cm_func.sdc]
create_analysis_view -name view_worst -constraint_mode cm_func -delay_corner dc_worst -latency_file ${::IMEX::dataVar}/mmmc/views/view_worst/latency.sdc
create_analysis_view -name view_best -constraint_mode cm_func -delay_corner dc_best -latency_file ${::IMEX::dataVar}/mmmc/views/view_best/latency.sdc
set_analysis_view -setup [list view_worst] -hold [list view_best]
