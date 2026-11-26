#######################################################
#                                                     
#  Innovus Command Logging File                     
#  Created on Thu Nov 26 23:02:38 2026                
#                                                     
#######################################################

#@(#)CDS: Innovus v21.15-s110_1 (64bit) 09/23/2022 13:08 (Linux 3.10.0-693.el7.x86_64)
#@(#)CDS: NanoRoute 21.15-s110_1 NR220912-2004/21_15-UB (database version 18.20.592) {superthreading v2.17}
#@(#)CDS: AAE 21.15-s039 (64bit) 09/23/2022 (Linux 3.10.0-693.el7.x86_64)
#@(#)CDS: CTE 21.15-s038_1 () Sep 20 2022 11:42:13 ( )
#@(#)CDS: SYNTECH 21.15-s012_1 () Sep  5 2022 10:25:51 ( )
#@(#)CDS: CPE v21.15-s076
#@(#)CDS: IQuantus/TQuantus 21.1.1-s867 (64bit) Sun Jun 26 22:12:54 PDT 2022 (Linux 3.10.0-693.el7.x86_64)

set_global _enable_mmmc_by_default_flow      $CTE::mmmc_default
suppressMessage ENCEXT-2799
getVersion
getVersion
getVersion
set init_gnd_net VSS
set init_pwr_net VDD
set init_verilog /home/vlsi1/124ec0043_09_chip/genus/outputs/netlist.v
set init_top_cell cnn_top
set init_lef_file {/home/vlsi1/124ec0043_09_chip/source_files/foundry/gsclib045_tech.lef /home/vlsi1/124ec0043_09_chip/source_files/foundry/gsclib045_macro.lef}
set init_mmmc_file mmmc.tcl
init_design
setDesignMode -process 45 -topRoutingLayer 9 -bottomRoutingLayer 1
setMultiCpuUsage -localCpu 4
setDontUse BUFX2 true
set_dont_use [get_lib_cells */BUFX2]
win
floorPlan -site CoreSite -s 50.0 49.59 10.20 10.26 10.20 10.26
setPinAssignMode -pinEditInBatch true
editPin -pin {clk rst_n start_i {pixel_i[0]} {pixel_i[1]} {pixel_i[2]} {pixel_i[3]} {pixel_i[4]} {pixel_i[5]} {pixel_i[6]} {pixel_i[7]} {logit8_o[0]} {logit8_o[1]} {logit8_o[2]} {logit8_o[3]} {logit8_o[4]} {logit8_o[5]} {logit8_o[6]} {logit8_o[7]} {logit8_o[8]} {logit8_o[9]} {logit8_o[10]} {logit8_o[11]} {logit8_o[12]} {logit8_o[13]} {logit8_o[14]} {logit8_o[15]} {logit8_o[16]} {logit8_o[17]} {logit8_o[18]} {logit8_o[19]} {logit8_o[20]} {logit8_o[21]} {logit8_o[22]} {logit8_o[23]} {logit8_o[24]} {logit8_o[25]} {logit8_o[26]} {logit8_o[27]} {logit8_o[28]} {logit8_o[29]} {logit8_o[30]} {logit8_o[31]} {logit9_o[0]} {logit9_o[1]} {logit9_o[2]} {logit9_o[3]} {logit9_o[4]} {logit9_o[5]} {logit9_o[6]} {logit9_o[7]} {logit9_o[8]} {logit9_o[9]} {logit9_o[10]} {logit9_o[11]} {logit9_o[12]} {logit9_o[13]} {logit9_o[14]} {logit9_o[15]} {logit9_o[16]} {logit9_o[17]} {logit9_o[18]} {logit9_o[19]} {logit9_o[20]} {logit9_o[21]} {logit9_o[22]} {logit9_o[23]} {logit9_o[24]} {logit9_o[25]} {logit9_o[26]} {logit9_o[27]} {logit9_o[28]} {logit9_o[29]} {logit9_o[30]} {logit9_o[31]} {logit7_o[0]} {logit7_o[1]} {logit7_o[2]} {logit7_o[3]} {logit7_o[4]} {logit7_o[5]} {logit7_o[6]} {logit7_o[7]} {logit7_o[8]} {logit7_o[9]} {logit7_o[10]} {logit7_o[11]}} -side Left -layer Metal3 -spreadType center -spacing 0.38
editPin -pin {{logit0_o[0]} {logit0_o[1]} {logit0_o[2]} {logit0_o[3]} {logit0_o[4]} {logit0_o[5]} {logit0_o[6]} {logit0_o[7]} {logit0_o[8]} {logit0_o[9]} {logit0_o[10]} {logit0_o[11]} {logit0_o[12]} {logit0_o[13]} {logit0_o[14]} {logit0_o[15]} {logit0_o[16]} {logit0_o[17]} {logit0_o[18]} {logit0_o[19]} {logit0_o[20]} {logit0_o[21]} {logit0_o[22]} {logit0_o[23]} {logit0_o[24]} {logit0_o[25]} {logit0_o[26]} {logit0_o[27]} {logit0_o[28]} {logit0_o[29]} {logit0_o[30]} {logit0_o[31]} {logit1_o[0]} {logit1_o[1]} {logit1_o[2]} {logit1_o[3]} {logit1_o[4]} {logit1_o[5]} {logit1_o[6]} {logit1_o[7]} {logit1_o[8]} {logit1_o[9]} {logit1_o[10]} {logit1_o[11]} {logit1_o[12]} {logit1_o[13]} {logit1_o[14]} {logit1_o[15]} {logit1_o[16]} {logit1_o[17]} {logit1_o[18]} {logit1_o[19]} {logit1_o[20]} {logit1_o[21]} {logit1_o[22]} {logit1_o[23]} {logit1_o[24]} {logit1_o[25]} {logit1_o[26]} {logit1_o[27]} {logit1_o[28]} {logit1_o[29]} {logit1_o[30]} {logit1_o[31]} {logit2_o[0]} {logit2_o[1]} {logit2_o[2]} {logit2_o[3]} {logit2_o[4]} {logit2_o[5]} {logit2_o[6]} {logit2_o[7]} {logit2_o[8]} {logit2_o[9]} {logit2_o[10]} {logit2_o[11]} {logit2_o[12]} {logit2_o[13]} {logit2_o[14]} {logit2_o[15]} {logit2_o[16]} {logit2_o[17]} {logit2_o[18]} {logit2_o[19]} {logit2_o[20]} {logit2_o[21]} {logit2_o[22]} {logit2_o[23]}} -side Top -layer Metal4 -spreadType center -spacing 0.40
editPin -pin {load_o busy_o done_o {pixel_idx_o[0]} {pixel_idx_o[1]} {pixel_idx_o[2]} {pixel_idx_o[3]} {pixel_idx_o[4]} {pixel_idx_o[5]} {pixel_idx_o[6]} {pixel_idx_o[7]} {pixel_idx_o[8]} {pixel_idx_o[9]} {prediction_o[0]} {prediction_o[1]} {prediction_o[2]} {prediction_o[3]} {logit3_o[0]} {logit3_o[1]} {logit3_o[2]} {logit3_o[3]} {logit3_o[4]} {logit3_o[5]} {logit3_o[6]} {logit3_o[7]} {logit3_o[8]} {logit3_o[9]} {logit3_o[10]} {logit3_o[11]} {logit3_o[12]} {logit3_o[13]} {logit3_o[14]} {logit3_o[15]} {logit3_o[16]} {logit3_o[17]} {logit3_o[18]} {logit3_o[19]} {logit3_o[20]} {logit3_o[21]} {logit3_o[22]} {logit3_o[23]} {logit3_o[24]} {logit3_o[25]} {logit3_o[26]} {logit3_o[27]} {logit3_o[28]} {logit3_o[29]} {logit3_o[30]} {logit3_o[31]} {logit4_o[0]} {logit4_o[1]} {logit4_o[2]} {logit4_o[3]} {logit4_o[4]} {logit4_o[5]} {logit4_o[6]} {logit4_o[7]} {logit4_o[8]} {logit4_o[9]} {logit4_o[10]} {logit4_o[11]} {logit4_o[12]} {logit4_o[13]} {logit4_o[14]} {logit4_o[15]} {logit4_o[16]} {logit4_o[17]} {logit4_o[18]} {logit4_o[19]} {logit4_o[20]} {logit4_o[21]} {logit4_o[22]} {logit4_o[23]} {logit4_o[24]} {logit4_o[25]} {logit4_o[26]} {logit4_o[27]} {logit4_o[28]} {logit4_o[29]} {logit4_o[30]} {logit4_o[31]} {logit2_o[24]} {logit2_o[25]} {logit2_o[26]} {logit2_o[27]} {logit2_o[28]} {logit2_o[29]} {logit2_o[30]} {logit2_o[31]}} -side Right -layer Metal3 -spreadType center -spacing 0.38
editPin -pin {{logit5_o[0]} {logit5_o[1]} {logit5_o[2]} {logit5_o[3]} {logit5_o[4]} {logit5_o[5]} {logit5_o[6]} {logit5_o[7]} {logit5_o[8]} {logit5_o[9]} {logit5_o[10]} {logit5_o[11]} {logit5_o[12]} {logit5_o[13]} {logit5_o[14]} {logit5_o[15]} {logit5_o[16]} {logit5_o[17]} {logit5_o[18]} {logit5_o[19]} {logit5_o[20]} {logit5_o[21]} {logit5_o[22]} {logit5_o[23]} {logit5_o[24]} {logit5_o[25]} {logit5_o[26]} {logit5_o[27]} {logit5_o[28]} {logit5_o[29]} {logit5_o[30]} {logit5_o[31]} {logit6_o[0]} {logit6_o[1]} {logit6_o[2]} {logit6_o[3]} {logit6_o[4]} {logit6_o[5]} {logit6_o[6]} {logit6_o[7]} {logit6_o[8]} {logit6_o[9]} {logit6_o[10]} {logit6_o[11]} {logit6_o[12]} {logit6_o[13]} {logit6_o[14]} {logit6_o[15]} {logit6_o[16]} {logit6_o[17]} {logit6_o[18]} {logit6_o[19]} {logit6_o[20]} {logit6_o[21]} {logit6_o[22]} {logit6_o[23]} {logit6_o[24]} {logit6_o[25]} {logit6_o[26]} {logit6_o[27]} {logit6_o[28]} {logit6_o[29]} {logit6_o[30]} {logit6_o[31]} {logit7_o[12]} {logit7_o[13]} {logit7_o[14]} {logit7_o[15]} {logit7_o[16]} {logit7_o[17]} {logit7_o[18]} {logit7_o[19]} {logit7_o[20]} {logit7_o[21]} {logit7_o[22]} {logit7_o[23]} {logit7_o[24]} {logit7_o[25]} {logit7_o[26]} {logit7_o[27]} {logit7_o[28]} {logit7_o[29]} {logit7_o[30]} {logit7_o[31]}} -side Bottom -layer Metal4 -spreadType center -spacing 0.40
setPinAssignMode -pinEditInBatch false
saveDesign db/01_floorplan.enc
setDrawView fplan
fit
redraw
dumpToGIF screenshots/01_floorplan.gif
clearGlobalNets
globalNetConnect VDD -type pgpin -pin VDD -inst * -override
globalNetConnect VSS -type pgpin -pin VSS -inst * -override
globalNetConnect VDD -type tiehi -all -override
globalNetConnect VSS -type tielo -all -override
addRing -nets {VDD VSS} -type core_rings -follow core -layer {top Metal9 bottom Metal9 left Metal8 right Metal8} -width {top 1.5 bottom 1.5 left 1.5 right 1.5} -spacing {top 1.0 bottom 1.0 left 1.0 right 1.0} -offset {top 1.5 bottom 1.5 left 1.5 right 1.5} -center 1
addStripe -nets {VDD VSS} -layer Metal8 -direction vertical -width 1.0 -spacing 1.0 -set_to_set_distance 24 -start_from left -start_offset 12 -switch_layer_over_obs false -max_same_layer_jog_length 2 -padcore_ring_top_layer_limit Metal9 -padcore_ring_bottom_layer_limit Metal1 -block_ring_top_layer_limit Metal9 -block_ring_bottom_layer_limit Metal1 -use_wire_group 0 -snap_wire_center_to_grid None
addStripe -nets {VDD VSS} -layer Metal9 -direction horizontal -width 1.0 -spacing 1.0 -set_to_set_distance 24 -start_from bottom -start_offset 12 -switch_layer_over_obs false -max_same_layer_jog_length 2 -padcore_ring_top_layer_limit Metal9 -padcore_ring_bottom_layer_limit Metal1 -block_ring_top_layer_limit Metal9 -block_ring_bottom_layer_limit Metal1 -use_wire_group 0 -snap_wire_center_to_grid None
sroute -connect { blockPin padPin padRing corePin floatingStripe } -layerChangeRange { Metal1(1) Metal9(9) } -blockPinTarget { nearestTarget } -padPinPortConnect { allPort oneGeom } -padPinTarget { nearestTarget } -corePinTarget { firstAfterRowEnd } -floatingStripeTarget { blockring padring ring stripe ringpin blockpin followpin } -allowJogging 1 -crossoverViaLayerRange { Metal1(1) Metal9(9) } -nets { VDD VSS } -allowLayerChange 1 -blockPin useLef -targetViaLayerRange { Metal1(1) Metal9(9) }
saveDesign db/02_powerplan.enc
setDrawView fplan
fit
redraw
dumpToGIF screenshots/02_powerplan.gif
setPlaceMode -fp false
setPlaceMode -place_global_ignore_scan true
place_opt_design
addTieHiLo -cell {TIEHI TIELO} -prefix LTIE
checkPlace reports/01_checkPlace.rpt
timeDesign -preCTS -outDir reports/preCTS
saveDesign db/03_placement.enc
setDrawView place
fit
redraw
dumpToGIF screenshots/03_placement_physical.gif
setDrawView ameba
fit
redraw
dumpToGIF screenshots/03_placement_amoeba.gif
set_ccopt_property buffer_cells {CLKBUFX2 CLKBUFX3 CLKBUFX4 CLKBUFX6 CLKBUFX8 CLKBUFX12 CLKBUFX16 CLKBUFX20}
set_ccopt_property inverter_cells {CLKINVX1 CLKINVX2 CLKINVX3 CLKINVX4 CLKINVX6 CLKINVX8 CLKINVX12 CLKINVX16 CLKINVX20}
create_ccopt_clock_tree_spec -file reports/ccopt.spec
get_ccopt_clock_trees
ccopt_check_and_flatten_ilms_no_restore
set_ccopt_property cts_is_sdc_clock_root -pin clk true
create_ccopt_clock_tree -name clk -source clk -no_skew_group
set_ccopt_property clock_period -pin clk 10
set_ccopt_property timing_connectivity_info {}
create_ccopt_skew_group -name clk/cm_func -sources clk -auto_sinks
set_ccopt_property include_source_latency -skew_group clk/cm_func true
set_ccopt_property extracted_from_clock_name -skew_group clk/cm_func clk
set_ccopt_property extracted_from_constraint_mode_name -skew_group clk/cm_func cm_func
set_ccopt_property extracted_from_delay_corners -skew_group clk/cm_func {dc_worst dc_best}
check_ccopt_clock_tree_convergence
get_ccopt_property auto_design_state_for_ilms
ccopt_design
optDesign -postCTS -setup -hold
report_ccopt_clock_trees -file reports/02_cts_trees.rpt
report_ccopt_skew_groups -file reports/02_cts_skew.rpt
timeDesign -postCTS -outDir reports/postCTS
timeDesign -postCTS -hold -outDir reports/postCTS_hold
saveDesign db/04_cts.enc
setDrawView place
fit
redraw
dumpToGIF screenshots/04_cts.gif
setNanoRouteMode -quiet -drouteEndIteration default
setNanoRouteMode -quiet -routeWithTimingDriven true
setNanoRouteMode -quiet -routeWithSiDriven true
routeDesign -globalDetail
setAnalysisMode -analysisType onChipVariation -cppr both
optDesign -postRoute -setup -hold
timeDesign -postRoute -outDir reports/postRoute
timeDesign -postRoute -hold -outDir reports/postRoute_hold
saveDesign db/05_routed.enc
setDrawView place
fit
redraw
dumpToGIF screenshots/05_routed.gif
addFiller -cell {FILL64 FILL32 FILL16 FILL8 FILL4 FILL2 FILL1} -prefix FILLER -fitGap
verify_drc -report reports/03_verify_drc.rpt
verifyConnectivity -type all -error 1000 -warning 50 -report reports/04_verify_connectivity.rpt
verifyProcessAntenna -report reports/05_verify_antenna.rpt
report_area > reports/06_area.rpt
report_power > reports/07_power.rpt
report_timing -max_paths 10 -late > reports/08_timing_setup.rpt
report_timing -max_paths 10 -early > reports/09_timing_hold.rpt
summaryReport -noHtml -outfile reports/10_summary.rpt
saveDesign db/06_final.enc
saveNetlist outputs/cnn_top_pnr.v
defOut -floorplan -netlist -routing outputs/cnn_top_pnr.def
write_sdf outputs/cnn_top_pnr.sdf
setExtractRCMode -engine postRoute -effortLevel medium
extractRC
rcOut -spef outputs/cnn_top_worst.spef -rc_corner rc_worst
rcOut -spef outputs/cnn_top_best.spef -rc_corner rc_best
streamOut outputs/cnn_top_pnr.gds -mapFile streamOut.map -libName DesignLib -units 2000 -mode ALL
setDrawView place
fit
redraw
dumpToGIF screenshots/06_final_layout.gif
setDrawView ameba
fit
redraw
dumpToGIF screenshots/07_final_amoeba.gif
