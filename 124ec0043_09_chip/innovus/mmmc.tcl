# MMMC Configuration for cnn_top (GPDK 45nm / gsclib045)

create_library_set -name lib_slow \
    -timing [list /home/vlsi1/124ec0043_09_chip/source_files/foundry/slow_vdd1v0_basicCells.lib]

create_library_set -name lib_fast \
    -timing [list /home/vlsi1/124ec0043_09_chip/source_files/foundry/fast_vdd1v0_basicCells.lib]

create_opcond -name op_worst -process 1.0 -voltage 0.9 -temperature 125
create_opcond -name op_best  -process 1.0 -voltage 1.1 -temperature 0

create_rc_corner -name rc_worst \
    -T 125 \
    -qx_tech_file /home/install/FOUNDRY/digital/45nm/LIBS/qx/qrcTechFile

create_rc_corner -name rc_best \
    -T 0 \
    -qx_tech_file /home/install/FOUNDRY/digital/45nm/LIBS/qx/qrcTechFile

create_delay_corner -name dc_worst \
    -library_set lib_slow \
    -opcond op_worst \
    -rc_corner rc_worst

create_delay_corner -name dc_best \
    -library_set lib_fast \
    -opcond op_best \
    -rc_corner rc_best

create_constraint_mode -name cm_func \
    -sdc_files [list /home/vlsi1/124ec0043_09_chip/genus/outputs/out_constraint.sdc]

create_analysis_view -name view_worst \
    -constraint_mode cm_func \
    -delay_corner dc_worst

create_analysis_view -name view_best \
    -constraint_mode cm_func \
    -delay_corner dc_best

set_analysis_view -setup [list view_worst] -hold [list view_best]
