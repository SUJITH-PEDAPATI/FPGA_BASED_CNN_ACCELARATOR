# =============================================================================
# fix_ila_and_regen.tcl
# QUANTA_2 -- Fix ILA BASIC-license probe overflow and regenerate IP.
#
# Problem summary:
#   The ILA (vlsi_design_ila_0_0) was configured with C_NUM_OF_PROBES=16.
#   Vivado 2026.1 BASIC license (Chipscope 16-620) does not support more
#   than 5 enabled probes on a standalone ILA IP.
#
# Fix:
#   Reduce ILA to 5 connected probes covering the minimal useful set:
#     probe0  [0:0]  busy_o
#     probe1  [0:0]  done_o
#     probe2  [3:0]  prediction_o
#     probe3  [9:0]  pixel_idx_o
#     probe4  [0:0]  load_o
#
#   Remove probes 5-15 from the ILA IP and disconnect their nets.
#   The source signals (cnn_top logit ports, pixel_controller image_active)
#   are NOT deleted or modified.
#
# Usage:
#   vivado -mode batch -notrace \
#     -source F:/QUANTA_2/synthesis/fix_ila_and_regen.tcl \
#     -log F:/QUANTA_2/synthesis/fix_ila_regen.log
# =============================================================================

set proj_xpr "E:/QUANTA_VLSI/success_test_1/success_test_1.xpr"

puts "INFO: Opening project $proj_xpr"
open_project $proj_xpr

# ---- 1. Refresh IP so Vivado knows all current file paths ----
puts "INFO: Refreshing IP repositories"
update_ip_catalog -rebuild -scan_changes

# ---- 2. Open the block design ----
open_bd_design [get_files *vlsi_design.bd]

# ---- 3. Report the current ILA configuration ----
set ila_cell [get_bd_cells ila_0]
puts "ILA cell       : $ila_cell"
puts "C_NUM_OF_PROBES: [get_property CONFIG.C_NUM_OF_PROBES $ila_cell]"
puts "C_DATA_DEPTH   : [get_property CONFIG.C_DATA_DEPTH    $ila_cell]"

# ---- 4. Disconnect excess ILA probes if present ----
set excess_nets {
    cnn_top_0_logit0_o
    cnn_top_0_logit1_o
    cnn_top_0_logit2_o
    cnn_top_0_logit3_o
    cnn_top_0_logit4_o
    cnn_top_0_logit5_o
    cnn_top_0_logit6_o
    cnn_top_0_logit7_o
    cnn_top_0_logit8_o
    cnn_top_0_logit9_o
    pixel_controller_0_image_active_o
}

foreach net_name $excess_nets {
    set net [get_bd_nets -quiet $net_name]
    if {$net ne ""} {
        set probe_pins [get_bd_pins -quiet -of_objects $net -filter {NAME =~ ila_0/probe*}]
        if {$probe_pins ne ""} {
            puts "INFO: Disconnecting ILA pins from $net_name : $probe_pins"
            disconnect_bd_net $net $probe_pins
        }
    }
}

# ---- 5. Reconfigure the ILA to exactly 5 probes (BASIC license limit) ----
set cur_probes [get_property CONFIG.C_NUM_OF_PROBES $ila_cell]
if {$cur_probes != 5} {
    set_property -dict [list \
        CONFIG.C_NUM_OF_PROBES  {5}    \
        CONFIG.C_PROBE0_WIDTH   {1}    \
        CONFIG.C_PROBE1_WIDTH   {1}    \
        CONFIG.C_PROBE2_WIDTH   {4}    \
        CONFIG.C_PROBE3_WIDTH   {10}   \
        CONFIG.C_PROBE4_WIDTH   {1}    \
        CONFIG.C_DATA_DEPTH     {1024} \
    ] $ila_cell
    puts "INFO: C_NUM_OF_PROBES set to 5."
} else {
    puts "INFO: C_NUM_OF_PROBES is already 5."
}

# Ensure probe0-4 are connected to required nets
set probe_map [list \
    /cnn_top_0_busy_o       /ila_0/probe0 \
    /cnn_top_0_done_o       /ila_0/probe1 \
    /cnn_top_0_prediction_o /ila_0/probe2 \
    /cnn_top_0_pixel_idx_o  /ila_0/probe3 \
    /cnn_top_0_load_o       /ila_0/probe4 \
]

foreach {net_name pin_name} $probe_map {
    set pin [get_bd_pins -quiet $pin_name]
    if {$pin ne ""} {
        set pin_nets [get_bd_nets -quiet -of_objects $pin]
        if {[llength $pin_nets] == 0} {
            set net [get_bd_nets -quiet $net_name]
            if {$net ne ""} {
                puts "INFO: Connecting $net to $pin"
                connect_bd_net $net $pin
            } else {
                puts "WARNING: Net $net_name not found to connect to $pin"
            }
        } else {
            puts "INFO: $pin is already connected to $pin_nets"
        }
    }
}

# ---- 6. Validate the block design ----
puts "INFO: Validating block design..."
validate_bd_design
puts "INFO: Block design validation passed."

# ---- 7. Save and regenerate targets ----
save_bd_design
puts "INFO: Block design saved."

generate_target all [get_files *vlsi_design.bd]
puts "INFO: generate_target all completed."

make_wrapper -files [get_files *vlsi_design.bd] -top -import -force
update_compile_order -fileset sources_1
puts "INFO: Wrapper updated."

export_ip_user_files -of_objects [get_files *vlsi_design.bd] -no_script -sync -force -quiet
puts "INFO: export_ip_user_files completed."

# ---- 8. Check and launch runs ----
puts "INFO: Resetting synth_1..."
reset_run synth_1

puts "INFO: Launching synth_1 (8 jobs)..."
launch_runs synth_1 -jobs 8
wait_on_run synth_1

set synth_status   [get_property STATUS   [get_runs synth_1]]
set synth_progress [get_property PROGRESS [get_runs synth_1]]
puts "SYNTH_STATUS  : $synth_status"
puts "SYNTH_PROGRESS: $synth_progress"

if {$synth_status ne "synth_design Complete!"} {
    puts "ERROR: Synthesis did not complete. Check run logs."
    close_project
    return
}

puts "INFO: Synthesis succeeded. Launching impl_1 through route_design..."
launch_runs impl_1 -to_step route_design -jobs 8
wait_on_run impl_1

set impl_status   [get_property STATUS   [get_runs impl_1]]
set impl_progress [get_property PROGRESS [get_runs impl_1]]
puts "IMPL_STATUS  : $impl_status"
puts "IMPL_PROGRESS: $impl_progress"

# ---- 9. Print WNS / TNS from timing summary ----
set rpt_files [glob -nocomplain \
    "E:/QUANTA_VLSI/success_test_1/success_test_1.runs/impl_1/*timing_summary_routed.rpt"]

if {[llength $rpt_files] > 0} {
    set rpt [lindex $rpt_files 0]
    puts "TIMING_REPORT: $rpt"
    set fh [open $rpt r]
    set in_summary 0
    while {[gets $fh line] >= 0} {
        if {[string match "*Design Timing Summary*" $line]} { set in_summary 1 }
        if {$in_summary} {
            if {[string match "*WNS*" $line]} { puts $line }
            if {[string match "*TNS*" $line]} { puts $line }
            if {$in_summary && [string match "*Total Negative*" $line]} { break }
        }
    }
    close $fh
} else {
    puts "WARNING: No routed timing summary report found."
}

close_project
puts "INFO: fix_ila_and_regen.tcl completed successfully."
