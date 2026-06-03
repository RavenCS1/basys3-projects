# Blink — Basys3

A minimal "hello world" for FPGA: divide the 100 MHz board clock down and toggle an on-board LED at roughly 1 Hz. The smallest possible design that proves your toolchain, board, and bitstream-loading all work.

## Target

| | |
|---|---|
| Board | Digilent Basys3 |
| FPGA | Xilinx Artix-7 `xc7a35tcpg236-1` |
| Clock | 100 MHz (pin W5) |
| Language | SystemVerilog |

## What it does

A counter increments on every 100 MHz clock edge. A high bit of that counter drives an LED, so the LED blinks at a slow, visible rate. Change which bit you tap to make it faster or slower (each higher bit halves the frequency).

```
100 MHz ─► [ N-bit counter ] ─► LED (LD0)
```

## Repository layout

```
blink-basys3/
├── README.md
├── rtl/
│   └── blink_top.sv
├── constraints/
│   └── Basys3.xdc
└── scripts/
    └── create_project.tcl
```

## Build & run

1. Open Vivado, create an RTL project for part `xc7a35tcpg236-1` (or run `scripts/create_project.tcl` from the Tcl Console: `source scripts/create_project.tcl`).
2. Add `rtl/blink_top.sv` and `constraints/Basys3.xdc`.
3. Set `blink_top` as the top module.
4. Generate Bitstream → Open Hardware Manager → Program Device.

## Usage

Once programmed, **LD0** blinks at ~1 Hz. That's it — if it blinks, your whole flow works.

To change the rate, edit the bit index that drives the LED in `blink_top.sv`: a lower bit = faster blink, a higher bit = slower.
