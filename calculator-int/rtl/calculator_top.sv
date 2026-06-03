`timescale 1ns / 1ps

module calculator_top (
    input  logic        clk,        // 100 MHz
    input  logic        btnC,       // center button = reset
    input  logic [15:0] sw,         // slide switches
    output logic [6:0]  seg,        // 7-seg segments (active low)
    output logic        dp,         // decimal point (active low)
    output logic [3:0]  an,         // 7-seg anodes (active low)
    output logic [15:0] led         // LEDs show binary result
);

    // -------------------------------------------------------
    // Switch mapping
    //   sw[3:0]   = operand A  (0-15)
    //   sw[7:4]   = operand B  (0-15)
    //   sw[15:14] = operation
    //       00 = ADD
    //       01 = SUB
    //       10 = MUL
    //       11 = DIV
    // -------------------------------------------------------

    logic [3:0]  a, b;
    logic [1:0]  op;
    logic        reset;
    logic signed [15:0] result;
    logic        neg_flag;

    assign a     = sw[3:0];
    assign b     = sw[7:4];
    assign op    = sw[15:14];
    assign reset = btnC;

    // ---------- ALU ----------
    always_comb begin
        neg_flag = 1'b0;
        case (op)
            2'b00:   result = a + b;                        // ADD  max 30
            2'b01: begin                                    // SUB  range -15..15
                result = signed'({1'b0, a}) - signed'({1'b0, b});
                if (result < 0) begin
                    neg_flag = 1'b1;
                    result   = -result;
                end
            end
            2'b10:   result = a * b;                        // MUL  max 225
            2'b11:   result = (b != 0) ? a / b : 16'd9999;  // DIV  (show 9999 on /0)
            default: result = '0;
        endcase
    end

    // Show unsigned magnitude on LEDs (active high)
    assign led = result[15:0];

    // ---------- BCD conversion (Double Dabble, 4 digits) ----------
    logic [3:0] bcd3, bcd2, bcd1, bcd0;   // thousands, hundreds, tens, ones

    always_comb begin
        automatic logic [31:0] scratch = '0;
        // load magnitude into lowest 16 bits
        scratch[15:0] = result[15:0];

        // 16 shifts
        for (int i = 0; i < 16; i++) begin
            // if any BCD digit >= 5, add 3
            if (scratch[31:28] >= 5) scratch[31:28] += 3;
            if (scratch[27:24] >= 5) scratch[27:24] += 3;
            if (scratch[23:20] >= 5) scratch[23:20] += 3;
            if (scratch[19:16] >= 5) scratch[19:16] += 3;
            scratch = scratch << 1;
        end
        bcd3 = scratch[31:28];
        bcd2 = scratch[27:24];
        bcd1 = scratch[23:20];
        bcd0 = scratch[19:16];
    end

    // ---------- 7-segment multiplexed display ----------
    logic [19:0] refresh_counter;  // ~1 kHz refresh from 100 MHz
    logic [1:0]  digit_sel;
    logic [3:0]  digit_val;
    logic        blank;            // blank leading zeros

    always_ff @(posedge clk or posedge reset)
        if (reset) refresh_counter <= '0;
        else       refresh_counter <= refresh_counter + 1;

    assign digit_sel = refresh_counter[19:18]; // cycles through 0-3

    always_comb begin
        blank = 1'b0;
        case (digit_sel)
            2'd0: begin  // rightmost digit (ones) - never blank
                digit_val = bcd0;
                an = 4'b1110;
            end
            2'd1: begin  // tens
                digit_val = bcd1;
                an = 4'b1101;
                if (bcd3 == 0 && bcd2 == 0 && bcd1 == 0) blank = 1'b1;
            end
            2'd2: begin  // hundreds
                digit_val = bcd2;
                an = 4'b1011;
                if (bcd3 == 0 && bcd2 == 0) blank = 1'b1;
            end
            2'd3: begin  // thousands - show minus sign if negative
                if (neg_flag) begin
                    digit_val = 4'd10;  // code for dash
                    an = 4'b0111;
                end else begin
                    digit_val = bcd3;
                    an = 4'b0111;
                    if (bcd3 == 0) blank = 1'b1;
                end
            end
            default: begin
                digit_val = '0;
                an = 4'b1111;
            end
        endcase
    end

    // segment decoder  (active low: 0 = on)
    //    ___
    //   |   |   segments: a(top) b(top-R) c(bot-R) d(bot)
    //   |___|             e(bot-L) f(top-L) g(mid)
    //   |   |
    //   |___|
    //
    logic [6:0] seg_pattern;

    always_comb begin
        if (blank) begin
            seg_pattern = 7'b111_1111; // all off
        end else begin
            case (digit_val)        //        gfe_dcba
                4'd0:  seg_pattern = 7'b100_0000;
                4'd1:  seg_pattern = 7'b111_1001;
                4'd2:  seg_pattern = 7'b010_0100;
                4'd3:  seg_pattern = 7'b011_0000;
                4'd4:  seg_pattern = 7'b001_1001;
                4'd5:  seg_pattern = 7'b001_0010;
                4'd6:  seg_pattern = 7'b000_0010;
                4'd7:  seg_pattern = 7'b111_1000;
                4'd8:  seg_pattern = 7'b000_0000;
                4'd9:  seg_pattern = 7'b001_0000;
                4'd10: seg_pattern = 7'b011_1111; // minus sign (seg g only)
                default: seg_pattern = 7'b111_1111;
            endcase
        end
    end

    assign seg = seg_pattern;
    assign dp  = 1'b1;  // decimal point off

endmodule
