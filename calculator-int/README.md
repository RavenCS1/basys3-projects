# Integer Calculator — Basys3

A 4-bit integer calculator driven entirely by the on-board switches. Pick two operands and an operation; the result shows in decimal on the 7-segment display and in binary on the LEDs. No clock-domain tricks, no memory — pure combinational ALU plus a display multiplexer.

## Target

| | |
|---|---|
| Board | Digilent Basys3 |
| FPGA | Xilinx Artix-7 `xc7a35tcpg236-1` |
| Clock | 100 MHz (only used to refresh the 7-seg display) |
| Language | SystemVerilog |

## Controls

| Input | Meaning |
|---|---|
| `sw[3:0]` | Operand A (0–15) |
| `sw[7:4]` | Operand B (0–15) |
| `sw[15:14]` | Operation (see below) |
| `btnC` (center) | Reset |

### Operation select

| `sw[15]` | `sw[14]` | Operation |
|---|---|---|
| 0 | 0 | A + B |
| 0 | 1 | A − B |
| 1 | 0 | A × B |
| 1 | 1 | A ÷ B |

Switches `sw[13:8]` are unused.

## Output

- **7-segment display** — result in decimal.
- **LEDs** — same result in binary.
- Subtraction returns a magnitude with a negative flag (the result of A − B is shown as its absolute value; a sign indicator marks negatives).

### Ranges

| Op | Range |
|---|---|
| Add | 0 … 30 |
| Subtract | −15 … 15 |
| Multiply | 0 … 225 |
| Divide | integer quotient (B = 0 guarded) |

## Example

Compute 5 + 3:

- A = 5 → `sw[3:0]` = `0101`
- B = 3 → `sw[7:4]` = `0011`
- Op = add → `sw[15:14]` = `00`

Display shows **8**.

## Repository layout

```
calculator-int-basys3/
├── README.md
├── rtl/
│   └── calculator_top.sv
├── constraints/
│   └── Basys3.xdc
└── scripts/
    └── create_project.tcl
```

## Build & run

1. Create an RTL project for `xc7a35tcpg236-1` (or `source scripts/create_project.tcl`).
2. Add `rtl/calculator_top.sv` and `constraints/Basys3.xdc`, set `calculator_top` as top.
3. Generate Bitstream → program the board.
4. Flip the switches and read the display.
