
`timescale 1ns/1ps
`default_nettype none

module pixel_controller #(
    parameter IMAGE_FILE = "image_input.mem"
)(
    input  wire       clk,
    input  wire       rst_n,
    input  wire       start_request_i,

    output reg        cnn_start_o,
    output wire [7:0] pixel_o,
    input  wire       cnn_load_i,

    output reg        image_active_o
);

    localparam [9:0] LAST_PIXEL = 10'd783;

    reg [7:0] image_mem [0:783];
    reg [9:0] pixel_index;
    reg       start_armed;
    reg       start_pending;

    initial begin
        $readmemh(IMAGE_FILE, image_mem);
    end

    assign pixel_o = image_mem[pixel_index];

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pixel_index     <= 10'd0;
            cnn_start_o     <= 1'b0;
            image_active_o  <= 1'b0;
            start_armed     <= 1'b1;
            start_pending   <= 1'b0;
        end else begin
            cnn_start_o <= 1'b0;

            // Rearm only after the VIO request is released.
            if (!start_request_i)
                start_armed <= 1'b1;

            // Request inference only when the controller is idle.
            if (!image_active_o && !start_pending &&
                start_request_i && start_armed) begin
                pixel_index   <= 10'd0;
                start_pending <= 1'b1;
                start_armed   <= 1'b0;
            end

            // Keep pixel 0 stable until the start pulse is issued.
            if (start_pending) begin
                cnn_start_o    <= 1'b1;
                start_pending  <= 1'b0;
                image_active_o <= 1'b1;
            end else if (image_active_o && cnn_load_i) begin
                if (pixel_index < LAST_PIXEL)
                    pixel_index <= pixel_index + 10'd1;
                else
                    image_active_o <= 1'b0;
            end
        end
    end

endmodule

`default_nettype wire
