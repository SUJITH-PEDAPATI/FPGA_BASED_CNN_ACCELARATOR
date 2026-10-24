// tb_xprop_diag.v  -- QUANTA_2 diagnostic for Vivado X-propagation
// Purpose: Prove EXACTLY where X is injected.
//
// This testbench reproduces the Vivado failure mode by loading weights from
// a non-existent file path (so arrays stay X), then shows that acc goes X
// on the very first S_ACCUM cycle, before any write occurs.
//
// Run from sim/ with Icarus:
//   iverilog -g2001 -Wall -o xprop_diag.vvp \
//     -I ../rtl ../rtl/quantization.v ../rtl/conv_layer.v tb_xprop_diag.v
//   vvp xprop_diag.vvp
//
`timescale 1ns/1ps
`default_nettype none

module tb_xprop_diag;

    // ----------------------------------------------------------------
    // Clock and control
    // ----------------------------------------------------------------
    reg clk   = 0;
    reg rst_n = 0;
    always #5 clk = ~clk;

    // ----------------------------------------------------------------
    // All-zero image buffer (completely known)
    // ----------------------------------------------------------------
    reg [7:0] img_buf [0:783];
    integer p;
    initial begin
        for (p = 0; p < 784; p = p+1) img_buf[p] = 8'h00;
    end

    // ----------------------------------------------------------------
    // Probe signals -- must be wires to observe internal module state
    // ----------------------------------------------------------------
    wire [9:0]          c1_in_rd_addr;
    wire [13:0]         c1_out_wr_addr;
    wire signed [7:0]   c1_out_wr_data;
    wire                c1_out_wr_en;
    wire                c1_done;
    reg                 c1_start_r = 0;

    // ----------------------------------------------------------------
    // CASE A: CORRECT paths (baseline -- should produce known values)
    // ----------------------------------------------------------------
    conv_layer #(
        .IN_CH(1),.IN_H(28),.IN_W(28),.OUT_CH(16),
        .WEIGHT_FILE("../conv1_weights_int.mem"),
        .BIAS_FILE("../params/conv1_bias_acc.mem"),
        .BIAS_WIDTH(20),.RQUANT_MULT(201),.RQUANT_SHIFT(18),.FIRST_LAYER(1)
    ) u_c1_good (
        .clk(clk),.rst_n(rst_n),.start_i(c1_start_r),
        .in_rd_addr(c1_in_rd_addr),
        .in_rd_data(img_buf[c1_in_rd_addr]),
        .out_wr_addr(c1_out_wr_addr),
        .out_wr_data(c1_out_wr_data),
        .out_wr_en(c1_out_wr_en),
        .done_o(c1_done),.busy_o()
    );

    // ----------------------------------------------------------------
    // CASE B: BROKEN paths (simulates Vivado xsim CWD mismatch)
    // Weights/biases will be all-X after $readmemh silently fails.
    // ----------------------------------------------------------------
    wire [9:0]          b_in_rd_addr;
    wire [13:0]         b_out_wr_addr;
    wire signed [7:0]   b_out_wr_data;
    wire                b_out_wr_en;
    wire                b_done;

    conv_layer #(
        .IN_CH(1),.IN_H(28),.IN_W(28),.OUT_CH(16),
        .WEIGHT_FILE("DOES_NOT_EXIST.mem"),      // intentionally broken
        .BIAS_FILE("DOES_NOT_EXIST_bias.mem"),   // intentionally broken
        .BIAS_WIDTH(20),.RQUANT_MULT(201),.RQUANT_SHIFT(18),.FIRST_LAYER(1)
    ) u_c1_bad (
        .clk(clk),.rst_n(rst_n),.start_i(c1_start_r),
        .in_rd_addr(b_in_rd_addr),
        .in_rd_data(img_buf[b_in_rd_addr]),
        .out_wr_addr(b_out_wr_addr),
        .out_wr_data(b_out_wr_data),
        .out_wr_en(b_out_wr_en),
        .done_o(b_done),.busy_o()
    );

    integer i, timeout;

    initial begin
        $dumpfile("xprop_diag.vcd");
        $dumpvars(0, tb_xprop_diag);

        $display("=== QUANTA_2 X-propagation diagnostic ===");
        $display("All-zero image -- 784 pixels all 0x00.");
        $display("");

        // Reset both instances
        rst_n = 0; c1_start_r = 0;
        repeat(4) @(posedge clk); rst_n = 1; repeat(2) @(posedge clk);

        // --- Check internal weight[0] and bias[0] immediately after reset ---
        // (Access via hierarchical references)
        $display("--- Memory load check (immediately after rst_n=1) ---");
        $display("  GOOD: weights[0] = 0x%02h  (expect DA=non-X)", u_c1_good.weights[0]);
        $display("  GOOD: bias_a[0]  = 0x%05h (expect 04B9C=non-X)", u_c1_good.bias_a[0]);
        $display("  BAD:  weights[0] = 0x%02h  (expect X -- file missing)", u_c1_bad.weights[0]);
        $display("  BAD:  bias_a[0]  = 0x%05h (expect X -- file missing)", u_c1_bad.bias_a[0]);
        $display("");

        // Start both convolution instances
        $display("--- Pulsing start ---");
        @(negedge clk); c1_start_r = 1;
        @(posedge clk);  // S_IDLE transition: acc <= bias_a[0]
        @(negedge clk); c1_start_r = 0;

        // Sample acc on NEXT posedge (first S_ACCUM cycle)
        @(posedge clk);
        $display("--- First S_ACCUM cycle (after start pulse) ---");
        $display("  GOOD: acc (u_c1_good) = %0d (expect 19356=0x04B9C, known)", u_c1_good.acc);
        $display("  BAD:  acc (u_c1_bad)  = %0d (expect X -- bias file missing)", u_c1_bad.acc);
        $display("  GOOD: mac_term        = %0d (0*weight -- weight[0]=0xDA=-38, zero input)", u_c1_good.mac_term);
        $display("  BAD:  mac_term        = %0d (0*X -- X propagates through multiply)", u_c1_bad.mac_term);
        $display("");

        // Wait 9 more cycles (complete first output pixel accumulation)
        repeat(8) @(posedge clk);
        @(posedge clk);  // last_tap fires -> S_WRITE
        $display("--- After 9 ACCUM cycles (S_WRITE for pixel 0) ---");
        $display("  GOOD: out_wr_data = %0d (expect 15)", c1_out_wr_data);
        $display("  BAD:  out_wr_data = %0d (expect X)",  b_out_wr_data);
        $display("  GOOD: out_wr_en   = %0b (expect 1)", c1_out_wr_en);
        $display("  BAD:  out_wr_en   = %0b (expect 1)", b_out_wr_en);
        $display("");

        // Run GOOD instance to completion
        timeout = 0;
        @(posedge clk);
        while (!c1_done && timeout < 200000) begin @(posedge clk); timeout=timeout+1; end
        @(posedge clk);

        $display("--- Conv1 complete (GOOD instance) ---");
        $display("  Done after %0d cycles.", timeout);
        $display("  c1_act[0]   (oc=0,oy=0,ox=0) = %0d  (expect 15)", u_c1_good.out_wr_data);
        $display("  out_wr_data at done = %0d", c1_out_wr_data);
        $display("");

        $display("=== Conclusion ===");
        $display("  GOOD: weights/biases loaded -> acc known -> outputs known");
        $display("  BAD:  files missing -> bias_a[0]=X -> acc=X at cycle 1 -> all outputs X");
        $display("  This is EXACTLY what Vivado xsim shows when the relative");
        $display("  mem file paths fail to resolve from the xsim working directory.");
        $display("");
        $display("  FIX: Use ABSOLUTE paths in the conv_layer parameter override,");
        $display("  OR copy .mem files to the xsim CWD via a pre-sim Tcl hook.");

        #100; $finish;
    end

    initial begin #50000000; $display("WATCHDOG"); $finish; end
endmodule
`default_nettype wire
