`timescale 1ns/1ps
`default_nettype none
module tb_debug2;
    reg clk, rst_n;
    reg [7:0] pixel_i;
    wire load_o;
    wire [9:0] pixel_idx_o;
    wire busy_o, done_o;
    wire [3:0] prediction_o;
    wire signed [31:0] l0,l1,l2,l3,l4,l5,l6,l7,l8,l9;

    cnn_top dut (
        .clk(clk),.rst_n(rst_n),.start_i(load_o ? 1'b0 : done_o ? 1'b0 : start_r),
        .pixel_i(pixel_i),.load_o(load_o),.pixel_idx_o(pixel_idx_o),
        .busy_o(busy_o),.done_o(done_o),.prediction_o(prediction_o),
        .logit0_o(l0),.logit1_o(l1),.logit2_o(l2),.logit3_o(l3),.logit4_o(l4),
        .logit5_o(l5),.logit6_o(l6),.logit7_o(l7),.logit8_o(l8),.logit9_o(l9)
    );

    reg start_r;
    initial clk = 0;
    always #5 clk = ~clk;

    integer i, timeout;

    initial begin
        rst_n = 0; start_r = 0; pixel_i = 0;
        repeat(5) @(posedge clk); rst_n = 1; repeat(3) @(posedge clk);

        // --- All-max (255) image ---
        $display("=== All-max image ===");
        @(negedge clk); start_r = 1; pixel_i = 255;
        @(negedge clk); start_r = 0; pixel_i = 255;
        for (i=1; i<=782; i=i+1) begin @(negedge clk); pixel_i = 255; end

        timeout = 0;
        @(posedge clk);
        while (!done_o && timeout < 10000000) begin @(posedge clk); timeout=timeout+1; end
        @(posedge clk);
        $display("Logits: [%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d]",l0,l1,l2,l3,l4,l5,l6,l7,l8,l9);
        $display("Expected (RTL-emulator): [-10,-23,-30,-34,-6,-59,5,-43,-9,-50]");
        $display("c2_act[0]=%0d (expect 34), c2_act[1]=%0d", $signed(dut.c2_act[0]), $signed(dut.c2_act[1]));
        $display("p2_act[0]=%0d (expect 34), p2_act[1]=%0d", $signed(dut.p2_act[0]), $signed(dut.p2_act[1]));
        $display("logits[0]=%0d  (expect -10)", dut.logits[0]);

        // --- Now run all-zero to test consecutive ---
        $display("=== Consecutive all-zero image ===");
        @(negedge clk); start_r = 1; pixel_i = 0;
        @(negedge clk); start_r = 0; pixel_i = 0;
        for (i=1; i<=782; i=i+1) begin @(negedge clk); pixel_i = 0; end

        timeout = 0;
        @(posedge clk);
        while (!done_o && timeout < 10000000) begin @(posedge clk); timeout=timeout+1; end
        @(posedge clk);
        $display("Logits: [%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d]",l0,l1,l2,l3,l4,l5,l6,l7,l8,l9);
        $display("Expected: [-3,5,4,-4,-4,2,-6,3,-7,-3]");
        $display("img_buf[0..3] = %0d %0d %0d %0d (expect all 0)",
            dut.img_buf[0],dut.img_buf[1],dut.img_buf[2],dut.img_buf[3]);

        #100; $finish;
    end
    initial begin #10000000000; $display("WATCHDOG"); $finish; end
endmodule
`default_nettype wire
