# Cadence Genus (Legacy UI) Synthesis Script for cnn_top (45nm)

set OUT_DIR "/home/vlsi1/124ec0043_09_chip/genus"
set SRC_DIR "/home/vlsi1/124ec0043_09_chip/source_files/proj_43_dd9"
set LIB_DIR "/home/vlsi1/124ec0043_09_chip/source_files/foundry"

file mkdir "$OUT_DIR/reports"
file mkdir "$OUT_DIR/outputs"

set_attribute lib_search_path $LIB_DIR /
set_attribute library slow_vdd1v0_basicCells.lib /
set_attribute init_hdl_search_path $SRC_DIR /
set_attribute information_level 5 /

# Avoid scan-flop mapping so Innovus PnR runs with zero scan-chain errors/warnings
catch {set_attribute avoid true [find / -libcell SDFF*] /}

read_hdl -v2001 {
    cnn_top.v
    argmax.v
    conv_layer.v
    fully_connected.v
    maxpool.v
    quantization.v
    relu.v
}

elaborate cnn_top
check_design -unresolved

# Clock and I/O constraints
create_clock -name clk -period 10 [get_ports clk]
set_input_delay 2 -clock clk [remove_from_collection [all_inputs] [get_ports clk]]
set_output_delay 2 -clock clk [all_outputs]

report clocks > "$OUT_DIR/reports/clocks.rpt"

syn_generic -effort medium
syn_map
syn_opt

report timing > "$OUT_DIR/reports/timing.rpt"
report area   > "$OUT_DIR/reports/area.rpt"
report gates  > "$OUT_DIR/reports/gates.rpt"
report power  > "$OUT_DIR/reports/power.rpt"
report qor    > "$OUT_DIR/reports/qor.rpt"

write_hdl > "$OUT_DIR/outputs/netlist.v"
write_sdc > "$OUT_DIR/outputs/out_constraint.sdc"
write_sdf -timescale ns -nonegchecks -recrem split -setuphold split -edges check_edge > "$OUT_DIR/outputs/delays.sdf"

puts "=== GENUS SYNTHESIS COMPLETED SUCCESSFULLY ==="
exit
