## Basys3 Constraints – Slot Machine on HD44780 LCD (Pmod JA)
## LCD wired in 4-bit mode, RW tied to GND.

# ── Clock 100 MHz ────────────────────────────────────────────
set_property PACKAGE_PIN W5 [get_ports clk]
set_property IOSTANDARD LVCMOS33 [get_ports clk]
create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports clk]

# ── Buttons ──────────────────────────────────────────────────
set_property PACKAGE_PIN U18 [get_ports btnC]   ;# center -> SPIN
set_property IOSTANDARD LVCMOS33 [get_ports btnC]
set_property PACKAGE_PIN T18 [get_ports btnU]   ;# up -> RESET
set_property IOSTANDARD LVCMOS33 [get_ports btnU]

# ── Switches (bet) ───────────────────────────────────────────
set_property PACKAGE_PIN V17 [get_ports {sw[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sw[0]}]
set_property PACKAGE_PIN V16 [get_ports {sw[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sw[1]}]

# ── LCD on Pmod JA (4-bit) ───────────────────────────────────
# JA1=J1  JA2=L2  JA3=J2  JA4=G2  JA7=H1  JA8=K2
set_property PACKAGE_PIN J1 [get_ports lcd_rs]        ;# JA1  -> LCD RS  (pin 4)
set_property PACKAGE_PIN L2 [get_ports lcd_e]         ;# JA2  -> LCD E   (pin 6)
set_property PACKAGE_PIN J2 [get_ports {lcd_d[0]}]    ;# JA3  -> LCD D4  (pin 11)
set_property PACKAGE_PIN G2 [get_ports {lcd_d[1]}]    ;# JA4  -> LCD D5  (pin 12)
set_property PACKAGE_PIN H1 [get_ports {lcd_d[2]}]    ;# JA7  -> LCD D6  (pin 13)
set_property PACKAGE_PIN K2 [get_ports {lcd_d[3]}]    ;# JA8  -> LCD D7  (pin 14)
set_property IOSTANDARD LVCMOS33 [get_ports lcd_rs]
set_property IOSTANDARD LVCMOS33 [get_ports lcd_e]
set_property IOSTANDARD LVCMOS33 [get_ports {lcd_d[*]}]

# ── LEDs (fire effect) ───────────────────────────────────────
set_property PACKAGE_PIN U16 [get_ports {led[0]}]
set_property PACKAGE_PIN E19 [get_ports {led[1]}]
set_property PACKAGE_PIN U19 [get_ports {led[2]}]
set_property PACKAGE_PIN V19 [get_ports {led[3]}]
set_property PACKAGE_PIN W18 [get_ports {led[4]}]
set_property PACKAGE_PIN U15 [get_ports {led[5]}]
set_property PACKAGE_PIN U14 [get_ports {led[6]}]
set_property PACKAGE_PIN V14 [get_ports {led[7]}]
set_property PACKAGE_PIN V13 [get_ports {led[8]}]
set_property PACKAGE_PIN V3  [get_ports {led[9]}]
set_property PACKAGE_PIN W3  [get_ports {led[10]}]
set_property PACKAGE_PIN U3  [get_ports {led[11]}]
set_property PACKAGE_PIN P3  [get_ports {led[12]}]
set_property PACKAGE_PIN N3  [get_ports {led[13]}]
set_property PACKAGE_PIN P1  [get_ports {led[14]}]
set_property PACKAGE_PIN L1  [get_ports {led[15]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[*]}]

set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]
