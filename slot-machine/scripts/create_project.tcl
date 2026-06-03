# ============================================================
#  create_project.tcl  -  slot-machine
#  Run from Vivado Tcl Console:   source scripts/create_project.tcl
#  or headless:  vivado -mode batch -source scripts/create_project.tcl
# ============================================================

# locate project root (this script lives in <root>/scripts/)
set script_dir [file dirname [file normalize [info script]]]
set proj_root  [file dirname $script_dir]

set proj_name "slot-machine"
set part      "xc7a35tcpg236-1"
set top       "slot_machine_top_v2"

create_project $proj_name "$proj_root/vivado_project" -part $part -force

# ---- RTL sources ----
set rtl [glob -nocomplain "$proj_root/rtl/*.sv" "$proj_root/rtl/*.v"]
if {[llength $rtl] == 0} { error "No RTL files found in $proj_root/rtl" }
add_files -norecurse $rtl

# ---- constraints ----
set xdc [glob -nocomplain "$proj_root/constraints/*.xdc"]
if {[llength $xdc] > 0} { add_files -fileset constrs_1 -norecurse $xdc }

# ---- simulation sources ----
set sim [glob -nocomplain "$proj_root/sim/*.sv"]
if {[llength $sim] > 0} { add_files -fileset sim_1 -norecurse $sim }

set_property file_type SystemVerilog [get_files *.sv]
set_property top $top [current_fileset]
update_compile_order -fileset sources_1

puts ""
puts "Project '$proj_name' created at $proj_root/vivado_project"
puts "Top module: $top"
puts "Next: Generate Bitstream, then program the board."