// tb_cnn_top.v -- QUANTA_2  (Verilog-2001 testbench)
// Comprehensive testbench for cnn_top.
//
// RTL expected values are from the bit-exact Python RTL emulator
// (reference/rtl_emulator.py) which mirrors the Verilog fixed-point
// arithmetic.  +/-1 logit differences from the rational reference are
// expected due to the MULT/SHIFT approximation.
//
// Pixel loading protocol (corrected):
//   @negedge: start_i=1, pixel_i=img[0] -> DUT posedge: T_IDLE captures img_buf[0]
//   @negedge: start_i=0, pixel_i=img[1] -> DUT posedge: T_LOAD(pix_cnt=0) img_buf[1]
//   @negedge: pixel_i=img[j] for j=2..783 -> DUT posedge: T_LOAD pix_cnt=j-1

`timescale 1ns/1ps
`default_nettype none

module tb_cnn_top;

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

    reg [7:0]         cur_img [0:783];
    reg signed [31:0] exp_l   [0:9];
    reg [3:0]         exp_pred;
    integer           pass_count, fail_count, timeout_cnt, j, i, seed;

    initial begin
        $dumpfile("waves.vcd");
        $dumpvars(0, tb_cnn_top);
    end

    initial begin #50000000000; $display("WATCHDOG"); $finish; end

    // run_cur_image: drive pixels onto pixel_i, then wait for done_o
    task run_cur_image;
        begin
            @(negedge clk); start_i = 1'b1; pixel_i = cur_img[0];
            @(negedge clk); start_i = 1'b0; pixel_i = cur_img[1];
            for (j = 2; j <= 783; j = j + 1) begin
                @(negedge clk); pixel_i = cur_img[j];
            end
            // posedge after j=783 negedge: pix_cnt=782->T_CONV1
            timeout_cnt = 0;
            @(posedge clk);
            while (done_o !== 1'b1 && timeout_cnt < 8000000) begin
                @(posedge clk); timeout_cnt = timeout_cnt + 1;
            end
            @(posedge clk);
            if (timeout_cnt >= 8000000) begin
                $display("  TIMEOUT"); fail_count = fail_count + 1;
            end
        end
    endtask

    task check_result;
        input [8*20:1] lbl;
        reg ok;
        begin
            ok = 1'b1;
            if (prediction_o !== exp_pred) begin
                $display("  FAIL [%0s] pred: RTL=%0d exp=%0d",lbl,prediction_o,exp_pred); ok=1'b0; end
            if (logit0!==exp_l[0]) begin $display("  FAIL [%0s] logit[0] RTL=%0d exp=%0d",lbl,logit0,exp_l[0]); ok=1'b0; end
            if (logit1!==exp_l[1]) begin $display("  FAIL [%0s] logit[1] RTL=%0d exp=%0d",lbl,logit1,exp_l[1]); ok=1'b0; end
            if (logit2!==exp_l[2]) begin $display("  FAIL [%0s] logit[2] RTL=%0d exp=%0d",lbl,logit2,exp_l[2]); ok=1'b0; end
            if (logit3!==exp_l[3]) begin $display("  FAIL [%0s] logit[3] RTL=%0d exp=%0d",lbl,logit3,exp_l[3]); ok=1'b0; end
            if (logit4!==exp_l[4]) begin $display("  FAIL [%0s] logit[4] RTL=%0d exp=%0d",lbl,logit4,exp_l[4]); ok=1'b0; end
            if (logit5!==exp_l[5]) begin $display("  FAIL [%0s] logit[5] RTL=%0d exp=%0d",lbl,logit5,exp_l[5]); ok=1'b0; end
            if (logit6!==exp_l[6]) begin $display("  FAIL [%0s] logit[6] RTL=%0d exp=%0d",lbl,logit6,exp_l[6]); ok=1'b0; end
            if (logit7!==exp_l[7]) begin $display("  FAIL [%0s] logit[7] RTL=%0d exp=%0d",lbl,logit7,exp_l[7]); ok=1'b0; end
            if (logit8!==exp_l[8]) begin $display("  FAIL [%0s] logit[8] RTL=%0d exp=%0d",lbl,logit8,exp_l[8]); ok=1'b0; end
            if (logit9!==exp_l[9]) begin $display("  FAIL [%0s] logit[9] RTL=%0d exp=%0d",lbl,logit9,exp_l[9]); ok=1'b0; end
            if (ok) begin
                $display("  PASS [%0s] pred=%0d logits=[%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d]",
                    lbl,prediction_o,logit0,logit1,logit2,logit3,logit4,
                    logit5,logit6,logit7,logit8,logit9);
                pass_count = pass_count + 1;
            end else fail_count = fail_count + 1;
        end
    endtask

    initial begin
        $display("=== QUANTA_2 CNN Testbench ===");
        pass_count = 0; fail_count = 0;
        rst_n = 0; start_i = 0; pixel_i = 0;
        repeat(6) @(posedge clk); rst_n = 1; repeat(4) @(posedge clk);

        // Test 1: all-zero
        $display("--- Test 1: all-zero ---");
        for (i=0; i<784; i=i+1) cur_img[i] = 8'h00;
        exp_l[0]=-32'sd3; exp_l[1]=32'sd5;  exp_l[2]=32'sd4;
        exp_l[3]=-32'sd4; exp_l[4]=-32'sd4; exp_l[5]=32'sd2;
        exp_l[6]=-32'sd6; exp_l[7]=32'sd3;  exp_l[8]=-32'sd7; exp_l[9]=-32'sd3;
        exp_pred = 4'd1;
        run_cur_image; check_result("all_zero");

        // Test 2: all-max (255) -- RTL emulator expected values
        $display("--- Test 2: all-max (255) ---");
        for (i=0; i<784; i=i+1) cur_img[i] = 8'hFF;
        exp_l[0]=-32'sd10; exp_l[1]=-32'sd23; exp_l[2]=-32'sd30;
        exp_l[3]=-32'sd34; exp_l[4]=-32'sd6;  exp_l[5]=-32'sd59;
        exp_l[6]=32'sd5;   exp_l[7]=-32'sd43; exp_l[8]=-32'sd9;  exp_l[9]=-32'sd50;
        exp_pred = 4'd6;
        run_cur_image; check_result("all_max");

        // Test 3: random seed=42
        // mem file img_rnd42.mem was generated by Python random.seed(42)
        // LCG below is NOT Python's Mersenne Twister; load from .mem instead
        $display("--- Test 3: random seed=42 ---");
        $readmemh("../params/img_rnd42.mem", cur_img);
        exp_l[0]=-32'sd19; exp_l[1]=-32'sd42; exp_l[2]=-32'sd11;
        exp_l[3]=-32'sd14; exp_l[4]=-32'sd25; exp_l[5]=-32'sd42;
        exp_l[6]=-32'sd14; exp_l[7]=-32'sd43; exp_l[8]=32'sd7;   exp_l[9]=-32'sd43;
        exp_pred = 4'd8;
        run_cur_image; check_result("rnd42");

        // Test 4: all-127 -- RTL emulator expected values
        $display("--- Test 4: all-127 ---");
        for (i=0; i<784; i=i+1) cur_img[i] = 8'h7F;
        exp_l[0]=-32'sd5;  exp_l[1]=-32'sd10; exp_l[2]=-32'sd16;
        exp_l[3]=-32'sd19; exp_l[4]=-32'sd2;  exp_l[5]=-32'sd31;
        exp_l[6]=32'sd3;   exp_l[7]=-32'sd22; exp_l[8]=-32'sd5;  exp_l[9]=-32'sd26;
        exp_pred = 4'd6;
        run_cur_image; check_result("all_127");

        // Test 5: consecutive all-zero (checks inter-image state reset)
        $display("--- Test 5: consecutive (all-zero 2nd run) ---");
        for (i=0; i<784; i=i+1) cur_img[i] = 8'h00;
        exp_l[0]=-32'sd3; exp_l[1]=32'sd5;  exp_l[2]=32'sd4;
        exp_l[3]=-32'sd4; exp_l[4]=-32'sd4; exp_l[5]=32'sd2;
        exp_l[6]=-32'sd6; exp_l[7]=32'sd3;  exp_l[8]=-32'sd7; exp_l[9]=-32'sd3;
        exp_pred = 4'd1;
        run_cur_image; check_result("all_zero_2nd");

        $display("");
        $display("=== Summary: %0d PASS, %0d FAIL (total %0d tests) ===",
            pass_count, fail_count, pass_count+fail_count);
        if (fail_count == 0) $display("ALL PASS");
        else $display("FAILURES DETECTED");
        #100; $finish;
    end

endmodule

`default_nettype wire
