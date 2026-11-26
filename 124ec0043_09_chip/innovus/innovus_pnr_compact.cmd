#######################################################
#                                                     
#  Innovus Command Logging File                     
#  Created on Thu Nov 26 22:58:52 2026                
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
floorPlan -site CoreSite -s 64.0 64.0 10.0 10.0 10.0 10.0
setPinAssignMode -pinEditInBatch true
editPin -pin {clk rst_n start_i pixel_i[*]} -side Left -layer Metal3 -spreadType center -spacing 4.0
editPin -pin {logit0_o[*] logit1_o[*] logit2_o[*] logit3_o[*]} -side Top -layer Metal4 -spreadType center -spacing 0.40
editPin -pin {load_o pixel_idx_o[*] busy_o done_o prediction_o[*] logit4_o[*] logit5_o[*] logit6_o[*]} -side Right -layer Metal3 -spreadType center -spacing 0.38
editPin -pin {logit7_o[*] logit8_o[*] logit9_o[*]} -side Bottom -layer Metal4 -spreadType center -spacing 0.40
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
addStripe -nets {VDD VSS} -layer Metal8 -direction vertical -width 1.0 -spacing 1.0 -set_to_set_distance 20 -start_from left -start_offset 10 -switch_layer_over_obs false -max_same_layer_jog_length 2 -padcore_ring_top_layer_limit Metal9 -padcore_ring_bottom_layer_limit Metal1 -block_ring_top_layer_limit Metal9 -block_ring_bottom_layer_limit Metal1 -use_wire_group 0 -snap_wire_center_to_grid None
addStripe -nets {VDD VSS} -layer Metal9 -direction horizontal -width 1.0 -spacing 1.0 -set_to_set_distance 20 -start_from bottom -start_offset 10 -switch_layer_over_obs false -max_same_layer_jog_length 2 -padcore_ring_top_layer_limit Metal9 -padcore_ring_bottom_layer_limit Metal1 -block_ring_top_layer_limit Metal9 -block_ring_bottom_layer_limit Metal1 -use_wire_group 0 -snap_wire_center_to_grid None
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
