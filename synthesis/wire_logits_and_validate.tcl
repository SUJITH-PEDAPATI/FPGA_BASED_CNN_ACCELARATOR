open_project E:/QUANTA_VLSI/success_test_1/success_test_1.xpr
open_bd_design [get_files *vlsi_design.bd]

# Connect the 10 logit pins from cnn_top_0 to ila_0
connect_bd_net [get_bd_pins /cnn_top_0/logit0_o] [get_bd_pins /ila_0/probe7]
connect_bd_net [get_bd_pins /cnn_top_0/logit1_o] [get_bd_pins /ila_0/probe8]
connect_bd_net [get_bd_pins /cnn_top_0/logit2_o] [get_bd_pins /ila_0/probe9]
connect_bd_net [get_bd_pins /cnn_top_0/logit3_o] [get_bd_pins /ila_0/probe10]
connect_bd_net [get_bd_pins /cnn_top_0/logit4_o] [get_bd_pins /ila_0/probe11]
connect_bd_net [get_bd_pins /cnn_top_0/logit5_o] [get_bd_pins /ila_0/probe12]
connect_bd_net [get_bd_pins /cnn_top_0/logit6_o] [get_bd_pins /ila_0/probe13]
connect_bd_net [get_bd_pins /cnn_top_0/logit7_o] [get_bd_pins /ila_0/probe5]
connect_bd_net [get_bd_pins /cnn_top_0/logit8_o] [get_bd_pins /ila_0/probe14]
connect_bd_net [get_bd_pins /cnn_top_0/logit9_o] [get_bd_pins /ila_0/probe15]

# Validate block design
validate_bd_design

# Save block design
save_bd_design

# Regenerate HDL wrapper and output products
make_wrapper -files [get_files *vlsi_design.bd] -top -import -force
generate_target all [get_files *vlsi_design.bd]
update_compile_order -fileset sources_1

puts "VALIDATE_AND_WIRE_COMPLETED_SUCCESSFULLY"
close_project
