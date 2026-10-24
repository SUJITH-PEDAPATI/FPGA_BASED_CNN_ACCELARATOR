// tb_unit_vivado.v -- QUANTA_2  Vivado behavioral simulation unit test
//
// PURPOSE: Vivado-safe version of tb_unit.v for testing Conv1 (quantization.v +
//          conv_layer.v) with an all-zero image.  Differs from tb_unit.v ONLY in:
//   1. All control signals initialized at t=0 (rst_n=0, start=0, c1_start_r=0).
//   2. WEIGHT_FILE and BIAS_FILE use ABSOLUTE paths (required for Vivado xsim).
//   3. $dumpfile/$dumpvars removed (not supported by xsim; use Vivado wave config).
//   4. Watchdog adjusted for Vivado (uses $time in ns directly).
//   5. Extra $display diagnostics for Vivado transcript.
//
// Required Vivado settings:
//   - Sim top    : tb_unit_vivado
//   - Runtime    : 2000 us  (Conv1 needs ~1082 us; 2000 gives margin)
//   - Sources    : rtl/quantization.v  rtl/conv_layer.v  tb/tb_unit_vivado.v
//
// Expected output (CORRECT -- all-zero image):
//   c1_act[0]    (oc=0) = 15
//   c1_act[676]  (oc=1) = 4
//   c1_act[1352] (oc=2) = 0
//   (see tb_unit.v for full expected list)
//
// Update the two absolute path strings if the project root changes.

`timescale 1ns/1ps
`default_nettype none

