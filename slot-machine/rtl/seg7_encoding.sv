// ============================================================
//  seg7_encoding.sv  --  segment encoding reference table
//  Reference file only -- this file contains no synthesisable RTL.
//
//  Basys3 7-segment display layout:
//
//       aaa
//      f   b
//      f   b
//       ggg
//      e   c
//      e   c
//       ddd   dp
//
//  Port seg[6:0] = {g, f, e, d, c, b, a}  (active low)
//  Bits:            6  5  4  3  2  1  0
// ============================================================

//  Symbol  |  Hex   | g f e d c b a | Appearance
//  --------|--------|---------------|------------------
//  b (BAR) |  7'h03 | 0 0 0 0 0 1 1 | lowercase b
//  7 (7)   |  7'h78 | 1 1 1 1 0 0 0 | digit 7
//  3 (3)   |  7'h30 | 0 1 1 0 0 0 0 | digit 3
//  C (Ch)  |  7'h46 | 1 0 0 0 1 1 0 | uppercase C
//  H (Ho)  |  7'h09 | 0 0 0 0 1 0 0 | uppercase H (f,g,b,e,c)  (note: bit 3=d off)
//  L (Le)  |  7'h47 | 1 0 0 0 1 1 1 | uppercase L (f,e,d)
//
//  Note: the Basys3 has a 4-digit display.
//  Anodes an[3:0] drive digits left to right.
//  an[3] = leftmost digit, an[0] = rightmost digit (active low).
//
//  Display layout:
//  +------+------+------+------+
//  | R1   | R2   | R3   |  SC  |
//  | reel | reel | reel | score|
//  |  0   |  1   |  2   | units|
//  +------+------+------+------+
//   an[3]  an[2]  an[1]  an[0]
//
// ============================================================
//  Payout table
//  +---------------------+--------------+
//  | Combination         | Reward       |
//  +---------------------+--------------+
//  |  7 - 7 - 7          | Jackpot  +50 |
//  |  x - x - x          | Match    +20 |
//  |  two matching       | Small  +2xbet|
//  |  no match           | -bet         |
//  +---------------------+--------------+
//
// ============================================================
//  LED effects
//  +------------+----------------------------------+
//  | FSM state  | Pattern led[15:0]                |
//  +------------+----------------------------------+
//  | IDLE       | every other LED, slow flicker    |
//  | SPIN       | running single bit               |
//  | WIN        | full LFSR fire + flame wave      |
//  | LOSE       | blinking checkerboard            |
//  | RESULT     | off (0x0000)                     |
//  +------------+----------------------------------+
