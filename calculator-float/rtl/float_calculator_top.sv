`timescale 1ns / 1ps

// ============================================================
//  7-bit Mini-Float Calculator - Basys3 / Artix-7
// ============================================================
//  Float format (7 bits):  [sign(1)] [exponent(3)] [mantissa(3)]
//    Bias = 3
//    Normal  (1≤e≤6):  (-1)^s × (1 + m/8) × 2^(e-3)
//    Denorm  (e=0):    (-1)^s × (m/8) × 2^(-2)
//    Inf/NaN (e=7):    shows "----"
//
//  Switch mapping:
//    sw[6:0]   = operand A   (7-bit float)
//    sw[13:7]  = operand B   (7-bit float)
//    sw[15:14] = operation    00=+ 01=- 10=× 11=÷
//
//  Result shown on 7-segment display with 1 decimal place.
//  LEDs show raw fixed-point result in binary.
//  Center button = reset.
// ============================================================

module float_calculator_top (
    input  logic        clk,        // 100 MHz
    input  logic        btnC,       // reset
    input  logic [15:0] sw,
    output logic [6:0]  seg,        // 7-seg segments (active low)
    output logic        dp,         // decimal point  (active low)
    output logic [3:0]  an,         // 7-seg anodes   (active low)
    output logic [15:0] led
);

    // ===================== input mapping =====================
    logic [6:0] fa, fb;
    logic [1:0] op;
    logic       reset;

    assign fa    = sw[6:0];
    assign fb    = sw[13:7];
    assign op    = sw[15:14];
    assign reset = btnC;

    // ========== float-7 → signed fixed-point Q9.8 ============
    //  18-bit signed: 1 sign + 9 integer + 8 fraction
    //  range ±255.996, resolution 1/256 ≈ 0.004

    function automatic logic signed [17:0] f7_to_fix (input logic [6:0] f);
        logic [2:0]  e, m;
        logic [15:0] mag;
        e = f[5:3];
        m = f[2:0];

        if (e == 0 && m == 0)
            mag = 16'd0;                              // zero
        else if (e == 0)
            mag = {13'd0, m} << 3;                    // denorm: m×2^(-5) in Q8.8
        else if (e == 3'd7)
            mag = 16'hFF00;                           // inf / NaN marker
        else
            mag = ({12'd0, 1'b1, m}) << (e + 2);     // normal: (8+m)×2^(e-6) in Q8.8

        if (f[6])
            return -$signed({2'b00, mag});
        else
            return  $signed({2'b00, mag});
    endfunction

    logic signed [17:0] fix_a, fix_b;
    assign fix_a = f7_to_fix(fa);
    assign fix_b = f7_to_fix(fb);

    // ======================== ALU ============================
    logic signed [35:0] mul_wide;       // Q18.16 product
    logic signed [35:0] div_num;        // dividend shifted for precision
    logic signed [35:0] div_b_ext;      // sign-extended divisor
    logic signed [17:0] result;         // Q9.8
    logic               div_zero;
    logic               is_special;     // inf/NaN on an input

    assign mul_wide  = fix_a * fix_b;
    assign div_num   = fix_a * 18'sd256;                    // fix_a << 8
    assign div_b_ext = {{18{fix_b[17]}}, fix_b};            // sign-extend to 36 b
    assign is_special = (fa[5:3] == 3'd7) || (fb[5:3] == 3'd7);

    always_comb begin
        div_zero = 1'b0;
        if (is_special) begin
            result = 18'sh1FFFF;                            // flag → display "----"
        end else begin
            case (op)
                2'b00:   result = fix_a + fix_b;            // ADD
                2'b01:   result = fix_a - fix_b;            // SUB
                2'b10:   result = mul_wide[25:8];           // MUL  Q18.16 >> 8 → Q9.8
                2'b11: begin                                // DIV
                    if (fix_b == 0) begin
                        result   = 18'sh1FFFF;
                        div_zero = 1'b1;
                    end else
                        result = 18'(div_num / div_b_ext);
                end
                default: result = '0;
            endcase
        end
    end

    assign led = result[15:0];

    // =============== magnitude / sign ========================
    logic        neg;
    logic [17:0] abs_val;

    always_comb begin
        if (result < 0) begin
            neg     = 1'b1;
            abs_val = 18'(-result);
        end else begin
            neg     = 1'b0;
            abs_val = result[17:0];
        end
    end

    // ====== multiply by 10 → integer for 1-decimal display ===
    //  abs_val is Q9.8.  (abs_val × 10) >> 8  = value×10 as integer
    logic [27:0] x10_full;
    logic [15:0] val_x10;           // max 225×10 = 2250

    assign x10_full = abs_val * 18'd10;
    assign val_x10  = x10_full[23:8];

    // =============== BCD (double-dabble) =====================
    logic [3:0] bcd3, bcd2, bcd1, bcd0;

    always_comb begin
        automatic logic [31:0] s = '0;
        s[15:0] = val_x10;
        for (int i = 0; i < 16; i++) begin
            if (s[31:28] >= 5) s[31:28] += 3;
            if (s[27:24] >= 5) s[27:24] += 3;
            if (s[23:20] >= 5) s[23:20] += 3;
            if (s[19:16] >= 5) s[19:16] += 3;
            s = s << 1;
        end
        bcd3 = s[31:28];       // hundreds (or minus)
        bcd2 = s[27:24];       // tens
        bcd1 = s[23:20];       // ones     ← decimal point here
        bcd0 = s[19:16];       // tenths
    end

    // === BCD for integer-only (large negatives ≥ 100) ========
    logic [15:0] int_val;
    logic [3:0]  ibcd2, ibcd1, ibcd0;

    assign int_val = val_x10 / 10;

    always_comb begin
        automatic logic [31:0] s2 = '0;
        s2[15:0] = int_val;
        for (int i = 0; i < 16; i++) begin
            if (s2[31:28] >= 5) s2[31:28] += 3;
            if (s2[27:24] >= 5) s2[27:24] += 3;
            if (s2[23:20] >= 5) s2[23:20] += 3;
            if (s2[19:16] >= 5) s2[19:16] += 3;
            s2 = s2 << 1;
        end
        ibcd2 = s2[27:24];
        ibcd1 = s2[23:20];
        ibcd0 = s2[19:16];
    end

    // =========== 7-segment multiplexed driver ================
    logic [19:0] refresh_cnt;
    logic [1:0]  digit_sel;
    logic [3:0]  digit_val;
    logic        blank;
    logic        show_dp;           // 1 = light the decimal point

    always_ff @(posedge clk or posedge reset)
        if (reset) refresh_cnt <= '0;
        else       refresh_cnt <= refresh_cnt + 1;

    assign digit_sel = refresh_cnt[19:18];

    logic neg_large;                // negative AND |val| >= 100
    assign neg_large = neg && (val_x10 >= 16'd1000);

    logic show_dashes;
    assign show_dashes = is_special || (div_zero);

    always_comb begin
        blank   = 1'b0;
        show_dp = 1'b0;
        an      = 4'b1111;         // default all off
        digit_val = 4'd0;

        if (show_dashes) begin
            // ---- (inf / NaN / div-by-zero)
            digit_val = 4'd10;     // dash character
            case (digit_sel)
                2'd0: an = 4'b1110;
                2'd1: an = 4'b1101;
                2'd2: an = 4'b1011;
                2'd3: an = 4'b0111;
                default: ;
            endcase

        end else if (neg_large) begin
            // negative ≥ 100 → show "-XXX" (integer, no decimal)
            case (digit_sel)
                2'd0: begin an = 4'b1110; digit_val = ibcd0; end
                2'd1: begin an = 4'b1101; digit_val = ibcd1;
                       if (ibcd2 == 0 && ibcd1 == 0) blank = 1; end
                2'd2: begin an = 4'b1011; digit_val = ibcd2;
                       if (ibcd2 == 0) blank = 1; end
                2'd3: begin an = 4'b0111; digit_val = 4'd10; end   // minus
                default: ;
            endcase

        end else if (neg) begin
            // negative < 100 → show "-XX.X"
            case (digit_sel)
                2'd0: begin an = 4'b1110; digit_val = bcd0; end              // tenths
                2'd1: begin an = 4'b1101; digit_val = bcd1; show_dp = 1; end // ones + dp
                2'd2: begin an = 4'b1011; digit_val = bcd2;
                       if (bcd2 == 0) blank = 1; end                         // tens
                2'd3: begin an = 4'b0111; digit_val = 4'd10; end             // minus
                default: ;
            endcase

        end else begin
            // positive → show "XXX.X"
            case (digit_sel)
                2'd0: begin an = 4'b1110; digit_val = bcd0; end              // tenths
                2'd1: begin an = 4'b1101; digit_val = bcd1; show_dp = 1; end // ones + dp
                2'd2: begin an = 4'b1011; digit_val = bcd2;
                       if (bcd3 == 0 && bcd2 == 0) blank = 1; end            // tens
                2'd3: begin an = 4'b0111; digit_val = bcd3;
                       if (bcd3 == 0) blank = 1; end                         // hundreds
                default: ;
            endcase
        end
    end

    // ============= segment decoder (active low) ==============
    logic [6:0] seg_pat;

    always_comb begin
        if (blank)
            seg_pat = 7'b111_1111;
        else case (digit_val)        //     gfe_dcba
            4'd0:    seg_pat = 7'b100_0000;
            4'd1:    seg_pat = 7'b111_1001;
            4'd2:    seg_pat = 7'b010_0100;
            4'd3:    seg_pat = 7'b011_0000;
            4'd4:    seg_pat = 7'b001_1001;
            4'd5:    seg_pat = 7'b001_0010;
            4'd6:    seg_pat = 7'b000_0010;
            4'd7:    seg_pat = 7'b111_1000;
            4'd8:    seg_pat = 7'b000_0000;
            4'd9:    seg_pat = 7'b001_0000;
            4'd10:   seg_pat = 7'b011_1111;   // minus sign
            default: seg_pat = 7'b111_1111;
        endcase
    end

    assign seg = seg_pat;
    assign dp  = show_dp ? 1'b0 : 1'b1;     // active low

endmodule