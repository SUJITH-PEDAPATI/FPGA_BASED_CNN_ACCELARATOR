// tb_mnist_digit2.v -- QUANTA_2
// RTL inference test for MNIST index=18, ground-truth label=3.
// Image file: test/image_input (1).mem  (784 uint8 pixels, hex, one per line)
// Label file: test/image_label (2).txt  (index=18, label=3)
//
// RTL emulator expected logits (reference/rtl_emulator.py):
//   [-41,-74,-8,3,-63,-18,-46,-59,-4,-36]  prediction=3
//
// Pixel loading protocol (same as tb_cnn_top.v / tb_mnist_digit.v):
//   @negedge: start_i=1, pixel_i=img[0]  -> posedge T_IDLE: img_buf[0]
//   @negedge: start_i=0, pixel_i=img[1]  -> posedge T_LOAD pix_cnt=0: img_buf[1]
//   @negedge: pixel_i=img[j] j=2..783   -> posedge T_LOAD: img_buf[j]

`timescale 1ns/1ps
`default_nettype none

module tb_mnist_digit2;

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

    // Image buffer -- $readmemh loads one hex byte per line
    reg [7:0] img [0:783];

    // Ground truth (from image_label (2).txt)
    localparam GT_INDEX = 18;
    localparam GT_LABEL = 4'd3;

    // RTL emulator expected logits
    localparam signed [31:0]
        EXP_L0=-32'sd41, EXP_L1=-32'sd74, EXP_L2=-32'sd8,
        EXP_L3= 32'sd3,  EXP_L4=-32'sd63, EXP_L5=-32'sd18,
        EXP_L6=-32'sd46, EXP_L7=-32'sd59, EXP_L8=-32'sd4, EXP_L9=-32'sd36;

    integer j, timeout_cnt;

    initial begin
        $dumpfile("mnist2_waves.vcd");
        $dumpvars(0, tb_mnist_digit2);
    end

    // Watchdog 60 s sim-time
    initial begin
        #60000000000;
        $display("WATCHDOG TIMEOUT -- inference did not complete");
        $finish;
    end

    initial begin
        $display("=== QUANTA_2 MNIST Real-Digit Test  (index=%0d, label=%0d) ===",
            GT_INDEX, GT_LABEL);
        $display("Image : test/image_input (1).mem");
        $display("Label : test/image_label (2).txt  -> label=%0d", GT_LABEL);
        $display("");

        // Load image -- parentheses in filename work fine with $readmemh string literal
        $readmemh("../test/image_input (1).mem", img);

        // Sanity: spot-check pixel 0 = 0x00 (known from inspection)
        $display("img[0]=0x%02h  img[100]=0x%02h  img[400]=0x%02h  (spot-check)",
            img[0], img[100], img[400]);

        // Reset
        rst_n = 0; start_i = 0; pixel_i = 0;
        repeat(6) @(posedge clk);
        rst_n = 1;
        repeat(4) @(posedge clk);

        $display("Starting RTL inference (approx 30 s wall-clock)...");

        // Feed pixels: correct handshake
        @(negedge clk); start_i = 1'b1; pixel_i = img[0];
        @(negedge clk); start_i = 1'b0; pixel_i = img[1];
        for (j = 2; j <= 783; j = j + 1) begin
            @(negedge clk);
            pixel_i = img[j];
        end

        // Wait for done_o
        timeout_cnt = 0;
        @(posedge clk);
        while (done_o !== 1'b1 && timeout_cnt < 8000000) begin
            @(posedge clk);
            timeout_cnt = timeout_cnt + 1;
        end
        @(posedge clk);

        $display("");
        if (timeout_cnt >= 8000000) begin
            $display("ERROR: Inference did not complete within timeout.");
            $finish;
        end

        $display("Inference complete.  Clock cycles waited: %0d", timeout_cnt);
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

        if (prediction_o == GT_LABEL)
            $display("PREDICTION: CORRECT -- matches ground truth label %0d", GT_LABEL);
        else
            $display("PREDICTION: INCORRECT -- RTL=%0d  expected=%0d",
                prediction_o, GT_LABEL);

        $display("");
        $display("=== Bit-exact comparison vs Python RTL emulator ===");
        $display("   Emulator expected: [-41,-74,-8,3,-63,-18,-46,-59,-4,-36]");

        if (logit0===EXP_L0 && logit1===EXP_L1 && logit2===EXP_L2 &&
            logit3===EXP_L3 && logit4===EXP_L4 && logit5===EXP_L5 &&
            logit6===EXP_L6 && logit7===EXP_L7 && logit8===EXP_L8 &&
            logit9===EXP_L9) begin
            $display("ALL LOGITS MATCH emulator -- bit-exact agreement confirmed.");
        end else begin
            $display("DIFFERENCES vs emulator:");
            if (logit0!==EXP_L0) $display("  logit[0]: RTL=%0d emu=%0d",logit0,EXP_L0);
            if (logit1!==EXP_L1) $display("  logit[1]: RTL=%0d emu=%0d",logit1,EXP_L1);
            if (logit2!==EXP_L2) $display("  logit[2]: RTL=%0d emu=%0d",logit2,EXP_L2);
            if (logit3!==EXP_L3) $display("  logit[3]: RTL=%0d emu=%0d",logit3,EXP_L3);
            if (logit4!==EXP_L4) $display("  logit[4]: RTL=%0d emu=%0d",logit4,EXP_L4);
            if (logit5!==EXP_L5) $display("  logit[5]: RTL=%0d emu=%0d",logit5,EXP_L5);
            if (logit6!==EXP_L6) $display("  logit[6]: RTL=%0d emu=%0d",logit6,EXP_L6);
            if (logit7!==EXP_L7) $display("  logit[7]: RTL=%0d emu=%0d",logit7,EXP_L7);
            if (logit8!==EXP_L8) $display("  logit[8]: RTL=%0d emu=%0d",logit8,EXP_L8);
            if (logit9!==EXP_L9) $display("  logit[9]: RTL=%0d emu=%0d",logit9,EXP_L9);
        end

        #100;
        $finish;
    end

endmodule
`default_nettype wire
