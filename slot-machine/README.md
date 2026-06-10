# Slot Machine — 7-segment version (Basys3)

A one-armed bandit on FPGA. Three reels, seven symbols, scoring, and a "fire" animation across the 16 LEDs on a win. Reels are driven by three independent linear-feedback shift registers (LFSRs) for pseudo-randomness, and the whole thing is a clean finite-state machine.

> There's also an **LCD version** of this game as a sibling project: [`../slot-machine-lcd/`](../slot-machine-lcd/). It renders the reels, score, and a status word on a 16×2 HD44780 character LCD over Pmod JA, and is working on hardware.

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

Three reels plus the score (coins, shown as the units digit). Full bit-level segment encoding is in [`docs/segment-encoding.md`](docs/segment-encoding.md).

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

## Source files

| File | Role |
|---|---|
| `rtl/slot_machine_top.sv` | top module (FSM, LFSRs, scoring, LED fire) |
| `rtl/seg7_ctrl.sv` | 7-segment multiplexer + symbol/digit encoder |
| `rtl/debounce.sv` | button debounce |
| `sim/slot_machine_tb.sv` | testbench |
| `constraints/slot-machine.xdc` | pins |
| `docs/segment-encoding.md` | segment / symbol / payout reference |

## Build & run

1. In the Vivado Tcl Console, `cd` into this folder and run:
   ```tcl
   source scripts/create_project.tcl
   ```
2. Top module is `slot_machine_top`. Generate Bitstream → Program Device.
3. Set a bet on `sw[1:0]`, press `btnC` to spin.

## Notes

- The top module is `slot_machine_top` (a clean, modular refactor of an earlier monolithic prototype that was dropped).
- Segment encoding is active-LOW on the Basys3; see `docs/segment-encoding.md` if a symbol renders wrong.
