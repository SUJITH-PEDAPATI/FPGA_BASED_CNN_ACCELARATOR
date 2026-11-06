# run_hardware_inference.tcl
# Automatically programs the ZedBoard, arms the ILA, pulses VIO start, and exports the captured ILA waveform to CSV.

open_hw_manager
connect_hw_server -url localhost:3121
set target [lindex [get_hw_targets */xilinx_tcf/Digilent/*] 0]
puts "=== Opening target $target ==="
open_hw_target $target

set dev [get_hw_devices xc7z020_1]
current_hw_device $dev

puts "=== Setting Bitstream and Probes ==="
set_property PROGRAM.FILE {F:/QUANTA_2/vlsi_design_wrapper_digit3.bit} $dev
set_property PROBES.FILE {F:/QUANTA_2/debug_nets_digit3.ltx} $dev

puts "=== Programming FPGA Device ==="
program_hw_devices $dev
refresh_hw_device $dev

set vio [lindex [get_hw_vios] 0]
set ila [lindex [get_hw_ilas] 0]

set rst_probe   [lindex [get_hw_probes -of_objects $vio *probe_out1*] 0]
set start_probe [lindex [get_hw_probes -of_objects $vio *probe_out0*] 0]
set done_probe  [lindex [get_hw_probes -of_objects $ila *done_o*] 0]

# Set ILA trigger condition: done_o == 1
puts "=== Configuring ILA Trigger on done_o == 1 ==="
set_property TRIGGER_COMPARE_VALUE eq1'b1 $done_probe

# 1. Reset cycle: assert rst_n = 0
puts "=== Asserting Reset (rst_n = 0) ==="
set_property OUTPUT_VALUE 0 $rst_probe
set_property OUTPUT_VALUE 0 $start_probe
commit_hw_vio $vio
after 100

# 2. Deassert reset: rst_n = 1
puts "=== Deasserting Reset (rst_n = 1) ==="
set_property OUTPUT_VALUE 1 $rst_probe
commit_hw_vio $vio
after 100

# 3. Arm ILA
puts "=== Arming ILA ==="
run_hw_ila $ila
after 100

# 4. Pulse start: start_request_i = 1 then 0
puts "=== Pulsing start_request_i: 0 -> 1 -> 0 ==="
set_property OUTPUT_VALUE 1 $start_probe
commit_hw_vio $vio
after 50
set_property OUTPUT_VALUE 0 $start_probe
commit_hw_vio $vio

# 5. Wait for ILA to capture completion
puts "=== Waiting for ILA trigger... ==="
wait_on_hw_ila -timeout 10 $ila

# 6. Upload captured waveform data
puts "=== Uploading ILA data ==="
upload_hw_ila_data $ila

# 7. Write captured ILA data to CSV
puts "=== Exporting captured ILA waveform to CSV ==="
set ila_data [current_hw_ila_data]
write_hw_ila_data -csv_file -force F:/QUANTA_2/synthesis/ila_capture.csv $ila_data

puts "=== Wrote F:/QUANTA_2/synthesis/ila_capture.csv successfully ==="

close_hw_target
close_hw_manager
