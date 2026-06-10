# ============================================================
#  create_project.tcl  -  slot-machine-lcd  (HD44780, 16-bit/4-bit direct)
#  Run from Vivado Tcl Console:
#     cd C:/sciezka/do/slot-machine-lcd
#     source scripts/create_project.tcl
#  or headless:
#     vivado -mode batch -source scripts/create_project.tcl
# ============================================================

# locate project root (this script lives in <root>/scripts/)
set script_dir [file dirname [file normalize [info script]]]
set proj_root  [file dirname $script_dir]

set proj_name "slot-machine-lcd"
set part      "xc7a35tcpg236-1"
set top       "slot_machine_lcd_top"

create_project $proj_name "$proj_root/vivado_project" -part $part -force

# ---- RTL sources ----
set rtl [glob -nocomplain "$proj_root/rtl/*.sv"]
if {[llength $rtl] == 0} {
    error "No RTL files found in $proj_root/rtl  (czy wkleiles kod do plikow?)"
}
add_files -norecurse $rtl

# ---- constraints ----
set xdc [glob -nocomplain "$proj_root/constraints/*.xdc"]
if {[llength $xdc] == 0} {
    error "No .xdc found in $proj_root/constraints"
}
add_files -fileset constrs_1 -norecurse $xdc

set_property file_type SystemVerilog [get_files *.sv]
set_property top $top [current_fileset]
update_compile_order -fileset sources_1

puts ""
puts "================================================="
puts " Project '$proj_name' utworzony."
puts " Top module: $top"
puts " RTL plikow: [llength $rtl]"
puts " Dalej: Generate Bitstream -> Program Device"
puts "================================================="