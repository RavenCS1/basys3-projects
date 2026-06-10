// ============================================================
//  Debounce – filtr drgań styków
//  Aktywny przy zboczu narastającym (LOW→HIGH)
//  Generuje jednotaktowy impuls btn_pulse po stabilizacji
// ============================================================
module debounce #(
    parameter CLK_HZ   = 100_000_000,
    parameter DEBOUNCE_MS = 10
)(
    input  logic clk,
    input  logic rst,
    input  logic btn_raw,
    output logic btn_clean,
    output logic btn_pulse   // jednotaktowy impuls
);

localparam THRESHOLD = CLK_HZ / 1000 * DEBOUNCE_MS;

logic [$clog2(THRESHOLD)-1:0] cnt;
logic prev;

always_ff @(posedge clk) begin
    if (rst) begin
        cnt       <= '0;
        prev      <= 0;
        btn_clean <= 0;
        btn_pulse <= 0;
    end else begin
        btn_pulse <= 0;
        if (btn_raw == prev) begin
            cnt <= '0;
        end else begin
            cnt <= cnt + 1;
            if (cnt == THRESHOLD - 1) begin
                prev      <= btn_raw;
                btn_clean <= btn_raw;
                btn_pulse <= btn_raw;   // impuls tylko przy zboczu narastającym
                cnt       <= '0;
            end
        end
    end
end

endmodule