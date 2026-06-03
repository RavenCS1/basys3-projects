// ============================================================
//  seg7_ctrl.sv  --  7-segment display driver (Basys3)
//  4-digit time-multiplexed driver for the slot machine.
//
//  Digit layout (left to right):
//    an[3] = reel 0    an[2] = reel 1
//    an[1] = reel 2    an[0] = score (units digit)
//
//  sym_in[i]   -- reel i symbol (0-6)
//  score_in    -- current score (0-99)
//  state       -- current FSM state (controls decimal-point animation)
//  fire_phase  -- fire animation phase (used to blink decimal points on WIN)
// ============================================================
module seg7_ctrl #(
    parameter CLK_HZ = 100_000_000
)(
    input  logic        clk,
    input  logic        rst,
    input  logic [2:0]  sym_in [0:2],   // reels 0, 1, 2
    input  logic [7:0]  score_in,       // score (bits 7:0)
    input  logic [2:0]  state,          // FSM state
    input  logic [4:0]  fire_phase,     // fire animation phase (decimal point)
    output logic [6:0]  seg,
    output logic        dp,
    output logic [3:0]  an
);

// Refresh at ~763 Hz (4 digits × ~191 Hz each)
localparam REFRESH_DIV = CLK_HZ / 763;
logic [$clog2(REFRESH_DIV)-1:0] ref_cnt;
logic [1:0] digit_sel;

always_ff @(posedge clk) begin
    if (rst) begin
        ref_cnt   <= '0;
        digit_sel <= '0;
    end else begin
        if (ref_cnt == REFRESH_DIV - 1) begin
            ref_cnt   <= '0;
            digit_sel <= digit_sel + 1;
        end else begin
            ref_cnt <= ref_cnt + 1;
        end
    end
end

// Reel symbol encoder
// Segments: gfedcba (bit 6 = g, bit 0 = a), active low
// Symbols: 0=BAR(b)  1=Seven(7)  2=Three(3)  3=Cherry(C)
//          4=Bell(b)  5=Horse(H)  6=Lemon(L)
function automatic logic [6:0] sym_to_seg (input logic [2:0] s);
    case (s)
    3'd0: return 7'b000_0011;  // b  - BAR
    3'd1: return 7'b111_1000;  // 7  - Seven
    3'd2: return 7'b011_0000;  // 3  - Three
    3'd3: return 7'b100_0110;  // C  - Cherry
    3'd4: return 7'b000_0011;  // b  - Bell
    3'd5: return 7'b000_1001;  // H  - Horse
    3'd6: return 7'b100_0111;  // L  - Lemon
    default: return 7'b111_1111;
    endcase
endfunction

// Decimal digit encoder (0-9), active low
function automatic logic [6:0] num_to_seg (input logic [3:0] n);
    case (n)
    4'd0: return 7'b100_0000;
    4'd1: return 7'b111_1001;
    4'd2: return 7'b010_0100;
    4'd3: return 7'b011_0000;
    4'd4: return 7'b001_1001;
    4'd5: return 7'b001_0010;
    4'd6: return 7'b000_0010;
    4'd7: return 7'b111_1000;
    4'd8: return 7'b000_0000;
    4'd9: return 7'b001_0000;
    default: return 7'b111_1111;
    endcase
endfunction

// BCD decoder for score (tens and units, max 99)
logic [3:0] score_tens, score_units;
assign score_tens  = (score_in >= 8'd90) ? 4'd9 :
                     (score_in >= 8'd80) ? 4'd8 :
                     (score_in >= 8'd70) ? 4'd7 :
                     (score_in >= 8'd60) ? 4'd6 :
                     (score_in >= 8'd50) ? 4'd5 :
                     (score_in >= 8'd40) ? 4'd4 :
                     (score_in >= 8'd30) ? 4'd3 :
                     (score_in >= 8'd20) ? 4'd2 :
                     (score_in >= 8'd10) ? 4'd1 : 4'd0;
assign score_units = score_in - (score_tens * 4'd10);

// FSM state codes (must match top module)
localparam S_IDLE=3'd0, S_SPIN=3'd1, S_RESULT=3'd2, S_WIN=3'd3, S_LOSE=3'd4;

// Digit multiplexer
always_comb begin
    an      = 4'b1111;
    seg     = 7'b111_1111;
    dp      = 1'b1;

    case (digit_sel)
    2'd3: begin  // left reel
        an  = 4'b0111;
        seg = sym_to_seg(sym_in[0]);
        dp  = (state == S_WIN) ? ~fire_phase[2] : 1'b1;
    end
    2'd2: begin  // centre reel
        an  = 4'b1011;
        seg = sym_to_seg(sym_in[1]);
        dp  = (state == S_WIN) ? ~fire_phase[1] : 1'b1;
    end
    2'd1: begin  // right reel
        an  = 4'b1101;
        seg = sym_to_seg(sym_in[2]);
        dp  = (state == S_WIN) ? ~fire_phase[0] : 1'b1;
    end
    2'd0: begin  // score units digit
        an  = 4'b1110;
        seg = (score_tens > 0) ? num_to_seg(score_units)
                               : num_to_seg(score_in[3:0]);
        dp  = 1'b1;
    end
    endcase
end

endmodule
