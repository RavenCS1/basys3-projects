# Basys3 FPGA Projects

A collection of digital-logic projects for the **Digilent Basys3** development board, written in SystemVerilog. They range from a one-line "is my toolchain alive" blink up to a full state-machine slot-machine game, and are meant to be read in roughly that order — each one introduces a little more (clock division, combinational ALUs, display multiplexing, FSMs, LFSRs).

## Projects

| Project | What it is | Highlights |
|---|---|---|
| [`blink/`](blink/) | LED blink ("hello world") | clock divider, smallest possible design |
| [`calculator-int/`](calculator-int/) | 4-bit integer calculator | switch-driven ALU, +, −, ×, ÷ |
| [`calculator-float/`](calculator-float/) | 7-bit mini-float calculator | custom sign/exponent/mantissa format, denormals |
| [`slot-machine/`](slot-machine/) | One-armed bandit game | FSM, 3× LFSR RNG, scoring, LED fire effect |

A variant of the slot machine that renders on a **16×2 HD44780 character LCD** (over Pmod JA) is in progress — see the note in [`slot-machine/README.md`](slot-machine/README.md).

## Target hardware

| | |
|---|---|
| Board | Digilent Basys3 |
| FPGA | Xilinx Artix-7 `xc7a35tcpg236-1` |
| Clock | 100 MHz (board oscillator, pin W5) |
| Toolchain | Xilinx Vivado |
| Language | SystemVerilog |

## Repository layout

```
basys3-projects/
├── README.md              ← you are here
├── LICENSE
├── blink/
│   ├── README.md
│   ├── rtl/
│   ├── constraints/
│   └── scripts/
├── calculator-int/
│   └── …
├── calculator-float/
│   └── …
└── slot-machine/
    ├── rtl/
    ├── sim/
    ├── constraints/
    ├── scripts/
    └── docs/
```

Each project is self-contained: its own sources, constraints, and a `create_project.tcl` that rebuilds the Vivado project from scratch.

## Building any project

Vivado project files (the `.runs`, `.cache`, etc.) are **not** committed — they're regenerated from a Tcl script. To build a project:

1. Open Vivado and launch the Tcl Console.
2. `cd` into the project folder and run its script:
   ```tcl
   source scripts/create_project.tcl
   ```
   (or do it by hand: create an RTL project for `xc7a35tcpg236-1`, add the `rtl/` and `constraints/` files, set the top module.)
3. **Generate Bitstream** → **Open Hardware Manager** → **Program Device**.

Connect the board over USB before programming — the same cable powers the board and loads the bitstream. Make sure the **POWER** switch is ON.

## License

Released under the MIT License — see [`LICENSE`](LICENSE).
