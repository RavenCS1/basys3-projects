# Slot Machine — Basys3

A one-armed bandit on FPGA. Three reels, seven symbols, scoring, and a "fire" animation across the 16 LEDs on a win. Reels are driven by three independent linear-feedback shift registers (LFSRs) for pseudo-randomness, and the whole thing is a clean finite-state machine.

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
| `sw[1:0]` | Bet (00/01 → 1, 10 → 2, 11 → 3) |

Keep all other switches down.

## Display (7-segment)

```
┌────┬────┬────┬────┐
│ R1 │ R2 │ R3 │ SC │
└────┴────┴────┴────┘
```

Three reels plus the score (coins, shown as the units digit).

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
| `7 · 7 · 7` | Jackpot, +50 |
| three of a kind | +20 |
| two of a kind | +2 × bet |
| no match | lose the bet |

## LED fire effect

| State | LEDs |
|---|---|
| Idle | dim flicker |
| Spinning | running bit |
| Win | full fire animation |
| Lose | blinking checkerboard |

## Repository layout

```
slot-machine-basys3/
├── README.md
├── rtl/
│   ├── slot_machine_top_v2.sv
│   ├── seg7_ctrl.sv
│   └── debounce.sv
├── sim/
│   └── slot_machine_tb.sv
├── constraints/
│   └── Basys3.xdc
├── scripts/
│   └── create_project.tcl
└── docs/
    └── lcd_schematic.png
```

## Build & run

1. Create an RTL project for `xc7a35tcpg236-1` (or `source scripts/create_project.tcl`).
2. Add the `rtl/` files and `constraints/Basys3.xdc`, set `slot_machine_top_v2` as top.
3. Generate Bitstream → program the board.
4. Set a bet on `sw[1:0]`, press `btnC` to spin.

## LCD version (in progress)

A variant that renders the whole game on a **16×2 HD44780 character LCD** (wired to Pmod JA, 4-bit mode) is being built, so the reels, score, and a status word (`SPIN?`, `WIN!`, `JACKPT`, `LOSE`) all fit on screen instead of being squeezed into four 7-seg digits. See `docs/lcd_schematic.png` for the wiring. Modules: `lcd_hd44780.sv` (display driver), `game_text.sv` (state → text), `slot_machine_lcd_top.sv` (top).
