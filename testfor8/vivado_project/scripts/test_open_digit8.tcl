# test_open_digit8.tcl
set proj_path "F:/QUANTA_2/testfor8/vivado_project/cnn_accelerator_digit8.xpr"
puts "=== Opening project $proj_path ==="
open_project $proj_path
puts "Project opened successfully!"

puts "=== Sources in sources_1 ==="
foreach f [get_files -of_objects [get_filesets sources_1]] {
    puts "  $f"
}

puts "=== Block Designs ==="
foreach f [get_files *.bd] {
    puts "  $f"
}

close_project
exit 0

