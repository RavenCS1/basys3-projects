// ============================================================
//  lcd_hd44780.sv  –  HD44780 character LCD driver (4-bit mode)
//
//  - Write-only (RW tied to GND in hardware)
//  - 4-bit interface (only D4..D7 wired)
//  - Continuously re-writes both lines, so dynamic content
//    (spinning reels, changing score) just shows up.
//  - Uses fixed conservative delays instead of reading the
//    busy flag (because RW is grounded).
//
//  Output mapping:
//    lcd_d[3] -> D7 , lcd_d[2] -> D6 , lcd_d[1] -> D5 , lcd_d[0] -> D4
//    lcd_rs   -> RS , lcd_e -> E
//    (RW is NOT a port — wire LCD pin 5 directly to GND)
// ============================================================
module lcd_hd44780 #(
    parameter int CLK_HZ = 100_000_000,
    parameter int COLS   = 16
)(
    input  logic              clk,
    input  logic              rst,
    input  logic [7:0]        line1 [0:COLS-1],
    input  logic [7:0]        line2 [0:COLS-1],
    output logic              lcd_rs,
    output logic              lcd_e,
    output logic [3:0]        lcd_d
);

    // ---- timing (clock cycles) --------------------------------
    localparam int C_US  = CLK_HZ / 1_000_000;          // 1 us
    localparam int T_PWR = 50 * (CLK_HZ / 1000);        // 50 ms power-on
    localparam int T_5MS = 5  * (CLK_HZ / 1000);        // >4.1 ms
    localparam int T_2MS = 2  * (CLK_HZ / 1000);        // >1.52 ms (clear/home)
    localparam int T_200U= 200 * C_US;                  // >100 us
    localparam int T_60U = 60  * C_US;                  // normal command exec
    localparam int T_PUL = (C_US < 1) ? 1 : C_US;       // ~1 us E pulse phase

    // ---- low-level nibble/byte transfer engine ----------------
    typedef enum logic [2:0] {
        T_IDLE, T_SETUP, T_EHIGH, T_ELOW, T_HOLD, T_DONE
    } tstate_t;
    tstate_t     tstate;

    logic        t_start;                 // pulse: begin a transfer
    logic [7:0]  t_byte;                  // byte to send (combinational from main)
    logic        t_rs;                    // RS for this transfer
    logic        t_nib;                   // 1 = send high nibble only
    logic [31:0] t_delay;                 // post-transfer wait (cycles)

    logic        t_busy;
    logic        t_done;
    assign t_busy = (tstate != T_IDLE);
    assign t_done = (tstate == T_DONE);

    logic [7:0]  cur_byte;
    logic        cur_rs;
    logic        cur_nib;
    logic [31:0] cur_delay;
    logic        phase;                   // 0 = high nibble, 1 = low nibble
    logic [31:0] tcnt;

    always_ff @(posedge clk) begin
        if (rst) begin
            tstate <= T_IDLE;
            lcd_e  <= 1'b0;
            lcd_rs <= 1'b0;
            lcd_d  <= 4'h0;
            phase  <= 1'b0;
            tcnt   <= '0;
        end else begin
            case (tstate)
            T_IDLE: begin
                lcd_e <= 1'b0;
                if (t_start) begin
                    cur_byte  <= t_byte;
                    cur_rs    <= t_rs;
                    cur_nib   <= t_nib;
                    cur_delay <= t_delay;
                    phase     <= 1'b0;
                    tcnt      <= '0;
                    tstate    <= T_SETUP;
                end
            end
            T_SETUP: begin                 // present data, E low
                lcd_e  <= 1'b0;
                lcd_rs <= cur_rs;
                lcd_d  <= (phase == 1'b0) ? cur_byte[7:4] : cur_byte[3:0];
                if (tcnt == T_PUL-1) begin tcnt <= '0; tstate <= T_EHIGH; end
                else tcnt <= tcnt + 1;
            end
            T_EHIGH: begin                 // E high
                lcd_e <= 1'b1;
                if (tcnt == T_PUL-1) begin tcnt <= '0; tstate <= T_ELOW; end
                else tcnt <= tcnt + 1;
            end
            T_ELOW: begin                  // E low (data latched on this edge)
                lcd_e <= 1'b0;
                if (tcnt == T_PUL-1) begin
                    tcnt <= '0;
                    if (phase == 1'b0 && !cur_nib) begin
                        phase  <= 1'b1;     // go send low nibble
                        tstate <= T_SETUP;
                    end else begin
                        tstate <= T_HOLD;   // done sending; wait exec time
                    end
                end else tcnt <= tcnt + 1;
            end
            T_HOLD: begin                  // wait command execution time
                lcd_e <= 1'b0;
                if (tcnt == cur_delay-1) begin tcnt <= '0; tstate <= T_DONE; end
                else tcnt <= tcnt + 1;
            end
            T_DONE: begin
                tstate <= T_IDLE;
            end
            default: tstate <= T_IDLE;
            endcase
        end
    end

    // ---- main sequencer ---------------------------------------
    typedef enum logic [2:0] {
        M_PWR, M_INIT, M_A1, M_D1, M_A2, M_D2
    } mstate_t;
    mstate_t      mstate;

    localparam int N_INIT = 9;
    logic [3:0]   pc;                      // init program counter
    logic [7:0]   col;                     // column index 0..COLS-1
    logic         launched;                // start pulse already issued?
    logic [31:0]  pwr_cnt;

    // init program: byte + nibble-only flag + delay
    function automatic void init_entry(
        input  logic [3:0] i,
        output logic [7:0] b,
        output logic       nib,
        output logic [31:0] dly
    );
        case (i)
        4'd0: begin b = 8'h30; nib = 1; dly = T_5MS;  end // wake 1
        4'd1: begin b = 8'h30; nib = 1; dly = T_200U; end // wake 2
        4'd2: begin b = 8'h30; nib = 1; dly = T_200U; end // wake 3
        4'd3: begin b = 8'h20; nib = 1; dly = T_200U; end // set 4-bit
        4'd4: begin b = 8'h28; nib = 0; dly = T_60U;  end // 4-bit, 2 line, 5x8
        4'd5: begin b = 8'h08; nib = 0; dly = T_60U;  end // display off
        4'd6: begin b = 8'h01; nib = 0; dly = T_2MS;  end // clear
        4'd7: begin b = 8'h06; nib = 0; dly = T_60U;  end // entry mode ++
        4'd8: begin b = 8'h0C; nib = 0; dly = T_60U;  end // display on, no cursor
        default: begin b = 8'h00; nib = 0; dly = T_60U; end
        endcase
    endfunction

    // combinational transfer parameters (held stable per state)
    always_comb begin
        logic [7:0]  ib; logic in; logic [31:0] idl;
        t_byte = 8'h00; t_rs = 1'b0; t_nib = 1'b0; t_delay = T_60U;
        unique case (mstate)
        M_INIT: begin init_entry(pc, ib, in, idl);
                      t_byte = ib; t_nib = in; t_delay = idl; t_rs = 1'b0; end
        M_A1:   begin t_byte = 8'h80; t_rs = 1'b0; t_delay = T_60U; end // DDRAM 0x00
        M_D1:   begin t_byte = line1[col]; t_rs = 1'b1; t_delay = T_60U; end
        M_A2:   begin t_byte = 8'hC0; t_rs = 1'b0; t_delay = T_60U; end // DDRAM 0x40
        M_D2:   begin t_byte = line2[col]; t_rs = 1'b1; t_delay = T_60U; end
        default:begin t_byte = 8'h00; t_rs = 1'b0; t_delay = T_60U; end
        endcase
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            mstate   <= M_PWR;
            pc       <= '0;
            col      <= '0;
            launched <= 1'b0;
            t_start  <= 1'b0;
            pwr_cnt  <= '0;
        end else begin
            t_start <= 1'b0;               // default: not starting
            case (mstate)
            M_PWR: begin
                if (pwr_cnt == T_PWR-1) mstate <= M_INIT;
                else pwr_cnt <= pwr_cnt + 1;
            end
            M_INIT: begin
                if (!launched && !t_busy) begin t_start <= 1'b1; launched <= 1'b1; end
                else if (t_done) begin
                    launched <= 1'b0;
                    if (pc == N_INIT-1) begin pc <= '0; mstate <= M_A1; end
                    else pc <= pc + 1;
                end
            end
            M_A1: begin
                if (!launched && !t_busy) begin t_start <= 1'b1; launched <= 1'b1; end
                else if (t_done) begin launched <= 1'b0; col <= '0; mstate <= M_D1; end
            end
            M_D1: begin
                if (!launched && !t_busy) begin t_start <= 1'b1; launched <= 1'b1; end
                else if (t_done) begin
                    launched <= 1'b0;
                    if (col == COLS-1) mstate <= M_A2;
                    else col <= col + 1;
                end
            end
            M_A2: begin
                if (!launched && !t_busy) begin t_start <= 1'b1; launched <= 1'b1; end
                else if (t_done) begin launched <= 1'b0; col <= '0; mstate <= M_D2; end
            end
            M_D2: begin
                if (!launched && !t_busy) begin t_start <= 1'b1; launched <= 1'b1; end
                else if (t_done) begin
                    launched <= 1'b0;
                    if (col == COLS-1) mstate <= M_A1;   // loop forever
                    else col <= col + 1;
                end
            end
            default: mstate <= M_PWR;
            endcase
        end
    end

endmodule