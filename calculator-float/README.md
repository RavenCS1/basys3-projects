# Mini-Float Calculator -- Basys3

A calculator that operates on a custom **7-bit floating-point format** -- a compact IEEE 754-style encoding with a sign bit, a 3-bit exponent, and a 3-bit mantissa. Same switch-driven workflow as the integer calculator, but the operands and result are real numbers shown with one decimal place.

## Target

| | |
|---|---|
| Board | Digilent Basys3 |
| FPGA | Xilinx Artix-7 `xc7a35tcpg236-1` |
| Clock | 100 MHz (used only to refresh the 7-segment display) |
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
| Normal | 1 <= E <= 6 | (-1)^S x (1 + M/8) x 2^(E-3) |
| Denormal | E = 0 | (-1)^S x (M/8) x 2^(-2) |
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
| 0 | 1 | A - B |
| 1 | 0 | A x B |
| 1 | 1 | A / B |

## Output

- **7-segment display** -- result as a decimal number with one fractional digit.
- **LEDs** -- raw fixed-point result in binary.
- Out-of-range or undefined results (E = 7) display `----`.
- Division by zero also displays `----`.

## Repository layout

```
calculator-float/
+-- README.md
+-- rtl/
|   +-- float_calculator_top.sv
+-- constraints/
|   +-- calc-float.xdc
+-- scripts/
    +-- create_project.tcl
```

## Build

From the Vivado Tcl Console, inside the `calculator-float/` directory:

```tcl
source scripts/create_project.tcl
```

Then: Generate Bitstream -> program the board.

## Notes

The format is intentionally tiny, so rounding is coarse and the representable range is small. That is the point: it is a hands-on way to see how exponent and mantissa bits trade range against precision, and how denormals fill in the gap near zero.
