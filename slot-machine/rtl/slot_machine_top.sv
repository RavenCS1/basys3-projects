// ============================================================
//  slot_machine_top.sv  –  slot machine (7-seg), top module
//  Używa osobnych modułów: debounce, seg7_ctrl
//  Basys3 Artix-7, clk 100 MHz
// ============================================================
module slot_machine_top (
    input  logic        clk,
    input  logic        btnC,
    input  logic        btnU,
    input  logic [1:0]  sw,
    output logic [6:0]  seg,
    output logic        dp,
    output logic [3:0]  an,
    output logic [15:0] led
);

// ── Stałe ────────────────────────────────────────────────────
localparam CLK_HZ = 100_000_000;

// ── Tik 1 ms ─────────────────────────────────────────────────
logic [16:0] ms_cnt;
logic        ms_tick;
always_ff @(posedge clk) begin
    if (btnU) begin ms_cnt <= '0; ms_tick <= 0; end
    else if (ms_cnt == 17'd99_999) begin ms_cnt <= '0; ms_tick <= 1; end
    else begin ms_cnt <= ms_cnt + 1; ms_tick <= 0; end
end

// ── Debounce ─────────────────────────────────────────────────
logic btn_clean, btn_pulse;
debounce #(.CLK_HZ(CLK_HZ), .DEBOUNCE_MS(10)) u_deb (
    .clk      (clk),
    .rst      (btnU),
    .btn_raw  (btnC),
    .btn_clean(btn_clean),
    .btn_pulse(btn_pulse)
);

// ── LFSR × 3 ─────────────────────────────────────────────────
logic [16:0] lfsr0, lfsr1, lfsr2;
always_ff @(posedge clk) begin
    if (btnU) begin
        lfsr0 <= 17'h1_ACE1;
        lfsr1 <= 17'h1_BEEF;
        lfsr2 <= 17'h1_CAFE;
    end else begin
        lfsr0 <= {lfsr0[15:0], lfsr0[16] ^ lfsr0[2]};
        lfsr1 <= {lfsr1[15:0], lfsr1[16] ^ lfsr1[4]};
        lfsr2 <= {lfsr2[15:0], lfsr2[16] ^ lfsr2[7]};
    end
end

function automatic logic [2:0] lfsr_sym (input logic [2:0] raw);
    return (raw > 3'd6) ? (raw - 3'd7) : raw;
endfunction

// ── FSM ──────────────────────────────────────────────────────
typedef enum logic [2:0] {
    S_IDLE   = 3'd0,
    S_SPIN   = 3'd1,
    S_RESULT = 3'd2,
    S_WIN    = 3'd3,
    S_LOSE   = 3'd4
} state_t;

state_t       state;
logic [31:0]  spin_ms;
logic [7:0]   score;
logic [1:0]   bet;
logic [2:0]   reel [0:2];
logic [2:0]   spin_sym [0:2];

always_ff @(posedge clk) begin
    if (btnU) begin
        state   <= S_IDLE;
        spin_ms <= '0;
        score   <= 8'd10;
        bet     <= 2'd1;
        for (int i=0; i<3; i++) reel[i] <= 3'd0;
    end else begin
        case (state)

        S_IDLE: begin
            bet <= (sw == 2'b00) ? 2'd1 : sw;
            if (btn_pulse && score >= {6'b0, bet}) begin
                score   <= score - {6'b0, bet};
                spin_ms <= '0;
                state   <= S_SPIN;
            end
        end

        S_SPIN: begin
            if (ms_tick) begin
                spin_ms <= spin_ms + 1;
                if (spin_ms == 32'd500)  reel[0] <= lfsr_sym(lfsr0[2:0]);
                if (spin_ms == 32'd1000) reel[1] <= lfsr_sym(lfsr1[2:0]);
                if (spin_ms == 32'd1500) begin
                    reel[2] <= lfsr_sym(lfsr2[2:0]);
                    state   <= S_RESULT;
                end
            end
        end

        S_RESULT: begin
            if (reel[0] == reel[1] && reel[1] == reel[2]) begin
                score <= score + ((reel[0] == 3'd1) ? 8'd50 : 8'd20);
                state <= S_WIN;
            end else if (reel[0]==reel[1] || reel[1]==reel[2] || reel[0]==reel[2]) begin
                score <= score + {5'b0, bet, 1'b0};
                state <= S_WIN;
            end else begin
                state <= S_LOSE;
            end
        end

        S_WIN, S_LOSE:
            if (btn_pulse) state <= S_IDLE;

        endcase
    end
end

// Symbole "w locie" podczas SPIN
always_comb begin
    for (int i=0; i<3; i++)
        spin_sym[i] = (state == S_SPIN)
                    ? lfsr_sym(lfsr0[2:0] ^ {3'(i), lfsr1[0]})
                    : reel[i];
end

// ── Fire LFSR + wzorce LED ────────────────────────────────────
logic [15:0] fire_lfsr;
logic [4:0]  fire_phase;

always_ff @(posedge clk) begin
    if (btnU) begin
        fire_lfsr  <= 16'hDEAD;
        fire_phase <= '0;
    end else if (ms_tick) begin
        fire_lfsr  <= {fire_lfsr[14:0], fire_lfsr[15]^fire_lfsr[13]^fire_lfsr[12]^fire_lfsr[10]};
        fire_phase <= fire_phase + 1;
    end
end

always_comb begin
    case (state)
    S_WIN:   led = fire_lfsr | (16'hFFFF << fire_phase[3:0]);
    S_IDLE:  led = {8'b0, fire_lfsr[7:0] & 8'h55};
    S_SPIN:  led = 16'h0001 << fire_phase[3:0];
    S_LOSE:  led = fire_phase[4] ? 16'hAAAA : 16'h5555;
    default: led = 16'h0000;
    endcase
end

// ── 7-seg ─────────────────────────────────────────────────────
seg7_ctrl #(.CLK_HZ(CLK_HZ)) u_seg (
    .clk       (clk),
    .rst       (btnU),
    .sym_in    (spin_sym),
    .score_in  (score),
    .state     (state),
    .fire_phase(fire_phase),
    .seg       (seg),
    .dp        (dp),
    .an        (an)
);

endmodule
