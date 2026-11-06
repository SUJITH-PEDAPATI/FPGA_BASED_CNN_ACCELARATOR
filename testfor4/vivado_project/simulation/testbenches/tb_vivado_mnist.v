// tb_vivado_mnist.v -- QUANTA_2 Vivado behavioral simulation testbench for Digit 4
`timescale 1ns/1ps
`default_nettype none

module tb_vivado_mnist;

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

    // Ground truth for test/image_input_4.mem (MNIST index=4, label=4)
    localparam GT_LABEL = 4'd4;

    integer j, timeout_cnt;

    // Watchdog: 7,500,000 ns = 750,000 cycles
    `ifdef DUMP_VCD
    initial begin
        $dumpfile("F:/QUANTA_2/testfor4/success_test_for_digit_4/waveforms/tb_vivado_mnist_digit4.vcd");
        $dumpvars(0, tb_vivado_mnist);
    end
    `endif

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

        $display("=== QUANTA_2 Vivado Behavioral Simulation for Digit 4 ===");
        $display("    Testbench: tb_vivado_mnist.v");
        $display("    Image:     test/image_input_4.mem (MNIST index=4, label=4)");
        $display("");

        $readmemh("F:/QUANTA_2/testfor4/test/image_input_4.mem", img);
        $display("Image loaded. img[0]=0x%02h  img[391]=0x%02h  img[783]=0x%02h",
            img[0], img[391], img[783]);

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
            $display("RESULT: CORRECT  -- prediction matches ground truth label %0d", GT_LABEL);
        else
            $display("RESULT: INCORRECT -- RTL=%0d  expected=%0d", prediction_o, GT_LABEL);

        $display("");
        $display("=== Expected (Python RTL emulator) ===");
        $display("  logits = [-27, -18, -26, -34, 39, -37, -27, -12, -24, 4]");
        $display("  pred   = 4");

        // Bit-exact check
        if (logit0==-27 && logit1==-18 && logit2==-26 && logit3==-34 &&
            logit4==39  && logit5==-37 && logit6==-27 && logit7==-12 &&
            logit8==-24 && logit9==4)
            $display("EMULATOR CHECK: ALL 10 LOGITS MATCH -- bit-exact agreement.");
        else
            $display("EMULATOR CHECK: some logits differ (see values above vs expected).");

        #100;
        $finish;
    end

endmodule

`default_nettype wire

