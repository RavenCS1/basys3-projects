# ============================================================
#  create_project.tcl  -  slot-machine (7-seg)
#  Run:  cd <project folder>;  source scripts/create_project.tcl
# ============================================================
set script_dir [file dirname [file normalize [info script]]]
set proj_root  [file dirname $script_dir]

set proj_name "slot-machine"
set part      "xc7a35tcpg236-1"
set top       "slot_machine_top"

create_project $proj_name "$proj_root/vivado_project" -part $part -force

# ---- RTL sources ----
set rtl [glob -nocomplain "$proj_root/rtl/*.sv"]
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
puts "Project '$proj_name' created. Top module: $top"
puts "Next: Generate Bitstream -> Program Device."