module tb_unit_vivado;

    // ----------------------------------------------------------------
    // Clock and control -- ALL initialized at t=0 (prevents X in xsim)
    // ----------------------------------------------------------------
    reg clk    = 1'b0;      // t=0 initialization
    reg rst_n  = 1'b0;      // t=0: reset asserted
    reg start  = 1'b0;      // unused here; prevent X on waveform

    always #5 clk = ~clk;  // 100 MHz

    // ----------------------------------------------------------------
    // Quantization unit under test (combinational -- no paths needed)
    // ----------------------------------------------------------------
    reg signed [31:0] acc_test = 32'sd0;
    wire signed [7:0]  q_test;
    quantization #(.MULT(201),.SHIFT(18),.ACC_WIDTH(32),.RELU(1))
        uq (.acc_in(acc_test), .q_out(q_test));

    // ----------------------------------------------------------------
    // Image buffer (all-zero, filled before start)
    // ----------------------------------------------------------------
    reg [7:0]        img_buf [0:783];
    reg signed [7:0] c1_act  [0:10815];  // capture conv1 outputs

    // ----------------------------------------------------------------
    // Conv1 instance -- ABSOLUTE PATHS for Vivado xsim
    // ----------------------------------------------------------------
    wire [9:0]          c1_in_rd_addr;
    wire [13:0]         c1_out_wr_addr;
    wire signed [7:0]   c1_out_wr_data;
    wire                c1_out_wr_en;
    wire                c1_done;
    reg                 c1_start_r = 1'b0;  // t=0 init

    conv_layer #(
        .IN_CH(1), .IN_H(28), .IN_W(28), .OUT_CH(16),
        // --------------------------------------------------------
        // ABSOLUTE PATHS -- update if project root changes
        // --------------------------------------------------------
        .WEIGHT_FILE("F:/QUANTA_2/conv1_weights_int.mem"),
        .BIAS_FILE  ("F:/QUANTA_2/params/conv1_bias_acc.mem"),
        // --------------------------------------------------------
        .BIAS_WIDTH(20), .RQUANT_MULT(201), .RQUANT_SHIFT(18), .FIRST_LAYER(1)
    ) u_c1 (
        .clk       (clk),
        .rst_n     (rst_n),
        .start_i   (c1_start_r),
        .in_rd_addr(c1_in_rd_addr),
        .in_rd_data(img_buf[c1_in_rd_addr]),
        .out_wr_addr(c1_out_wr_addr),
        .out_wr_data(c1_out_wr_data),
        .out_wr_en (c1_out_wr_en),
        .done_o    (c1_done),
        .busy_o    ()
    );

    // Capture conv1 outputs
    always @(posedge clk)
        if (c1_out_wr_en) c1_act[c1_out_wr_addr] <= c1_out_wr_data;

    integer i, timeout;

    // ----------------------------------------------------------------
    // Stimulus
    // ----------------------------------------------------------------
    initial begin
        $display("=== QUANTA_2 Vivado Unit Test (tb_unit_vivado) ===");
        $display("    Conv1 with all-zero image + quantization checks");
        $display("    t=0: rst_n=0, start=0, c1_start_r=0 (all signals known)");
        $display("");

        // -----------------------------------------------------------
        // Quantization unit tests (combinational, no clock needed)
        // -----------------------------------------------------------
        $display("--- Quantization unit tests ---");
        acc_test = 32'sd19356; #1;
        $display("  quant(19356,MULT=201,SH=18,ReLU=1) = %0d  (expect 15)", q_test);
        acc_test = 32'sd5334;  #1;
        $display("  quant(5334)  = %0d  (expect 4)",  q_test);
        acc_test = -32'sd1829; #1;
        $display("  quant(-1829) = %0d  (expect 0 -- ReLU)", q_test);
        acc_test = 32'sd0;     #1;
        $display("  quant(0)     = %0d  (expect 0)",  q_test);
        $display("");

        // -----------------------------------------------------------
        // Check that weight/bias files loaded correctly (non-X)
        // -----------------------------------------------------------
        $display("--- Memory initialization check ---");
        $display("  weights[0]   = 0x%02h  (expect DA -- non-X if file loaded)", u_c1.weights[0]);
        $display("  weights[143] = 0x%02h  (last weight entry -- non-X)",        u_c1.weights[143]);
        $display("  bias_a[0]    = 0x%05h (expect 04B9C -- non-X)",              u_c1.bias_a[0]);
        $display("  bias_a[15]   = 0x%05h (last bias entry -- non-X)",           u_c1.bias_a[15]);
        if (^u_c1.weights[0] === 1'bx)
            $display("  WARNING: weights[0] is X -- WEIGHT_FILE path failed!");
        else
            $display("  OK: weights[0] is known (file loaded successfully).");
        if (^u_c1.bias_a[0] === 1'bx)
            $display("  WARNING: bias_a[0] is X -- BIAS_FILE path failed!");
        else
            $display("  OK: bias_a[0] is known (file loaded successfully).");
        $display("");

        // -----------------------------------------------------------
        // Reset: already asserted at t=0; hold 4 cycles then release
        // -----------------------------------------------------------
        rst_n = 1'b0; c1_start_r = 1'b0;
        repeat(4) @(posedge clk);
        rst_n = 1'b1;
        $display("Reset released at %0t ns.", $time);
        repeat(2) @(posedge clk);

        // -----------------------------------------------------------
        // Load all-zero image
        // -----------------------------------------------------------
        for (i = 0; i < 784; i = i+1) img_buf[i] = 8'h00;
        $display("Image buffer: all-zero (784 pixels, 0x00).");
        $display("");

        // -----------------------------------------------------------
        // Start Conv1
        // -----------------------------------------------------------
        $display("--- Conv1 all-zero inference ---");
        $display("Starting Conv1 at %0t ns...", $time);
        @(negedge clk); c1_start_r = 1'b1;
        @(negedge clk); c1_start_r = 1'b0;
        $display("  Start pulse sent.  Expected acc after 1st ACCUM = bias_a[0] = 19356.");

        // Check acc on the very first S_ACCUM cycle to detect X early
        @(posedge clk);  // S_IDLE -> S_ACCUM transition posedge
        @(posedge clk);  // first S_ACCUM cycle: acc = bias + mac_term[0]
        $display("  After 1st ACCUM cycle: acc = %0d  (expect 19356 + mac_0; if X, bias not loaded)",
                 u_c1.acc);
        if (^u_c1.acc === 1'bx)
            $display("  ERROR: acc is X! bias_a[0] was X -> file path FAILED.");
        else
            $display("  OK: acc is known.");
        $display("");

        // -----------------------------------------------------------
        // Wait for Conv1 to complete (up to 200,000 cycles = 2 ms)
        // -----------------------------------------------------------
        timeout = 0;
        @(posedge clk);
        while (!c1_done && timeout < 250000) begin
            @(posedge clk);
            timeout = timeout + 1;
        end
        @(posedge clk);  // extra settle cycle

        $display("Conv1 %s at %0t ns. Cycles waited: %0d  (expect ~108151).",
                 c1_done ? "DONE" : "TIMEOUT", $time, timeout);
        $display("");

        if (!c1_done) begin
            $display("ERROR: Conv1 did not assert done_o within 200000 cycles.");
            $display("  Check WEIGHT_FILE/BIAS_FILE paths and simulation runtime.");
        end

        // -----------------------------------------------------------
        // Print first 16 outputs (one per output channel, at oy=0,ox=0)
        // -----------------------------------------------------------
        $display("--- Conv1 output activations (oy=0, ox=0) ---");
        for (i = 0; i < 16; i = i+1)
            $display("  c1_act[%5d] (oc=%2d, oy=0, ox=0) = %4d",
                     i*676, i, $signed(c1_act[i*676]));
        $display("");
        $display("Expected (all-zero image, bias-dominant):");
        $display("  oc= 0: 15   oc= 1:  4   oc= 2:  0   oc= 3:  5");
        $display("  oc= 4: 13   oc= 5:  7   oc= 6: 12   oc= 7:  0");
        $display("  oc= 8:  0   oc= 9:  9   oc=10:  2   oc=11:  0");
        $display("  oc=12:  0   oc=13:  0   oc=14:  0   oc=15:  0");

        // Check oc=0 and oc=1 explicitly
        if (c1_act[0] === 8'sd15)
            $display("  PASS: c1_act[0] (oc=0) = 15");
        else if (^c1_act[0] === 1'bx)
            $display("  FAIL: c1_act[0] is X (weights/biases not loaded)");
        else
            $display("  FAIL: c1_act[0] = %0d (expected 15)", $signed(c1_act[0]));

        if (c1_act[676] === 8'sd4)
            $display("  PASS: c1_act[676] (oc=1) = 4");
        else if (^c1_act[676] === 1'bx)
            $display("  FAIL: c1_act[676] is X");
        else
            $display("  FAIL: c1_act[676] = %0d (expected 4)", $signed(c1_act[676]));

        $display("");
        $display("=== tb_unit_vivado COMPLETE ===");
        #100; $finish;
    end

    // Watchdog: 50 ms (far beyond the 1.082 ms Conv1 needs)
    initial begin
        #50000000;
        $display("WATCHDOG at %0t ns -- Conv1 did not complete.", $time);
        $finish;
    end

endmodule
`default_nettype wire
