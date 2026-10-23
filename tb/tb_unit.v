// tb_unit.v -- QUANTA_2 unit tests for quantization and conv_layer
// Runs all-zero image through Conv1 only and prints intermediate results.
`timescale 1ns/1ps
`default_nettype none

module tb_unit;
    reg clk, rst_n, start;
    initial clk = 0;
    always #5 clk = ~clk;

    // Test quantization directly
    reg signed [31:0] acc_test;
    wire signed [7:0]  q_test;
    quantization #(.MULT(201),.SHIFT(18),.ACC_WIDTH(32),.RELU(1))
        uq (.acc_in(acc_test), .q_out(q_test));

    // Test images
    reg [7:0] img_buf [0:783];
    reg signed [7:0] c1_act [0:10815];

    // Conv1 instance via write-port
    wire [9:0]           c1_in_rd_addr;
    wire [13:0]          c1_out_wr_addr;
    wire signed [7:0]    c1_out_wr_data;
    wire                 c1_out_wr_en;
    wire                 c1_done;
    reg                  c1_start_r;

    conv_layer #(
        .IN_CH(1),.IN_H(28),.IN_W(28),.OUT_CH(16),
        .WEIGHT_FILE("../conv1_weights_int.mem"),
        .BIAS_FILE("../params/conv1_bias_acc.mem"),
        .BIAS_WIDTH(20),.RQUANT_MULT(201),.RQUANT_SHIFT(18),.FIRST_LAYER(1)
    ) u_c1 (
        .clk(clk),.rst_n(rst_n),.start_i(c1_start_r),
        .in_rd_addr(c1_in_rd_addr),
        .in_rd_data(img_buf[c1_in_rd_addr]),
        .out_wr_addr(c1_out_wr_addr),
        .out_wr_data(c1_out_wr_data),
        .out_wr_en(c1_out_wr_en),
        .done_o(c1_done),.busy_o()
    );
    always @(posedge clk)
        if (c1_out_wr_en) c1_act[c1_out_wr_addr] <= c1_out_wr_data;

    integer i, timeout;

    initial begin
        $dumpfile("unit_waves.vcd");
        $dumpvars(0, tb_unit);

        // Test quantization
        $display("=== Quantization unit tests ===");
        acc_test = 19356;
        #1; $display("  quant(19356,MULT=201,SH=18,ReLU=1) = %0d  (expect 15)", q_test);
        acc_test = 5334;
        #1; $display("  quant(5334) = %0d  (expect 4)", q_test);
        acc_test = -1829;
        #1; $display("  quant(-1829) = %0d  (expect 0, ReLU)", q_test);
        acc_test = 0;
        #1; $display("  quant(0) = %0d  (expect 0)", q_test);

        // Reset
        rst_n = 0; c1_start_r = 0;
        repeat(4) @(posedge clk); rst_n = 1; repeat(2) @(posedge clk);

        // Load all-zero image
        for (i=0; i<784; i=i+1) img_buf[i] = 8'h00;

        // Start Conv1
        $display("=== Conv1 all-zero inference ===");
        @(negedge clk); c1_start_r = 1;
        @(negedge clk); c1_start_r = 0;

        // Wait for done
        timeout = 0;
        @(posedge clk);
        while (!c1_done && timeout < 200000) begin @(posedge clk); timeout = timeout+1; end
        @(posedge clk);

        $display("Conv1 done. First 16 outputs (one per channel at oy=0,ox=0):");
        for (i=0; i<16; i=i+1)
            $display("  c1_act[%0d] (oc=%0d,oy=0,ox=0) = %0d", i*676, i, $signed(c1_act[i*676]));
        $display("Expected oc=0:15, oc=1:4, oc=2:0, oc=8:0(ReLU), oc=11:0(ReLU)");

        #100; $finish;
    end

    initial begin #50000000; $display("WATCHDOG"); $finish; end
endmodule
`default_nettype wire
