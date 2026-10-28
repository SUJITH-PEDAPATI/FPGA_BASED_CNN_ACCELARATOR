open_project E:/QUANTA_VLSI/success_test_1/success_test_1.xpr
open_bd_design [get_files *vlsi_design.bd]
puts "=== ILA PINS ==="
foreach pin [get_bd_pins /ila_0/*] {
    puts "ILA PIN: $pin -> net: [get_bd_nets -quiet -of_objects $pin]"
}
puts "=== CNN TOP PINS ==="
foreach pin [get_bd_pins /cnn_top_0/*] {
    puts "CNN PIN: $pin -> net: [get_bd_nets -quiet -of_objects $pin]"
}
puts "=== ALL BD NETS ==="
foreach net [get_bd_nets] {
    puts "NET: $net"
}
close_project
