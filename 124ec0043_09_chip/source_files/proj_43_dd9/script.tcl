

set_db init_lib_search_path /home/install/FOUNDRY/digital/45nm/LIBS/lib/
set_db library slow_vdd1v0_basicCells.lib

set_attribute hdl_search_path /home/vlsi1/124ec0043_09_chip/source_files

read_hdl -language verilog {
cnn_top.v argmax.v conv_layer.v fully_connected.v maxpool.v quantization.v relu.v}

# name the top so only pipe_cpu is built
elaborate cnn_top
cd /designs/cnn_top

# ---- clock and I/O constraints (inline) ----
create_clock -name clk -period 10 [get_ports clk]
set_input_delay 2 -clock clk [remove_from_collection [all_inputs] [get_ports clk]]
set_output_delay 2 -clock clk [all_outputs]
# --------------------------------------------

report_clocks

syn_generic -effort medium
syn_map
syn_opt

report_timing
report_area
report_power

gui_report_timing
gui_show

write_hdl > netlist.v
write_sdc > out_constraint.sdc

