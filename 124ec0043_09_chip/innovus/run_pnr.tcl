# ==============================================================================
# Cadence Innovus Full RTL-to-GDSII Physical Design Flow for cnn_top (45nm)
# ==============================================================================

file mkdir db reports outputs screenshots

# Helper to capture GUI screenshots as GIF and convert to PNG (without instance/filler text clutter)
proc take_shot {name {view place}} {
    catch {setPreference ShowInstanceText 0}
    catch {setDrawView $view}
    catch {fit}
    catch {redraw}
    catch {update}
    after 400
    catch {update}
    if {[catch {dumpToGIF screenshots/${name}.gif} err]} {
        puts "WARN: dumpToGIF failed for ${name}: $err"
    } else {
        catch {exec sh -c "giftopnm screenshots/${name}.gif | pnmtopng > screenshots/${name}.png"}
    }
}

# ------------------------------------------------------------------------------
# 1. Design Import & Initialization
# ------------------------------------------------------------------------------
set init_gnd_net VSS
set init_pwr_net VDD
set init_verilog /home/vlsi1/124ec0043_09_chip/genus/outputs/netlist.v
set init_top_cell cnn_top
set init_lef_file [list \
    /home/vlsi1/124ec0043_09_chip/source_files/foundry/gsclib045_tech.lef \
    /home/vlsi1/124ec0043_09_chip/source_files/foundry/gsclib045_macro.lef \
]
set init_mmmc_file mmmc.tcl

init_design

setDesignMode -process 45 -topRoutingLayer 9 -bottomRoutingLayer 1
setMultiCpuUsage -localCpu 4

# Avoid gsclib045 BUFX2 (CoreSiteDouble bug) and scan flops (zero scan-chain errors)
catch {setDontUse BUFX2 true}
catch {set_dont_use [get_lib_cells */BUFX2]}
catch {setDontUse SDFF* true}
catch {set_dont_use [get_lib_cells */SDFF*]}

# Open GUI window if DISPLAY is available
catch {win}
catch {setPreference ShowInstanceText 0}
after 500
catch {update}

# ------------------------------------------------------------------------------
# 2. Floorplanning & IO Pin Assignment
# ------------------------------------------------------------------------------
# Grid-aligned 43.00um x 42.75um core (25 CoreSite rows, ~73% density)
# Tight margins (6.00um L/R, 6.84um T/B -> 55.00um x 56.43um die)
floorPlan -site CoreSite -s 43.00 42.75 6.00 6.84 6.00 6.84

# Place ONLY the 28 essential pins on Left (11 inputs) and Right (17 outputs) on Metal3
# Zero pins on Top and Bottom
set left_pins [list clk rst_n start_i]
for {set i 0} {$i < 8} {incr i} { lappend left_pins "pixel_i\[$i\]" }

set right_pins [list load_o busy_o done_o]
for {set i 0} {$i < 10} {incr i} { lappend right_pins "pixel_idx_o\[$i\]" }
for {set i 0} {$i < 4}  {incr i} { lappend right_pins "prediction_o\[$i\]" }

setPinAssignMode -pinEditInBatch true
editPin -pin $left_pins  -side Left  -layer Metal3 -spreadType center -spacing 2.66 -pinWidth 0.12 -pinDepth 0.40
editPin -pin $right_pins -side Right -layer Metal3 -spreadType center -spacing 1.90 -pinWidth 0.12 -pinDepth 0.40
setPinAssignMode -pinEditInBatch false

saveDesign db/01_floorplan.enc
take_shot 01_floorplan fplan

# ------------------------------------------------------------------------------
# 3. Power Planning (Global Nets, Core Rings, Power Mesh, Special Route)
# ------------------------------------------------------------------------------
clearGlobalNets
globalNetConnect VDD -type pgpin -pin VDD -inst * -override
globalNetConnect VSS -type pgpin -pin VSS -inst * -override
globalNetConnect VDD -type tiehi -all -override
globalNetConnect VSS -type tielo -all -override

addRing -nets {VDD VSS} -type core_rings -follow core \
    -layer {top Metal9 bottom Metal9 left Metal8 right Metal8} \
    -width {top 1.2 bottom 1.2 left 1.2 right 1.2} \
    -spacing {top 0.8 bottom 0.8 left 0.8 right 0.8} \
    -offset {top 1.2 bottom 1.2 left 1.2 right 1.2} \
    -center 1

setMultiCpuUsage -localCpu 1
addStripe -nets {VDD VSS} -layer Metal8 -direction vertical \
    -width 1.0 -spacing 1.0 -set_to_set_distance 21 \
    -start_from left -start_offset 11 \
    -switch_layer_over_obs false -max_same_layer_jog_length 2 \
    -padcore_ring_top_layer_limit Metal9 -padcore_ring_bottom_layer_limit Metal1 \
    -block_ring_top_layer_limit Metal9 -block_ring_bottom_layer_limit Metal1 \
    -use_wire_group 0 -snap_wire_center_to_grid None

