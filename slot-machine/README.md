# Slot Machine -- Basys3

A one-armed bandit on FPGA. Three reels, seven symbols, scoring, and a fire animation across the 16 LEDs on a win. Reels are driven by three independent linear-feedback shift registers (LFSRs) for pseudo-randomness, and the whole thing is a clean finite-state machine.

## Target

| | |
|---|---|
| Board | Digilent Basys3 |
| FPGA | Xilinx Artix-7 `xc7a35tcpg236-1` |
| Clock | 100 MHz |
| Language | SystemVerilog |

## Controls

| Input | Meaning |
|---|---|
| `btnC` (center) | SPIN / confirm result |
| `btnU` (up) | RESET (score back to 10) |
| `sw[1:0]` | Bet (00/01 = 1, 10 = 2, 11 = 3) |

Keep all other switches down.

## Display (7-segment)

```
+----+----+----+----+
| R1 | R2 | R3 | SC |
+----+----+----+----+
```

Three reels plus the score (coins, units digit shown).

### Symbols

| Shown | Symbol |
|---|---|
| `7` | Seven |
| `3` | Three |
| `C` | Cherry |
| `b` | BAR / Bell |
| `H` | Horse |
| `L` | Lemon |

## Payouts

| Combination | Reward |
|---|---|
| `7 - 7 - 7` | Jackpot, +50 |
| three of a kind | +20 |
| two of a kind | +2 x bet |
| no match | -bet |

## LED fire effect

| State | LEDs |
|---|---|
| Idle | dim flicker (every other LED) |
| Spinning | running single bit |
| Win | full fire animation (LFSR flame wave) |
| Lose | blinking checkerboard |

## Repository layout

```
slot-machine/
+-- README.md
+-- rtl/
|   +-- slot_machine_top_v2.sv
|   +-- seg7_ctrl.sv
|   +-- debounce.sv
|   +-- seg7_encoding.sv   (reference table, not synthesised)
+-- sim/
|   +-- slot_machine_tb.sv
+-- constraints/
|   +-- slot-machine.xdc
+-- scripts/
    +-- create_project.tcl
```

## Build

From the Vivado Tcl Console, inside the `slot-machine/` directory:

```tcl
source scripts/create_project.tcl
```

Then: Generate Bitstream -> program the board. Set a bet on `sw[1:0]`, press `btnC` to spin.

## LCD version (in progress)

A variant that renders the whole game on a 16x2 HD44780 character LCD (wired to Pmod JA, 4-bit mode) is being built, so the reels, score, and a status word (`SPIN?`, `WIN!`, `JACKPT`, `LOSE`) all fit on screen instead of being squeezed into four 7-segment digits. Modules planned: `lcd_hd44780.sv` (display driver), `game_text.sv` (state to text), `slot_machine_lcd_top.sv` (top).
