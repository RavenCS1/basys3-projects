# Basys3 FPGA Projects

A collection of digital-logic projects for the **Digilent Basys3** development board, written in SystemVerilog. They run from a one-line "is my toolchain alive" blink up to a slot-machine game with two front-ends (7-segment and a character LCD), and are roughly ordered by complexity — each introduces a little more (clock division, combinational ALUs, display multiplexing, FSMs, LFSRs, an external display driver).

## Projects

| Project | What it is | Highlights |
|---|---|---|
| [`blink/`](blink/) | LED blink ("hello world") | clock divider, smallest possible design |
| [`calculator-int/`](calculator-int/) | 4-bit integer calculator | switch-driven ALU: +, −, ×, ÷ |
| [`calculator-float/`](calculator-float/) | 7-bit mini-float calculator | custom sign/exponent/mantissa format, denormals |
| [`slot-machine/`](slot-machine/) | One-armed bandit (7-seg) | FSM, 3× LFSR RNG, scoring, LED fire effect |
| [`slot-machine-lcd/`](slot-machine-lcd/) | Same game on a 16×2 LCD | HD44780 driver, Pmod JA, 4-bit mode — **working** |

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
├── README.md
├── LICENSE
├── .gitignore
├── blink/
│   ├── README.md
│   ├── rtl/blink_top.sv
│   ├── constraints/blink.xdc
│   └── scripts/create_project.tcl
├── calculator-int/
│   ├── README.md
│   ├── rtl/calculator_top.sv
│   ├── constraints/calculator-int.xdc
│   └── scripts/create_project.tcl
├── calculator-float/
│   ├── README.md
│   ├── rtl/float_calculator_top.sv
│   ├── constraints/calculator-float.xdc
│   └── scripts/create_project.tcl
├── slot-machine/
│   ├── README.md
│   ├── rtl/{slot_machine_top_v2,seg7_ctrl,debounce}.sv
│   ├── sim/slot_machine_tb.sv
│   ├── docs/segment-encoding.md
│   ├── constraints/slot-machine.xdc
│   └── scripts/create_project.tcl
└── slot-machine-lcd/
    ├── README.md
    ├── rtl/{slot_machine_lcd_top,lcd_hd44780,game_text,debounce}.sv
    ├── docs/lcd_schematic.png
    ├── constraints/slot-machine-lcd.xdc
    └── scripts/create_project.tcl
```

## Conventions

Kept consistent across every project:

- **One project = one top-level folder**, named in `kebab-case`.
- Every project has `rtl/`, `constraints/`, `scripts/`, plus `sim/` and `docs/` where useful.
- **SystemVerilog files and modules** use `snake_case` (Verilog convention). The top module is named `<thing>_top`.
- The **constraints file is named after its folder**: `blink/constraints/blink.xdc`, `slot-machine-lcd/constraints/slot-machine-lcd.xdc`, etc.
- Each project carries its own `README.md` and a `scripts/create_project.tcl` that rebuilds the Vivado project from scratch.
- The 7-segment and LCD versions of the slot machine are **separate sibling projects**, not nested variants.

## Building any project

Vivado project files (`.runs`, `.cache`, `.gen`, etc.) are **not** committed — they're regenerated from the Tcl script. To build:

1. Open Vivado, launch the Tcl Console.
2. `cd` into the project folder and run its script (use forward slashes, even on Windows):
   ```tcl
   cd C:/fpga/basys3-projects/slot-machine-lcd
   source scripts/create_project.tcl
   ```
3. **Generate Bitstream → Open Hardware Manager → Program Device**.

Connect the board over USB before programming — the same cable powers the board and loads the bitstream. Make sure the **POWER** switch is ON.

## License

MIT — see [`LICENSE`](LICENSE).
