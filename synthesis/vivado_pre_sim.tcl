# vivado_pre_sim.tcl -- QUANTA_2
# Pre-simulation hook: copies all .mem files to the Vivado xsim working
# directory so that the relative paths in cnn_top.v / conv_layer.v /
# fully_connected.v resolve correctly at runtime.
#
# Vivado xsim working directory:
#   <project>/<project>.sim/sim_1/behav/xsim/
#
# Usage in Vivado:
#   Simulation Settings -> Simulation -> xsim.simulate.tcl.pre  = <path>/vivado_pre_sim.tcl
# Or via Tcl console:
#   set_property -name {xsim.simulate.tcl.pre} \
#                -value {F:/QUANTA_2/sim/vivado_pre_sim.tcl} \
#                -objects [get_filesets sim_1]

set root "F:/QUANTA_2"

puts "=== QUANTA_2 pre_sim.tcl: copying .mem files to xsim CWD ==="
puts "    Source root : $root"
puts "    xsim CWD    : [pwd]"

# Root-level weight files (used by conv_layer.v with "../*.mem" paths)
# xsim CWD is two levels deep: copy to parent so "../" resolves correctly
# Actually xsim resolves $readmemh paths relative to xsim CWD itself.
# cnn_top.v uses: "../conv1_weights_int.mem" -> needs to be one level up
# from xsim CWD.  Copy to both locations to be safe.
foreach f {conv1_weights_int.mem conv2_weights_int.mem fc1_weights_int.mem} {
    file copy -force "$root/$f" "./$f"
    file copy -force "$root/$f" "../$f"
}

# params/ bias files (used with "../params/*.mem")
file mkdir "./params"
file mkdir "../params"
foreach f {conv1_bias_acc.mem conv2_bias_acc.mem fc_bias_acc.mem} {
    file copy -force "$root/params/$f" "./params/$f"
    file copy -force "$root/params/$f" "../params/$f"
}

puts "    Copied: conv1_weights_int.mem, conv2_weights_int.mem, fc1_weights_int.mem"
puts "    Copied: params/conv1_bias_acc.mem, params/conv2_bias_acc.mem, params/fc_bias_acc.mem"
puts "=== pre_sim.tcl done ==="
