module blink_top (
    input  logic clk,
    output logic led
);
    logic [25:0] counter = 0;

    always_ff @(posedge clk)
        counter <= counter + 1;

    assign led = counter[25];

endmodule