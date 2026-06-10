# 7-Segment Encoding Reference (Basys3)

Reference for the 7-segment display used by the slot machine (and the calculators).

## Segment layout

```
     aaa
    f   b
    f   b
     ggg
    e   c
    e   c
     ddd   • dp
```

On the Basys3 the segments are **active LOW** (0 lights a segment, 1 turns it off).
The bus is `seg[6:0] = {g, f, e, d, c, b, a}`, i.e. bit 0 = a, bit 6 = g.

## Slot-machine symbols

| Code | Shown | Symbol | `seg[6:0]` |
|---|---|---|---|
| 0 | `b` | BAR | `0000011` |
| 1 | `7` | Seven | `1111000` |
| 2 | `3` | Three | `0110000` |
| 3 | `C` | Cherry | `1000110` |
| 4 | `b` | Bell | `0000011` |
| 5 | `H` | Horse | `0001001` |
| 6 | `L` | Lemon | `1000111` |

## Decimal digits

| Digit | `seg[6:0]` |
|---|---|
| 0 | `1000000` |
| 1 | `1111001` |
| 2 | `0100100` |
| 3 | `0110000` |
| 4 | `0011001` |
| 5 | `0010010` |
| 6 | `0000010` |
| 7 | `1111000` |
| 8 | `0000000` |
| 9 | `0010000` |

## Display layout (slot machine, 7-seg version)

```
┌────┬────┬────┬────┐
│ R1 │ R2 │ R3 │ SC │
└────┴────┴────┴────┘
 an[3] an[2] an[1] an[0]
```

Three reels + score (units digit). Anodes `an[3:0]` are active LOW, multiplexed at ~763 Hz.

## Payout table

| Combination | Reward |
|---|---|
| `7 · 7 · 7` | Jackpot, +50 |
| three of a kind | +20 |
| two of a kind | +2 × bet |
| no match | lose the bet |

## LED fire effect

| State | LEDs |
|---|---|
| Idle | dim flicker (every other LED) |
| Spinning | running bit |
| Win | full fire animation |
| Lose | blinking checkerboard |
