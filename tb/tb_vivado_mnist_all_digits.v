// tb_vivado_mnist_all_digits.v -- QUANTA_2 Universal Multi-Digit Testbench (Digits 0-9)
// Can evaluate any individual digit (0-9) or iterate through all 10 digits consecutively.

`timescale 1ns/1ps
`default_nettype none

module tb_vivado_mnist_all_digits #(
    parameter TEST_DIGIT = 3,         // Default digit to evaluate (0..9)
    parameter ALL_DIGITS_MODE = 1     // 1: Run all 10 digits in sequence, 0: Run TEST_DIGIT only
);

    // DUT signals
    reg        clk;
    reg        rst_n;
    reg        start_i;
    reg  [7:0] pixel_i;
    wire        load_o;
    wire [9:0]  pixel_idx_o;
    wire        busy_o;
    wire        done_o;
    wire [3:0]  prediction_o;
    wire signed [31:0] logit0, logit1, logit2, logit3, logit4;
    wire signed [31:0] logit5, logit6, logit7, logit8, logit9;

    // DUT
    cnn_top dut (
        .clk          (clk),
        .rst_n        (rst_n),
        .start_i      (start_i),
        .pixel_i      (pixel_i),
        .load_o       (load_o),
        .pixel_idx_o  (pixel_idx_o),
        .busy_o       (busy_o),
        .done_o       (done_o),
        .prediction_o (prediction_o)
    );

    // Sample internal logits
    assign logit0 = dut.logits[0]; assign logit1 = dut.logits[1];
    assign logit2 = dut.logits[2]; assign logit3 = dut.logits[3];
    assign logit4 = dut.logits[4]; assign logit5 = dut.logits[5];
    assign logit6 = dut.logits[6]; assign logit7 = dut.logits[7];
    assign logit8 = dut.logits[8]; assign logit9 = dut.logits[9];

    // Clock: 10 ns period, 100 MHz
    initial clk = 1'b0;
    always #5 clk = ~clk;

    reg [7:0] img [0:783];
    integer d, j, timeout_cnt;
    integer pass_count;
    integer start_digit, end_digit;
    reg [255:0] mem_filename;

    // Watchdog
    initial begin
        #80000000; // 80 ms maximum for all digits
        $display("ERROR: WATCHDOG TIMEOUT.");
        $finish;
    end

    task run_single_digit(input integer digit_val);
        begin
            case (digit_val)
                0: mem_filename = "F:/QUANTA_2/test/image_input_0.mem";
                1: mem_filename = "F:/QUANTA_2/test/image_input_1.mem";
                2: mem_filename = "F:/QUANTA_2/test/image_input_2.mem";
                3: mem_filename = "F:/QUANTA_2/test/image_input_3.mem";
                4: mem_filename = "F:/QUANTA_2/test/image_input_4.mem";
                5: mem_filename = "F:/QUANTA_2/test/image_input_5.mem";
                6: mem_filename = "F:/QUANTA_2/test/image_input_6.mem";
                7: mem_filename = "F:/QUANTA_2/test/image_input_7.mem";
                8: mem_filename = "F:/QUANTA_2/test/image_input_8.mem";
                9: mem_filename = "F:/QUANTA_2/test/image_input_9.mem";
                default: mem_filename = "F:/QUANTA_2/test/image_input_0.mem";
            endcase

            $readmemh(mem_filename, img);

            // Synchronous reset cycle
            @(negedge clk);
            rst_n   = 1'b0;
            start_i = 1'b0;
            pixel_i = 8'h00;
            repeat(4) @(posedge clk);
            @(negedge clk);
            rst_n   = 1'b1;
            repeat(2) @(posedge clk);

            // Feed image pixels
            @(negedge clk);
            start_i = 1'b1;
            pixel_i = img[0];
            @(negedge clk);
            start_i = 1'b0;
            pixel_i = img[1];

            for (j = 2; j <= 783; j = j + 1) begin
                @(negedge clk);
                pixel_i = img[j];
            end

            // Wait for completion
            timeout_cnt = 0;
            @(posedge clk);
            while (done_o !== 1'b1 && timeout_cnt < 750000) begin
                @(posedge clk);
                timeout_cnt = timeout_cnt + 1;
            end

            if (timeout_cnt >= 750000) begin
                $display("  Digit %0d: FAILED -- Timeout waiting for done_o", digit_val);
            end else if (prediction_o == digit_val[3:0]) begin
                $display("  Digit %0d: PASS  -- Predicted: %0d  Cycles: %0d  Logit: %4d",
                         digit_val, prediction_o, timeout_cnt + 784, dut.logits[digit_val]);
                pass_count = pass_count + 1;
            end else begin
                $display("  Digit %0d: FAIL  -- Predicted: %0d (Expected: %0d)  Cycles: %0d",
                         digit_val, prediction_o, digit_val, timeout_cnt + 784);
            end

            repeat(5) @(posedge clk);
        end
    endtask

    initial begin
        clk        = 1'b0;
        rst_n      = 1'b0;
        start_i    = 1'b0;
        pixel_i    = 8'h00;
        pass_count = 0;

        $display("================================================================================");
        $display("QUANTA_2: Multi-Digit RTL Simulation Benchmark (Vivado / Icarus Verilog)");
        $display("================================================================================");

        if (ALL_DIGITS_MODE) begin
            start_digit = 0;
            end_digit   = 9;
            $display("Running full sequential test across all 10 digits (0 to 9)...");
        end else begin
            start_digit = TEST_DIGIT;
            end_digit   = TEST_DIGIT;
            $display("Running single digit test for Digit %0d...", TEST_DIGIT);
        end
        $display("--------------------------------------------------------------------------------");

        for (d = start_digit; d <= end_digit; d = d + 1) begin
            run_single_digit(d);
        end

        $display("--------------------------------------------------------------------------------");
        $display("Summary: %0d / %0d digits correctly classified.", pass_count, (end_digit - start_digit + 1));
        if (pass_count == (end_digit - start_digit + 1))
            $display("OVERALL RESULT: SUCCESS -- 100%% Accuracy across tested digits.");
        else
            $display("OVERALL RESULT: FAILED -- Mismatches detected.");
        $display("================================================================================");

        #100;
        $finish;
    end

endmodule
`default_nettype wire

