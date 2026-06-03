# Blink -- Basys3

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
100 MHz --> [ 26-bit counter ] --> LED (LD0)
```

## Repository layout

```
blink/
+-- README.md
+-- rtl/
|   +-- blink_top.sv
+-- constraints/
|   +-- blink.xdc
+-- scripts/
    +-- create_project.tcl
```

## Build

From the Vivado Tcl Console, inside the `blink/` directory:

```tcl
source scripts/create_project.tcl
```

Then: Generate Bitstream -> Open Hardware Manager -> Program Device.

## Usage

Once programmed, LD0 blinks at approximately 1 Hz. If it blinks, the full toolchain flow works.

To change the blink rate, edit the bit index that drives `led` in `rtl/blink_top.sv`: a lower index gives a faster blink, a higher index gives a slower one.
