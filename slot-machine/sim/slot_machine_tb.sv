// ============================================================
//  slot_machine_tb.sv  --  testbench for slot_machine_top_v2
//  Simulation: reset, several spins, verify outputs.
// ============================================================
`timescale 1ns/1ps

module slot_machine_tb;

// DUT ports
logic        clk, btnC, btnU;
logic [1:0]  sw;
logic [6:0]  seg;
logic        dp;
logic [3:0]  an;
logic [15:0] led;

// DUT instance
slot_machine_top_v2 dut (.*);

// 100 MHz clock (10 ns period)
initial clk = 0;
always #5 clk = ~clk;

// Task: press and release a button
task press_btn (ref logic btn, input int hold_us);
    btn = 1;
    #(hold_us * 1000);
    btn = 0;
endtask

// Task: wait N milliseconds
task wait_ms (input int ms);
    #(ms * 1_000_000);
endtask

// Main test scenario
integer spin_count;

initial begin
    $dumpfile("slot_machine.vcd");
    $dumpvars(0, slot_machine_tb);

    // Initialise
    btnC = 0; btnU = 0; sw = 2'b01;

    // Reset
    $display("[TB] === RESET ===");
    btnU = 1; wait_ms(5); btnU = 0;
    wait_ms(5);

    // Spin 1
    $display("[TB] === SPIN 1 (bet=1) ===");
    sw = 2'b01;
    press_btn(btnC, 20_000);  // 20 ms (above the 10 ms debounce threshold)
    wait_ms(2000);            // wait for spin to complete

    $display("[TB] LED after spin 1: %04h", led);
    $display("[TB] AN=%b SEG=%b", an, seg);

    // Press to continue (exit WIN/LOSE state)
    press_btn(btnC, 20_000);
    wait_ms(50);

    // Spin 2
    $display("[TB] === SPIN 2 (bet=3) ===");
    sw = 2'b11;
    press_btn(btnC, 20_000);
    wait_ms(2000);

    $display("[TB] LED after spin 2: %04h", led);

    press_btn(btnC, 20_000);
    wait_ms(50);

    // Spin 3
    $display("[TB] === SPIN 3 ===");
    sw = 2'b10;
    press_btn(btnC, 20_000);
    wait_ms(2000);

    $display("[TB] LED after spin 3: %04h", led);

    press_btn(btnC, 20_000);
    wait_ms(50);

    // Quick reset test (reset mid-spin)
    $display("[TB] === Quick reset test ===");
    press_btn(btnC, 20_000);   // spin
    wait_ms(500);              // mid-spin
    btnU = 1; wait_ms(2); btnU = 0;  // reset mid-spin
    wait_ms(100);
    $display("[TB] State after reset: LED=%04h", led);

    $display("[TB] === End of simulation ===");
    $finish;
end

// Monitor AN changes
always @(an) begin
    case (an)
    4'b1110: $display("[TB] Digit 0 (score)  SEG=%b", seg);
    4'b1101: $display("[TB] Digit 1 (reel 3) SEG=%b", seg);
    4'b1011: $display("[TB] Digit 2 (reel 2) SEG=%b", seg);
    4'b0111: $display("[TB] Digit 3 (reel 1) SEG=%b", seg);
    endcase
end

// Simulation timeout guard (100 s)
initial begin
    #100_000_000_000;
    $display("[TB] TIMEOUT!");
    $finish;
end

endmodule