addStripe -nets {VDD VSS} -layer Metal9 -direction horizontal \
    -width 1.0 -spacing 1.0 -set_to_set_distance 21 \
    -start_from bottom -start_offset 11 \
    -switch_layer_over_obs false -max_same_layer_jog_length 2 \
    -padcore_ring_top_layer_limit Metal9 -padcore_ring_bottom_layer_limit Metal1 \
    -block_ring_top_layer_limit Metal9 -block_ring_bottom_layer_limit Metal1 \
    -use_wire_group 0 -snap_wire_center_to_grid None
setMultiCpuUsage -localCpu 4

sroute -connect { corePin floatingStripe } \
    -layerChangeRange { Metal1(1) Metal9(9) } \
    -corePinTarget { firstAfterRowEnd } \
    -floatingStripeTarget { blockring padring ring stripe ringpin blockpin followpin } \
    -allowJogging 1 \
    -crossoverViaLayerRange { Metal1(1) Metal9(9) } \
    -nets { VDD VSS } \
    -allowLayerChange 1 \
    -targetViaLayerRange { Metal1(1) Metal9(9) }

saveDesign db/02_powerplan.enc
take_shot 02_powerplan fplan

# ------------------------------------------------------------------------------
# 4. Placement & Pre-CTS Optimization
# ------------------------------------------------------------------------------
setPlaceMode -fp false
place_opt_design

addTieHiLo -cell {TIEHI TIELO} -prefix LTIE
checkPlace reports/01_checkPlace.rpt
timeDesign -preCTS -outDir reports/preCTS

saveDesign db/03_placement.enc
take_shot 03_placement_physical place
take_shot 03_placement_amoeba ameba

# ------------------------------------------------------------------------------
# 5. Clock Tree Synthesis (CTS) & Post-CTS Optimization
# ------------------------------------------------------------------------------
set_ccopt_property buffer_cells {CLKBUFX2 CLKBUFX3 CLKBUFX4 CLKBUFX6 CLKBUFX8 CLKBUFX12 CLKBUFX16 CLKBUFX20}
set_ccopt_property inverter_cells {CLKINVX1 CLKINVX2 CLKINVX3 CLKINVX4 CLKINVX6 CLKINVX8 CLKINVX12 CLKINVX16 CLKINVX20}

create_ccopt_clock_tree_spec -file reports/ccopt.spec
source reports/ccopt.spec

ccopt_design

optDesign -postCTS -setup -hold

report_ccopt_clock_trees -file reports/02_cts_trees.rpt
report_ccopt_skew_groups -file reports/02_cts_skew.rpt
timeDesign -postCTS -outDir reports/postCTS
timeDesign -postCTS -hold -outDir reports/postCTS_hold

saveDesign db/04_cts.enc
take_shot 04_cts place

# ------------------------------------------------------------------------------
# 6. NanoRoute & Post-Route Optimization
# ------------------------------------------------------------------------------
setNanoRouteMode -quiet -drouteEndIteration default
setNanoRouteMode -quiet -routeWithTimingDriven true
setNanoRouteMode -quiet -routeWithSiDriven true

routeDesign -globalDetail

setAnalysisMode -analysisType onChipVariation -cppr both
optDesign -postRoute -setup -hold

timeDesign -postRoute -outDir reports/postRoute
timeDesign -postRoute -hold -outDir reports/postRoute_hold

saveDesign db/05_routed.enc
take_shot 05_routed place

# ------------------------------------------------------------------------------
# 7. Filler Insertion & Physical/Timing Signoff
# ------------------------------------------------------------------------------
addFiller -cell {FILL64 FILL32 FILL16 FILL8 FILL4 FILL2 FILL1} -prefix FILLER -fitGap
ecoRoute -target

setMultiCpuUsage -localCpu 1
verify_drc -report reports/03_verify_drc.rpt
setMultiCpuUsage -localCpu 4
verifyConnectivity -type all -error 1000 -warning 50 -report reports/04_verify_connectivity.rpt
verifyProcessAntenna -report reports/05_verify_antenna.rpt

report_area > reports/06_area.rpt
report_power > reports/07_power.rpt
report_timing -max_paths 10 -late > reports/08_timing_setup.rpt
report_timing -max_paths 10 -early > reports/09_timing_hold.rpt
summaryReport -noHtml -outfile reports/10_summary.rpt

# ------------------------------------------------------------------------------
# 8. Export Final Design & Signoff Deliverables
# ------------------------------------------------------------------------------
saveDesign db/06_final.enc
saveNetlist outputs/cnn_top_pnr.v
defOut -floorplan -netlist -routing outputs/cnn_top_pnr.def
write_sdf -recompute_delay_calc outputs/cnn_top_pnr.sdf
setExtractRCMode -engine postRoute -effortLevel medium
extractRC
rcOut -spef outputs/cnn_top_worst.spef -rc_corner rc_worst
rcOut -spef outputs/cnn_top_best.spef  -rc_corner rc_best
streamOut outputs/cnn_top_pnr.gds -mapFile streamOut.map -libName DesignLib -units 2000 -mode ALL

take_shot 06_final_layout place
take_shot 07_final_amoeba ameba

puts "=== INNOVUS PNR FLOW COMPLETED SUCCESSFULLY ==="
exit
