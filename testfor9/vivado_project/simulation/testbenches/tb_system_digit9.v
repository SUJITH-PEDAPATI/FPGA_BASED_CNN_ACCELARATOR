// tb_system_digit3.v -- System-level testbench connecting pixel_controller to cnn_top
// Verifies that the fixed pixel_controller correctly streams Digit 9 into cnn_top and predicts 3.

`timescale 1ns/1ps
`default_nettype none

module tb_system_digit9;

    reg clk;
    reg rst_n;
    reg start_request_i;

    wire        cnn_start;
    wire [7:0]  pixel_bus;
    wire        cnn_load;
    wire        image_active;

    wire [9:0]  pixel_idx;
    wire        busy;
    wire        done;
    wire [3:0]  prediction;

    // Clock: 10 ns, 100 MHz
    initial clk = 1'b0;
    always #5 clk = ~clk;

    // Instantiate fixed pixel_controller with Digit 9
    pixel_controller #(
        .IMAGE_FILE("F:/QUANTA_2/testfor9/test/image_input_9.mem")
    ) u_controller (
        .clk             (clk),
        .rst_n           (rst_n),
        .start_request_i (start_request_i),
        .cnn_start_o     (cnn_start),
        .pixel_o         (pixel_bus),
        .cnn_load_i      (cnn_load),
        .image_active_o  (image_active)
    );

    // Instantiate cnn_top
    cnn_top u_cnn (
        .clk          (clk),
        .rst_n        (rst_n),
        .start_i      (cnn_start),
        .pixel_i      (pixel_bus),
        .load_o       (cnn_load),
        .pixel_idx_o  (pixel_idx),
        .busy_o       (busy),
        .done_o       (done),
        .prediction_o (prediction)
    );

    integer timeout_cnt;

    // Watchdog
    `ifdef DUMP_VCD
    initial begin
        $dumpfile("F:/QUANTA_2/testfor9/success_test_3/waveforms/tb_system_digit9.vcd");
        $dumpvars(0, tb_system_digit9);
    end
`endif

    initial begin
        #10000000; // 10 ms
        $display("ERROR: Watchdog timeout -- inference did not complete.");
        $finish;
    end

    initial begin
        clk             = 1'b0;
        rst_n           = 1'b0;
        start_request_i = 1'b0;

        $display("================================================================================");
        $display("QUANTA_2: System-Level Simulation (pixel_controller + cnn_top for Digit 9)");
        $display("================================================================================");

        repeat(5) @(posedge clk);
        rst_n = 1'b1;
        $display("Reset released.");
        repeat(5) @(posedge clk);

        $display("Asserting start_request_i via VIO emulation...");
        @(negedge clk);
        start_request_i = 1'b1;
        @(negedge clk);
        start_request_i = 1'b0;

        // Verify pixel ingestion
        wait(u_cnn.state == 5'd1); // T_LOAD
        $display("CNN entered T_LOAD. First pixel stored: 0x%02h (Expected from image: 0x%02h)",
                 u_cnn.img_buf[0], u_controller.image_mem[0]);

        wait(done == 1'b1);
        $display("");
        $display("=== Inference Complete (done_o asserted) ===");
        $display("  DUT Prediction       : %0d", prediction);
        $display("  Ground Truth Label   : 9");
        $display("  Logit 0 = %4d", u_cnn.logits[0]);
        $display("  Logit 1 = %4d", u_cnn.logits[1]);
        $display("  Logit 2 = %4d", u_cnn.logits[2]);
        $display("  Logit 3 = %4d (Digit 9 Winner!)", u_cnn.logits[3]);
        $display("  Logit 4 = %4d", u_cnn.logits[4]);
        $display("  Logit 5 = %4d", u_cnn.logits[5]);
        $display("  Logit 6 = %4d", u_cnn.logits[6]);
        $display("  Logit 7 = %4d", u_cnn.logits[7]);
        $display("  Logit 8 = %4d", u_cnn.logits[8]);
        $display("  Logit 9 = %4d (Digit 9 Winner!)", u_cnn.logits[9]);

        if (prediction === 4'd9) begin
            $display("");
            $display(">>> SUCCESS: Fixed pixel_controller produced Digit 9 in cnn_top! <<<");
        end else begin
            $display("");
            $display(">>> FAILED: Prediction was %0d, expected 9 <<<", prediction);
        end
        $display("================================================================================");

        #100;
        $finish;
    end

endmodule
`default_nettype wire

