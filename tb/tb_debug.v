// tb_debug.v -- traces full all-zero inference through cnn_top internals
`timescale 1ns/1ps
`default_nettype none

module tb_debug;
    reg clk, rst_n, start_i;
    reg [7:0] pixel_i;
    wire load_o;
    wire [9:0] pixel_idx_o;
    wire busy_o, done_o;
    wire [3:0] prediction_o;
    wire signed [31:0] l0,l1,l2,l3,l4,l5,l6,l7,l8,l9;

    cnn_top dut (
        .clk(clk),.rst_n(rst_n),.start_i(start_i),.pixel_i(pixel_i),
        .load_o(load_o),.pixel_idx_o(pixel_idx_o),
        .busy_o(busy_o),.done_o(done_o),.prediction_o(prediction_o),
        .logit0_o(l0),.logit1_o(l1),.logit2_o(l2),.logit3_o(l3),.logit4_o(l4),
        .logit5_o(l5),.logit6_o(l6),.logit7_o(l7),.logit8_o(l8),.logit9_o(l9)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    integer i, timeout;

    initial begin
        rst_n = 0; start_i = 0; pixel_i = 0;
        repeat(5) @(posedge clk); rst_n = 1; repeat(3) @(posedge clk);

        $display("=== All-zero image debug trace ===");

        // Load all-zero: hold pixel_i=0 throughout
        @(negedge clk); start_i = 1; pixel_i = 0;
        @(negedge clk); start_i = 0;
        // Feed remaining 783 pixels (all zero)
        for (i=1; i<=783; i=i+1) begin
            @(negedge clk); pixel_i = 0;
        end

        // Wait for done
        timeout = 0;
        @(posedge clk);
        while (!done_o && timeout < 10000000) begin @(posedge clk); timeout=timeout+1; end
        @(posedge clk);

        $display("Logits: [%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d]",l0,l1,l2,l3,l4,l5,l6,l7,l8,l9);
        $display("Prediction: %0d", prediction_o);
        $display("Expected:   [-3,5,4,-4,-4,2,-6,3,-7,-3] pred=1");

        // Print internal Conv1 output for oc=0
        $display("DUT c1_act[0] (oc=0,oy=0,ox=0) = %0d  (expect 15)", $signed(dut.c1_act[0]));
        $display("DUT c1_act[676] (oc=1,oy=0,ox=0) = %0d  (expect 4)", $signed(dut.c1_act[676]));
        $display("DUT p1_act[0] = %0d  (expect 15)", $signed(dut.p1_act[0]));
        $display("DUT p2_act[0] = %0d", $signed(dut.p2_act[0]));
        $display("DUT logits[0..4] = [%0d,%0d,%0d,%0d,%0d]",
            dut.logits[0],dut.logits[1],dut.logits[2],dut.logits[3],dut.logits[4]);

        // Inspect img_buf - first few pixels
        $display("img_buf[0]=%0d  [1]=%0d  [2]=%0d  [783]=%0d (all should be 0)",
            dut.img_buf[0],dut.img_buf[1],dut.img_buf[2],dut.img_buf[783]);

        #100; $finish;
    end
    initial begin #5000000000; $display("WATCHDOG"); $finish; end
endmodule
`default_nettype wire
