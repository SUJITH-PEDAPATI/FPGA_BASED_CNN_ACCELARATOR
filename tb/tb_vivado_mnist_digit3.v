// tb_vivado_mnist_digit3.v -- QUANTA_2 Vivado behavioral simulation testbench
// Benchmarks MNIST sample index 18 (ground-truth label = 3)
// Image file: test/image_input_3.mem
// Label file: test/image_label_3.txt

`timescale 1ns/1ps
`default_nettype none

module tb_vivado_mnist_digit3;

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

    // Sample internal logits hierarchically
    assign logit0 = dut.logits[0];
    assign logit1 = dut.logits[1];
    assign logit2 = dut.logits[2];
    assign logit3 = dut.logits[3];
    assign logit4 = dut.logits[4];
    assign logit5 = dut.logits[5];
    assign logit6 = dut.logits[6];
    assign logit7 = dut.logits[7];
    assign logit8 = dut.logits[8];
    assign logit9 = dut.logits[9];

    // Clock: 10 ns period, 100 MHz
    initial clk = 1'b0;
    always #5 clk = ~clk;

    // Image buffer
    reg [7:0] img [0:783];

    // Ground truth for test/image_input_3.mem (MNIST index=18, label=3)
    localparam GT_INDEX = 18;
    localparam GT_LABEL = 4'd3;

    // Expected RTL logits from integer RTL reference emulator
    localparam signed [31:0]
        EXP_L0 = -32'sd41, EXP_L1 = -32'sd74, EXP_L2 = -32'sd8,
        EXP_L3 =  32'sd3,  EXP_L4 = -32'sd63, EXP_L5 = -32'sd18,
        EXP_L6 = -32'sd46, EXP_L7 = -32'sd59, EXP_L8 = -32'sd4, EXP_L9 = -32'sd36;

    integer j, timeout_cnt;

    // Watchdog: 7,500,000 ns = 750,000 cycles
    initial begin
        #7500000;
        $display("ERROR: WATCHDOG -- CNN did not complete in 7500 us.");
        $finish;
    end

    initial begin
        clk      = 1'b0;
        rst_n    = 1'b0;
        start_i  = 1'b0;
        pixel_i  = 8'h00;

        $display("=== QUANTA_2 Vivado Behavioral Simulation (Digit 3) ===");
        $display("    Testbench: tb_vivado_mnist_digit3.v");
        $display("    Image:     test/image_input_3.mem  (MNIST index=%0d, label=%0d)", GT_INDEX, GT_LABEL);
        $display("");

        $readmemh("F:/QUANTA_2/test/image_input_3.mem", img);
        $display("Image loaded. img[0]=0x%02h  img[100]=0x%02h  img[400]=0x%02h",
            img[0], img[100], img[400]);

        repeat(6) @(posedge clk);
        rst_n = 1'b1;
        $display("Reset released at %0t ns.", $time);
        repeat(4) @(posedge clk);

        $display("Starting inference at %0t ns...", $time);
        @(negedge clk); start_i = 1'b1; pixel_i = img[0];
        @(negedge clk); start_i = 1'b0; pixel_i = img[1];
        for (j = 2; j <= 783; j = j + 1) begin
            @(negedge clk);
            pixel_i = img[j];
        end
        $display("All 784 pixels fed. Waiting for done_o...");

        timeout_cnt = 0;
        @(posedge clk);
        while (done_o !== 1'b1 && timeout_cnt < 750000) begin
            @(posedge clk);
            timeout_cnt = timeout_cnt + 1;
        end
        @(posedge clk);

        if (timeout_cnt >= 750000) begin
            $display("ERROR: done_o never asserted after 750000 cycles.");
            $finish;
        end

        $display("");
        $display("=== Inference complete at %0t ns ===", $time);
        $display("    Clock cycles after pixel feed: %0d", timeout_cnt);
        $display("    Total clock cycles (end-to-end): %0d", timeout_cnt + 784);
        $display("");
        $display("=== RTL Output Logits ===");
        $display("  logit[0] = %4d  (digit 0)", logit0);
        $display("  logit[1] = %4d  (digit 1)", logit1);
        $display("  logit[2] = %4d  (digit 2)", logit2);
        $display("  logit[3] = %4d  (digit 3)  <-- argmax", logit3);
        $display("  logit[4] = %4d  (digit 4)", logit4);
        $display("  logit[5] = %4d  (digit 5)", logit5);
        $display("  logit[6] = %4d  (digit 6)", logit6);
        $display("  logit[7] = %4d  (digit 7)", logit7);
        $display("  logit[8] = %4d  (digit 8)", logit8);
        $display("  logit[9] = %4d  (digit 9)", logit9);
        $display("");
        $display("RTL predicted digit : %0d", prediction_o);
        $display("Ground truth label  : %0d", GT_LABEL);
        $display("");
        if (prediction_o === GT_LABEL)
            $display("RESULT: CORRECT  -- prediction matches ground truth label %0d", GT_LABEL);
        else
            $display("RESULT: INCORRECT -- RTL=%0d  expected=%0d", prediction_o, GT_LABEL);

        $display("");
        $display("=== Bit-Exact Comparison vs Python RTL Emulator ===");
        $display("  Expected: [-41, -74, -8, 3, -63, -18, -46, -59, -4, -36]");

        if (logit0===EXP_L0 && logit1===EXP_L1 && logit2===EXP_L2 &&
            logit3===EXP_L3 && logit4===EXP_L4 && logit5===EXP_L5 &&
            logit6===EXP_L6 && logit7===EXP_L7 && logit8===EXP_L8 &&
            logit9===EXP_L9)
            $display("EMULATOR CHECK: ALL 10 LOGITS MATCH -- bit-exact agreement confirmed.");
        else
            $display("EMULATOR CHECK: MISMATCH detected!");

        #100;
        $finish;
    end

endmodule
`default_nettype wire

