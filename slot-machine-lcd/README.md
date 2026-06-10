# Slot Machine — LCD version (Basys3)

The one-armed bandit, rendered on a **16×2 HD44780 character LCD** wired to Pmod JA in 4-bit mode. Same game logic as the 7-segment version (`../slot-machine/`) — FSM, three LFSR reels, scoring, LED fire effect — but the reels, score, and a status word all show on the LCD instead of being squeezed into four 7-seg digits.

> Status: **working on hardware.** Tested on a 20×4 panel driven as 16×2 (it uses the top two rows). The wiring below is verified.

## Target

| | |
|---|---|
| Board | Digilent Basys3 |
| FPGA | Xilinx Artix-7 `xc7a35tcpg236-1` |
| Display | HD44780 character LCD, 4-bit parallel (NOT I²C) |
| Language | SystemVerilog |

## What it shows

```
REELS: 7 C H
COINS:012 JACKPT
```

- **Line 1** — the three reels.
- **Line 2** — coins (3 digits) + status: `SPIN?`, `SPIN..`, `WIN!`, `WIN20`, `JACKPT`, or `LOSE`.

Symbols map to: `7` `3` `C`(herry) `B`(ell) `H`(orse) `L`(emon) `=`(BAR).

## Controls

| Input | Meaning |
|---|---|
| `btnC` (center) | SPIN / confirm result |
| `btnU` (up) | RESET (score back to 10) |
| `sw[1:0]` | Bet (00/01 → 1, 10 → 2, 11 → 3) |

## Payouts

| Combination | Reward |
|---|---|
| `7 · 7 · 7` | Jackpot, +50 |
| three of a kind | +20 |
| two of a kind | +2 × bet |
| no match | lose the bet |

## Wiring (LCD → Pmod JA, 4-bit)

Power the LCD from the Pmod's **3.3 V** (everything stays 3.3 V — clean). RW is tied to GND (write-only).

| LCD pin | Goes to |
|---|---|
| 1 · VSS (GND) | GND rail |
| 2 · VDD | 3.3 V rail |
| 3 · V0 | potentiometer wiper |
| 4 · RS | JA1 (J1) |
| 5 · RW | GND rail |
| 6 · E | JA2 (L2) |
| 7–10 · D0–D3 | not connected |
| 11 · D4 | JA3 (J2) |
| 12 · D5 | JA4 (G2) |
| 13 · D6 | JA7 (H1) |
| 14 · D7 | JA8 (K2) |
| 15 · A (LED+) | 3.3 V (via ~220 Ω if no onboard resistor) |
| 16 · K (LED−) | GND rail |

**Contrast pot (10 kΩ):** outer legs to 3.3 V and GND, wiper to LCD pin 3.

> **Note on V0 / contrast:** V0 needs nothing but the pot wiper — there's nothing else to "connect." If the screen is blank or shows solid blocks, the fix is almost always just **turning the potentiometer** until the text appears. That's the single most common gotcha with these displays.

Pmod JA holes (pin 1 is marked on the board):
```
top:    [1][2][3][4][5=GND][6=3V3]
bottom: [7][8][9][10][11=GND][12=3V3]
```

See `docs/lcd_schematic.png` for the full schematic.

## Source files

| File | Role |
|---|---|
| `rtl/slot_machine_lcd_top.sv` | top module (FSM, LFSRs, scoring, LED fire) |
| `rtl/lcd_hd44780.sv` | HD44780 driver: power-on init + continuous 4-bit refresh |
| `rtl/game_text.sv` | turns game state into two 16-char ASCII lines |
| `rtl/debounce.sv` | button debounce |
| `constraints/slot-machine-lcd.xdc` | pins (Pmod JA + buttons + switches + LEDs) |

## Build & run

1. `cd` into this folder in the Vivado Tcl Console and run:
   ```tcl
   source scripts/create_project.tcl
   ```
2. Top module is `slot_machine_lcd_top`. Generate Bitstream → Program Device.
3. Power on, **turn the contrast pot** until text appears.
4. Set a bet on `sw[1:0]`, press `btnC` to spin.

## Notes & next steps

- The panel is a 20×4 but the code currently uses it as 16×2 (top-left). Expanding `game_text.sv` and the driver's line addressing to all four rows (row 3 = DDRAM 0x14, row 4 = 0x54) would let it use the full screen — a title bar, larger reels, a winnings line.
- This is the **parallel** (16-pin) build. If you ever switch to the I²C backpack module (PCF8574), this driver won't work — that needs an I²C controller instead.
