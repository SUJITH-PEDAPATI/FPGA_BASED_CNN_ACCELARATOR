// tb_system_digit1.v -- System-level testbench connecting pixel_controller to cnn_top for Digit 1
`timescale 1ns/1ps
`default_nettype none

module tb_system_digit1;

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

    // Instantiate pixel_controller with Digit 1
    pixel_controller #(
        .IMAGE_FILE("F:/QUANTA_2/testfor1/test/image_input_1.mem")
    ) u_controller (
        .clk             (clk),
        .rst_n           (rst_n),
        .start_request_i (start_request_i),
        .cnn_start_o     (cnn_start),
        .pixel_o         (pixel_bus),
        .cnn_load_i      (cnn_load),
        .image_active_o  (image_active)
    );

    // Instantiate complete cnn_top
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

    localparam GT_LABEL = 4'd1;
    integer cycles;

    `ifdef DUMP_VCD
    initial begin
        $dumpfile("F:/QUANTA_2/testfor1/success_test_for_digit_1/waveforms/tb_system_digit1.vcd");
        $dumpvars(0, tb_system_digit1);
    end
    `endif

    initial begin
        clk = 0;
        rst_n = 0;
        start_request_i = 0;

        $display("=== System Testbench: Digit 1 (image_input_1.mem) ===");
        repeat(10) @(posedge clk);
        rst_n = 1;
        repeat(5) @(posedge clk);

        $display("Triggering start_request_i pulse...");
        @(posedge clk);
        start_request_i = 1;
        @(posedge clk);
        start_request_i = 0;

        cycles = 0;
        while (!done && cycles < 800000) begin
            @(posedge clk);
            cycles = cycles + 1;
        end

        if (done) begin
            $display("=== System Inference Complete ===");
            $display("Cycles elapsed: %0d", cycles);
            $display("Prediction: %0d", prediction);
            $display("Ground Truth: %0d", GT_LABEL);
            if (prediction == GT_LABEL)
                $display("SYSTEM TEST RESULT: PASS (Prediction matches Digit 1)");
            else
                $display("SYSTEM TEST RESULT: FAIL");
        end else begin
            $display("SYSTEM TEST RESULT: TIMEOUT");
        end

        #100;
        $finish;
    end

endmodule

`default_nettype wire

