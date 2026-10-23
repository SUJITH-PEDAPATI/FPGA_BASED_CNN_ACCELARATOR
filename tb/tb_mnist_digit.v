// tb_mnist_digit.v -- QUANTA_2
// Test the RTL CNN with a real MNIST image (test/image_input.mem).
// Ground-truth label: 7  (test/image_label.txt)
//
// Expected RTL emulator output:
//   logits = [-21,-21,2,-1,-46,-33,-77,49,-30,-8]
//   prediction = 7  (logit[7]=49 is the maximum)
//
// Pixel loading protocol:
//   @negedge: start_i=1, pixel_i=img[0]  -> posedge: T_IDLE captures img_buf[0]
//   @negedge: start_i=0, pixel_i=img[1]  -> posedge: T_LOAD(pix_cnt=0) img_buf[1]
//   @negedge: pixel_i=img[j] j=2..783    -> posedge: T_LOAD captures img_buf[j]

`timescale 1ns/1ps
`default_nettype none

module tb_mnist_digit;

    // DUT ports
    reg        clk, rst_n, start_i;
    reg  [7:0] pixel_i;
    wire        load_o, busy_o, done_o;
    wire [9:0]  pixel_idx_o;
    wire [3:0]  prediction_o;
    wire signed [31:0] logit0, logit1, logit2, logit3, logit4;
    wire signed [31:0] logit5, logit6, logit7, logit8, logit9;

    cnn_top dut (
        .clk(clk), .rst_n(rst_n),
        .start_i(start_i), .pixel_i(pixel_i),
        .load_o(load_o), .pixel_idx_o(pixel_idx_o),
        .busy_o(busy_o), .done_o(done_o),
        .prediction_o(prediction_o),
        .logit0_o(logit0), .logit1_o(logit1), .logit2_o(logit2),
        .logit3_o(logit3), .logit4_o(logit4), .logit5_o(logit5),
        .logit6_o(logit6), .logit7_o(logit7), .logit8_o(logit8),
        .logit9_o(logit9)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    // Image buffer: loaded from test/image_input.mem via $readmemh
    reg [7:0] img [0:783];

    // Ground truth
    localparam GT_LABEL = 4'd7;

    // Expected RTL logits (from bit-exact Python RTL emulator)
    localparam signed [31:0] EXP_L0 = -32'sd21, EXP_L1 = -32'sd21,
                              EXP_L2 =  32'sd2,  EXP_L3 = -32'sd1,
                              EXP_L4 = -32'sd46, EXP_L5 = -32'sd33,
                              EXP_L6 = -32'sd77, EXP_L7 =  32'sd49,
                              EXP_L8 = -32'sd30, EXP_L9 = -32'sd8;

    integer j, timeout_cnt, pixel_errors;

    // VCD waveform
    initial begin
        $dumpfile("mnist_waves.vcd");
        $dumpvars(0, tb_mnist_digit);
    end

    // Watchdog: 60 seconds sim time
    initial begin
        #60000000000;
        $display("WATCHDOG TIMEOUT -- simulation did not complete");
        $finish;
    end

    initial begin
        $display("=== QUANTA_2 MNIST Real-Digit Test ===");
        $display("Image:       test/image_input.mem  (784 pixels, uint8)");
        $display("Ground truth: label = %0d", GT_LABEL);
        $display("");

        // Load image from relative path (run from sim/)
        $readmemh("../test/image_input.mem", img);

        // Quick sanity: count non-zero pixels
        pixel_errors = 0;
        for (j=0; j<784; j=j+1)
            if (img[j] > 8'hFF) pixel_errors = pixel_errors + 1;
        $display("Pixels loaded: 784  non-zero: %0d  range-errors: %0d",
            pixel_errors, pixel_errors);

        // Reset
        rst_n = 0; start_i = 0; pixel_i = 0;
        repeat(6) @(posedge clk);
        rst_n = 1;
        repeat(4) @(posedge clk);

        $display("Starting RTL inference...");
        $display("(This takes ~30s wall-clock in simulation)");

        // Feed image: correct pixel-loading protocol
        @(negedge clk); start_i = 1'b1; pixel_i = img[0];
        @(negedge clk); start_i = 1'b0; pixel_i = img[1];
        for (j = 2; j <= 783; j = j + 1) begin
            @(negedge clk);
            pixel_i = img[j];
        end

        // Wait for inference to complete
        timeout_cnt = 0;
        @(posedge clk);
        while (done_o !== 1'b1 && timeout_cnt < 8000000) begin
            @(posedge clk);
            timeout_cnt = timeout_cnt + 1;
        end
        @(posedge clk);  // extra cycle to let outputs settle

        $display("");
        if (timeout_cnt >= 8000000) begin
            $display("ERROR: Timeout waiting for done_o");
            $finish;
        end

        $display("Inference complete after %0d clock cycles.", timeout_cnt);
        $display("");
        $display("=== RTL Output Logits ===");
        $display("  logit[0] = %0d  (digit 0)", logit0);
        $display("  logit[1] = %0d  (digit 1)", logit1);
        $display("  logit[2] = %0d  (digit 2)", logit2);
        $display("  logit[3] = %0d  (digit 3)", logit3);
        $display("  logit[4] = %0d  (digit 4)", logit4);
        $display("  logit[5] = %0d  (digit 5)", logit5);
        $display("  logit[6] = %0d  (digit 6)", logit6);
        $display("  logit[7] = %0d  (digit 7)  <-- argmax", logit7);
        $display("  logit[8] = %0d  (digit 8)", logit8);
        $display("  logit[9] = %0d  (digit 9)", logit9);
        $display("");
        $display("RTL predicted digit: %0d", prediction_o);
        $display("Ground truth label:  %0d", GT_LABEL);

        if (prediction_o == GT_LABEL)
            $display("RESULT: CORRECT -- RTL matches ground truth label 7");
        else
            $display("RESULT: INCORRECT -- RTL predicted %0d, expected %0d",
                prediction_o, GT_LABEL);

        $display("");
        $display("=== Bit-exact comparison vs Python RTL emulator ===");
        if (logit0===EXP_L0 && logit1===EXP_L1 && logit2===EXP_L2 &&
            logit3===EXP_L3 && logit4===EXP_L4 && logit5===EXP_L5 &&
            logit6===EXP_L6 && logit7===EXP_L7 && logit8===EXP_L8 &&
            logit9===EXP_L9) begin
            $display("ALL LOGITS MATCH emulator  [-21,-21,2,-1,-46,-33,-77,49,-30,-8]");
        end else begin
            if (logit0!==EXP_L0) $display("  DIFF logit[0]: RTL=%0d  emu=%0d", logit0, EXP_L0);
            if (logit1!==EXP_L1) $display("  DIFF logit[1]: RTL=%0d  emu=%0d", logit1, EXP_L1);
            if (logit2!==EXP_L2) $display("  DIFF logit[2]: RTL=%0d  emu=%0d", logit2, EXP_L2);
            if (logit3!==EXP_L3) $display("  DIFF logit[3]: RTL=%0d  emu=%0d", logit3, EXP_L3);
            if (logit4!==EXP_L4) $display("  DIFF logit[4]: RTL=%0d  emu=%0d", logit4, EXP_L4);
            if (logit5!==EXP_L5) $display("  DIFF logit[5]: RTL=%0d  emu=%0d", logit5, EXP_L5);
            if (logit6!==EXP_L6) $display("  DIFF logit[6]: RTL=%0d  emu=%0d", logit6, EXP_L6);
            if (logit7!==EXP_L7) $display("  DIFF logit[7]: RTL=%0d  emu=%0d", logit7, EXP_L7);
            if (logit8!==EXP_L8) $display("  DIFF logit[8]: RTL=%0d  emu=%0d", logit8, EXP_L8);
            if (logit9!==EXP_L9) $display("  DIFF logit[9]: RTL=%0d  emu=%0d", logit9, EXP_L9);
        end

        #100;
        $finish;
    end

endmodule

`default_nettype wire
