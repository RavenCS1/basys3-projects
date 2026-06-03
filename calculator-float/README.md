# Mini-Float Calculator — Basys3

A calculator that operates on a custom **7-bit floating-point format** — a tiny IEEE-754-style encoding with a sign, a 3-bit exponent, and a 3-bit mantissa. Same switch-driven workflow as the integer calculator, but the operands and result are real numbers, shown with one decimal place.

## Target

| | |
|---|---|
| Board | Digilent Basys3 |
| FPGA | Xilinx Artix-7 `xc7a35tcpg236-1` |
| Language | SystemVerilog |

## The 7-bit float format

```
 bit:   6   5 4 3   2 1 0
       [S] [ E E E ] [ M M M ]
       sign  exp(3)   mantissa(3)
```

Exponent bias = 3.

| Case | Exponent | Value |
|---|---|---|
| Normal | 1 ≤ E ≤ 6 | (−1)^S × (1 + M/8) × 2^(E−3) |
| Denormal | E = 0 | (−1)^S × (M/8) × 2^(−2) |
| Inf / NaN | E = 7 | display shows `----` |

## Controls

| Input | Meaning |
|---|---|
| `sw[6:0]` | Operand A (7-bit float) |
| `sw[13:7]` | Operand B (7-bit float) |
| `sw[15:14]` | Operation |
| `btnC` (center) | Reset |

### Operation select

| `sw[15]` | `sw[14]` | Operation |
|---|---|---|
| 0 | 0 | A + B |
| 0 | 1 | A − B |
| 1 | 0 | A × B |
| 1 | 1 | A ÷ B |

## Output

- **7-segment display** — result as a decimal number with one fractional digit.
- **LEDs** — raw fixed-point result in binary.
- Out-of-range / undefined results (E = 7) display `----`.

## Repository layout

```
calculator-float-basys3/
├── README.md
├── rtl/
│   └── float_calculator_top.sv
├── constraints/
│   └── Basys3.xdc
└── scripts/
    └── create_project.tcl
```

## Build & run

1. Create an RTL project for `xc7a35tcpg236-1` (or `source scripts/create_project.tcl`).
2. Add the RTL and `constraints/Basys3.xdc`, set `float_calculator_top` as top.
3. Generate Bitstream → program the board.

## Notes

This format is intentionally tiny, so rounding is coarse and the representable range is small — that's the point. It's a hands-on way to *see* how exponent and mantissa bits trade range against precision, and how denormals fill in the gap near zero.
