// tb_vivado_mnist.v  --  QUANTA_2  rtl_desktop copy
// ============================================================
// Full-CNN Vivado behavioral simulation testbench.
// Tests the 5-layer CNN on a real MNIST image (digit 7).
//
// Project root: F:\QUANTA_2\rtl_desktop
// Update the $readmemh path on line marked "ABSOLUTE PATH"
// if this folder is moved.
//
// Required Vivado settings:
//   Design Sources : rtl/quantization.v  rtl/conv_layer.v
//                    rtl/fully_connected.v  rtl/argmax.v
//                    rtl/relu.v  rtl/maxpool.v
//                    tb/cnn_top_vivado.v      ← NOT rtl/cnn_top.v
//   Sim Sources    : tb/tb_vivado_mnist.v     ← this file
//   Sim Top        : tb_vivado_mnist
//   Runtime        : 7500 us
// ============================================================
`timescale 1ns/1ps
`default_nettype none

module tb_vivado_mnist;

    // ── DUT signals ────────────────────────────────────────────────────────
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

    // ── DUT instantiation ──────────────────────────────────────────────────
    cnn_top dut (
        .clk          (clk),
        .rst_n        (rst_n),
        .start_i      (start_i),
        .pixel_i      (pixel_i),
        .load_o       (load_o),
        .pixel_idx_o  (pixel_idx_o),
        .busy_o       (busy_o),
        .done_o       (done_o),
        .prediction_o (prediction_o),
        .logit0_o(logit0), .logit1_o(logit1),
        .logit2_o(logit2), .logit3_o(logit3),
        .logit4_o(logit4), .logit5_o(logit5),
        .logit6_o(logit6), .logit7_o(logit7),
        .logit8_o(logit8), .logit9_o(logit9)
    );

    // ── Clock: 100 MHz (10 ns period) ──────────────────────────────────────
    initial clk = 1'b0;
    always #5 clk = ~clk;

    // ── Image buffer ───────────────────────────────────────────────────────
    reg [7:0] img [0:783];

    // Ground truth: test/image_input.mem = MNIST index 0, label = 7
    localparam GT_LABEL = 4'd7;

    integer j, timeout_cnt;

    // ── Watchdog ───────────────────────────────────────────────────────────
    // CNN needs ~677,624 cycles = ~6,784,240 ns.  7,500,000 ns gives margin.
    initial begin
        #7500000;
        $display("ERROR: WATCHDOG -- CNN did not finish within 7500 us.");
        $display("       Make sure Vivado runtime is set to >= 7500 us.");
        $finish;
    end

    // ── Stimulus ───────────────────────────────────────────────────────────
    initial begin
        // Initialize every testbench-driven signal at t=0
        clk     = 1'b0;
        rst_n   = 1'b0;
        start_i = 1'b0;
        pixel_i = 8'h00;

        $display("=== QUANTA_2 rtl_desktop -- Vivado Behavioral Simulation ===");
        $display("    Testbench : tb_vivado_mnist.v");
        $display("    Image     : test/image_input.mem  (MNIST index 0, label 7)");
        $display("");

        // Load the MNIST image from the rtl_desktop test folder
        // ABSOLUTE PATH -- update if folder moves
        $readmemh("F:/QUANTA_2/rtl_desktop/test/image_input.mem", img);

        // Sanity check: print three pixel values
        $display("Image loaded:  img[0]=0x%02h  img[391]=0x%02h  img[783]=0x%02h",
                 img[0], img[391], img[783]);
        if (^img[0] === 1'bx)
            $display("WARNING: img[0] is X -- image_input.mem path may be wrong!");

        // Reset: assert low for 6 cycles, then release
        repeat(6) @(posedge clk);
        rst_n = 1'b1;
        $display("Reset released at %0t ns.", $time);
        repeat(4) @(posedge clk);

        // Pixel-loading protocol:
        //   negedge 1: start_i=1, pixel_i=img[0]  (DUT enters T_LOAD on next posedge)
        //   negedge 2: start_i=0, pixel_i=img[1]
        //   negedges 3..783: pixel_i=img[2..783]
        $display("Starting inference at %0t ns...", $time);
        @(negedge clk); start_i = 1'b1; pixel_i = img[0];
        @(negedge clk); start_i = 1'b0; pixel_i = img[1];
        for (j = 2; j <= 783; j = j + 1) begin
            @(negedge clk);
            pixel_i = img[j];
        end
        $display("All 784 pixels fed.  Waiting for done_o...");

        // Wait for inference completion (timeout = 750,000 cycles = 7,500,000 ns)
        timeout_cnt = 0;
        @(posedge clk);
        while (done_o !== 1'b1 && timeout_cnt < 750000) begin
            @(posedge clk);
            timeout_cnt = timeout_cnt + 1;
        end
        @(posedge clk);  // extra settle cycle

        if (timeout_cnt >= 750000) begin
            $display("ERROR: done_o never asserted after 750,000 cycles.");
            $finish;
        end

        // ── Results ─────────────────────────────────────────────────────────
        $display("");
        $display("=== Inference complete at %0t ns ===", $time);
        $display("    Cycles after pixel feed: %0d", timeout_cnt);
        $display("");
        $display("=== RTL Output Logits ===");
        $display("  logit[0] = %4d  (digit 0)", logit0);
        $display("  logit[1] = %4d  (digit 1)", logit1);
        $display("  logit[2] = %4d  (digit 2)", logit2);
        $display("  logit[3] = %4d  (digit 3)", logit3);
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
            $display("RESULT: CORRECT -- prediction matches ground truth label %0d", GT_LABEL);
        else
            $display("RESULT: INCORRECT -- RTL=%0d  expected=%0d", prediction_o, GT_LABEL);

        $display("");
        $display("=== Expected (Python RTL emulator) ===");
        $display("  logits = [-21,-21,2,-1,-46,-33,-77,49,-30,-8]");
        $display("  pred   = 7");

        if (logit0==-21 && logit1==-21 && logit2==2   && logit3==-1  &&
            logit4==-46 && logit5==-33 && logit6==-77 && logit7==49  &&
            logit8==-30 && logit9==-8)
            $display("EMULATOR CHECK: ALL 10 LOGITS MATCH -- bit-exact agreement.");
        else
            $display("EMULATOR CHECK: some logits differ (see above vs expected).");

        #100;
        $finish;
    end

endmodule
`default_nettype wire
