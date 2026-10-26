
`timescale 1ns/1ps
`default_nettype none

module cnn_top (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       start_i,
    input  wire [7:0] pixel_i,

    output reg        load_o,
    output reg [9:0]  pixel_idx_o,
    output reg        busy_o,
    output reg        done_o,

    output wire [3:0] prediction_o,
    output wire signed [31:0] logit0_o, logit1_o, logit2_o,
    output wire signed [31:0] logit3_o, logit4_o, logit5_o,
    output wire signed [31:0] logit6_o, logit7_o, logit8_o,
    output wire signed [31:0] logit9_o
);

    // ---------------------------------------------------------
    // Activation memories
    // ---------------------------------------------------------
    reg [7:0]        img_buf [0:783];
    reg signed [7:0] c1_act  [0:10815];
    reg signed [7:0] p1_act  [0:2703];
    reg signed [7:0] c2_act  [0:3871];
    reg signed [7:0] p2_act  [0:799];
    reg signed [31:0] logits [0:9];

    // ---------------------------------------------------------
    // Main FSM
    // ---------------------------------------------------------
    localparam [4:0]
        T_IDLE        = 5'd0,
        T_LOAD        = 5'd1,
        T_CONV1       = 5'd2,

        T_POOL1_R0    = 5'd3,
        T_POOL1_R1    = 5'd4,
        T_POOL1_R2    = 5'd5,
        T_POOL1_R3    = 5'd6,
        T_POOL1_WRITE = 5'd7,

        T_CONV2       = 5'd8,

        T_POOL2_R0    = 5'd9,
        T_POOL2_R1    = 5'd10,
        T_POOL2_R2    = 5'd11,
        T_POOL2_R3    = 5'd12,
        T_POOL2_WRITE = 5'd13,

        T_FC          = 5'd14,
        T_ARGMAX      = 5'd15,
        T_DONE        = 5'd16;

    reg [4:0] state;
    reg [9:0] pix_cnt;

    // Pool 1: 16 channels, 13 rows, 13 columns
    reg [3:0] pool1_ch;
    reg [3:0] pool1_y;
    reg [3:0] pool1_x;

    reg signed [7:0] pool1_v0;
    reg signed [7:0] pool1_v1;
    reg signed [7:0] pool1_v2;
    reg signed [7:0] pool1_v3;
    reg signed [7:0] pool1_max;

    // Pool 2: 32 channels, 5 rows, 5 columns
    reg [4:0] pool2_ch;
    reg [2:0] pool2_y;
    reg [2:0] pool2_x;

    reg signed [7:0] pool2_v0;
    reg signed [7:0] pool2_v1;
    reg signed [7:0] pool2_v2;
    reg signed [7:0] pool2_v3;
    reg signed [7:0] pool2_max;

    // ---------------------------------------------------------
    // Conv1
    // ---------------------------------------------------------
    wire [9:0]         c1_in_rd_addr;
    wire [13:0]        c1_out_wr_addr;
    wire signed [7:0]  c1_out_wr_data;
    wire               c1_out_wr_en;
    wire               c1_done, c1_busy;
    reg                c1_start_r;

    conv_layer #(
        .IN_CH(1),
        .IN_H(28),
        .IN_W(28),
        .OUT_CH(16),
        .WEIGHT_FILE("E:/FGPA_BASED_CNN_ACCELERATOR_43_09/FPGA_BASED_CNN_ACCELARATOR-main/rtl_desktop/params/conv1_weights_int.mem"),
        .BIAS_FILE("E:/FGPA_BASED_CNN_ACCELERATOR_43_09/FPGA_BASED_CNN_ACCELARATOR-main/rtl_desktop/params/conv1_bias_int.mem"),
        .BIAS_WIDTH(20),
        .RQUANT_MULT(201),
        .RQUANT_SHIFT(18),
        .FIRST_LAYER(1)
    ) u_conv1 (
        .clk(clk),
        .rst_n(rst_n),
        .start_i(c1_start_r),
        .in_rd_addr(c1_in_rd_addr),
        .in_rd_data(img_buf[c1_in_rd_addr]),
        .out_wr_addr(c1_out_wr_addr),
        .out_wr_data(c1_out_wr_data),
        .out_wr_en(c1_out_wr_en),
        .done_o(c1_done),
        .busy_o(c1_busy)
    );

    always @(posedge clk) begin
        if (c1_out_wr_en)
            c1_act[c1_out_wr_addr] <= c1_out_wr_data;
    end

    // ---------------------------------------------------------
    // Conv2
    // ---------------------------------------------------------
    wire [11:0]        c2_in_rd_addr;
    wire [11:0]        c2_out_wr_addr;
    wire signed [7:0]  c2_out_wr_data;
    wire               c2_out_wr_en;
    wire               c2_done, c2_busy;
    reg                c2_start_r;

    conv_layer #(
        .IN_CH(16),
        .IN_H(13),
        .IN_W(13),
        .OUT_CH(32),
        .WEIGHT_FILE("E:/FGPA_BASED_CNN_ACCELERATOR_43_09/FPGA_BASED_CNN_ACCELARATOR-main/rtl_desktop/params/conv2_weights_int.mem"),
        .BIAS_FILE("E:/FGPA_BASED_CNN_ACCELERATOR_43_09/FPGA_BASED_CNN_ACCELARATOR-main/rtl_desktop/params/conv2_bias_int.mem"),
        .BIAS_WIDTH(16),
        .RQUANT_MULT(2637),
        .RQUANT_SHIFT(21),
        .FIRST_LAYER(0)
    ) u_conv2 (
        .clk(clk),
        .rst_n(rst_n),
        .start_i(c2_start_r),
        .in_rd_addr(c2_in_rd_addr),
        .in_rd_data(p1_act[c2_in_rd_addr]),
        .out_wr_addr(c2_out_wr_addr),
        .out_wr_data(c2_out_wr_data),
        .out_wr_en(c2_out_wr_en),
        .done_o(c2_done),
        .busy_o(c2_busy)
    );

    always @(posedge clk) begin
        if (c2_out_wr_en)
            c2_act[c2_out_wr_addr] <= c2_out_wr_data;
    end

    // ---------------------------------------------------------
    // Fully connected
    // ---------------------------------------------------------
    wire [9:0]          fc_in_rd_addr;
    wire [3:0]          fc_out_wr_addr;
    wire signed [31:0]  fc_out_wr_data;
    wire                fc_out_wr_en;
    wire                fc_done, fc_busy;
    reg                 fc_start_r;

    fully_connected #(
        .IN_FEATURES(800),
        .OUT_FEATURES(10),
        .WEIGHT_FILE("E:/FGPA_BASED_CNN_ACCELERATOR_43_09/FPGA_BASED_CNN_ACCELARATOR-main/rtl_desktop/params/fc1_weights_int.mem"),
        .BIAS_FILE("E:/FGPA_BASED_CNN_ACCELERATOR_43_09/FPGA_BASED_CNN_ACCELARATOR-main/rtl_desktop/params/fc1_bias_int.mem"),
        .BIAS_WIDTH(12),
        .RQUANT_MULT(1965),
        .RQUANT_SHIFT(21)
    ) u_fc (
        .clk(clk),
        .rst_n(rst_n),
        .start_i(fc_start_r),
        .in_rd_addr(fc_in_rd_addr),
        .in_rd_data(p2_act[fc_in_rd_addr]),
        .out_wr_addr(fc_out_wr_addr),
        .out_wr_data(fc_out_wr_data),
        .out_wr_en(fc_out_wr_en),
        .done_o(fc_done),
        .busy_o(fc_busy)
    );

    always @(posedge clk) begin
        if (fc_out_wr_en)
            logits[fc_out_wr_addr] <= fc_out_wr_data;
    end

    // ---------------------------------------------------------
    // Argmax and outputs
    // ---------------------------------------------------------
    wire [3:0] pred_wire;
    reg [3:0] pred_r;

    argmax u_argmax (
        .logit0(logits[0]),
        .logit1(logits[1]),
        .logit2(logits[2]),
        .logit3(logits[3]),
        .logit4(logits[4]),
        .logit5(logits[5]),
        .logit6(logits[6]),
        .logit7(logits[7]),
        .logit8(logits[8]),
        .logit9(logits[9]),
        .prediction(pred_wire)
    );

    assign prediction_o = pred_r;

    assign logit0_o = logits[0];
    assign logit1_o = logits[1];
    assign logit2_o = logits[2];
    assign logit3_o = logits[3];
    assign logit4_o = logits[4];
    assign logit5_o = logits[5];
    assign logit6_o = logits[6];
    assign logit7_o = logits[7];
    assign logit8_o = logits[8];
    assign logit9_o = logits[9];

    // ---------------------------------------------------------
    // Main control FSM
    // ---------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state       <= T_IDLE;
            done_o      <= 1'b0;
            busy_o      <= 1'b0;
            load_o      <= 1'b0;
            pixel_idx_o <= 10'd0;
            pix_cnt     <= 10'd0;

            c1_start_r  <= 1'b0;
            c2_start_r  <= 1'b0;
            fc_start_r  <= 1'b0;
            pred_r      <= 4'd0;

            pool1_ch    <= 4'd0;
            pool1_y     <= 4'd0;
            pool1_x     <= 4'd0;
            pool1_v0    <= 8'sd0;
            pool1_v1    <= 8'sd0;
            pool1_v2    <= 8'sd0;
            pool1_v3    <= 8'sd0;
            pool1_max   <= 8'sd0;

            pool2_ch    <= 5'd0;
            pool2_y     <= 3'd0;
            pool2_x     <= 3'd0;
            pool2_v0    <= 8'sd0;
            pool2_v1    <= 8'sd0;
            pool2_v2    <= 8'sd0;
            pool2_v3    <= 8'sd0;
            pool2_max   <= 8'sd0;

        end else begin
            done_o     <= 1'b0;
            c1_start_r <= 1'b0;
            c2_start_r <= 1'b0;
            fc_start_r <= 1'b0;

            case (state)

                // ---------------------------------------------
                // Load 784 input pixels
                // ---------------------------------------------
                T_IDLE: begin
                    busy_o <= 1'b0;
                    load_o <= 1'b0;

                    if (start_i) begin
                        pix_cnt     <= 10'd0;
                        pixel_idx_o <= 10'd0;
                        img_buf[0]  <= pixel_i;
                        load_o      <= 1'b1;
                        busy_o      <= 1'b1;
                        state       <= T_LOAD;
                    end
                end

                T_LOAD: begin
                    if (pix_cnt == 10'd782) begin
                        img_buf[783] <= pixel_i;
                        load_o       <= 1'b0;
                        c1_start_r   <= 1'b1;
                        state        <= T_CONV1;
                    end else begin
                        pix_cnt            <= pix_cnt + 10'd1;
                        img_buf[pix_cnt+1] <= pixel_i;
                        pixel_idx_o        <= pix_cnt + 10'd1;
                    end
                end

                // ---------------------------------------------
                // Wait for Conv1 completion
                // ---------------------------------------------
                T_CONV1: begin
                    if (c1_done) begin
                        pool1_ch <= 4'd0;
                        pool1_y  <= 4'd0;
                        pool1_x  <= 4'd0;
                        state    <= T_POOL1_R0;
                    end
                end

                // ---------------------------------------------
                // Pool1: four separate synchronous read cycles
                // ---------------------------------------------
                T_POOL1_R0: begin
                    pool1_v0 <= c1_act[
                        (pool1_ch * 26 + pool1_y * 2) * 26
                        + pool1_x * 2
                    ];
                    state <= T_POOL1_R1;
                end

                T_POOL1_R1: begin
                    pool1_v1 <= c1_act[
                        (pool1_ch * 26 + pool1_y * 2) * 26
                        + pool1_x * 2 + 1
                    ];
                    state <= T_POOL1_R2;
                end

                T_POOL1_R2: begin
                    pool1_v2 <= c1_act[
                        (pool1_ch * 26 + pool1_y * 2 + 1) * 26
                        + pool1_x * 2
                    ];
                    state <= T_POOL1_R3;
                end

                T_POOL1_R3: begin
                    pool1_v3 <= c1_act[
                        (pool1_ch * 26 + pool1_y * 2 + 1) * 26
                        + pool1_x * 2 + 1
                    ];
                    state <= T_POOL1_WRITE;
                end

                T_POOL1_WRITE: begin
                    // Signed max of the four stored activations.
                    pool1_max = pool1_v0;
                    if (pool1_v1 > pool1_max)
                        pool1_max = pool1_v1;
                    if (pool1_v2 > pool1_max)
                        pool1_max = pool1_v2;
                    if (pool1_v3 > pool1_max)
                        pool1_max = pool1_v3;

                    p1_act[(pool1_ch * 13 + pool1_y) * 13 + pool1_x]
                        <= pool1_max;

                    if (pool1_x == 4'd12) begin
                        pool1_x <= 4'd0;

                        if (pool1_y == 4'd12) begin
                            pool1_y <= 4'd0;

                            if (pool1_ch == 4'd15) begin
                                c2_start_r <= 1'b1;
                                state      <= T_CONV2;
                            end else begin
                                pool1_ch <= pool1_ch + 4'd1;
                                state     <= T_POOL1_R0;
                            end
                        end else begin
                            pool1_y <= pool1_y + 4'd1;
                            state   <= T_POOL1_R0;
                        end
                    end else begin
                        pool1_x <= pool1_x + 4'd1;
                        state   <= T_POOL1_R0;
                    end
                end

                // ---------------------------------------------
                // Wait for Conv2 completion
                // ---------------------------------------------
                T_CONV2: begin
                    if (c2_done) begin
                        pool2_ch <= 5'd0;
                        pool2_y  <= 3'd0;
                        pool2_x  <= 3'd0;
                        state    <= T_POOL2_R0;
                    end
                end

                // ---------------------------------------------
                // Pool2: four separate synchronous read cycles
                // ---------------------------------------------
                T_POOL2_R0: begin
                    pool2_v0 <= c2_act[
                        (pool2_ch * 11 + pool2_y * 2) * 11
                        + pool2_x * 2
                    ];
                    state <= T_POOL2_R1;
                end

                T_POOL2_R1: begin
                    pool2_v1 <= c2_act[
                        (pool2_ch * 11 + pool2_y * 2) * 11
                        + pool2_x * 2 + 1
                    ];
                    state <= T_POOL2_R2;
                end

                T_POOL2_R2: begin
                    pool2_v2 <= c2_act[
                        (pool2_ch * 11 + pool2_y * 2 + 1) * 11
                        + pool2_x * 2
                    ];
                    state <= T_POOL2_R3;
                end

                T_POOL2_R3: begin
                    pool2_v3 <= c2_act[
                        (pool2_ch * 11 + pool2_y * 2 + 1) * 11
                        + pool2_x * 2 + 1
                    ];
                    state <= T_POOL2_WRITE;
                end

                T_POOL2_WRITE: begin
                    pool2_max = pool2_v0;
                    if (pool2_v1 > pool2_max)
                        pool2_max = pool2_v1;
                    if (pool2_v2 > pool2_max)
                        pool2_max = pool2_v2;
                    if (pool2_v3 > pool2_max)
                        pool2_max = pool2_v3;

                    p2_act[(pool2_ch * 5 + pool2_y) * 5 + pool2_x]
                        <= pool2_max;

                    if (pool2_x == 3'd4) begin
                        pool2_x <= 3'd0;

                        if (pool2_y == 3'd4) begin
                            pool2_y <= 3'd0;

                            if (pool2_ch == 5'd31) begin
                                fc_start_r <= 1'b1;
                                state      <= T_FC;
                            end else begin
                                pool2_ch <= pool2_ch + 5'd1;
                                state     <= T_POOL2_R0;
                            end
                        end else begin
                            pool2_y <= pool2_y + 3'd1;
                            state   <= T_POOL2_R0;
                        end
                    end else begin
                        pool2_x <= pool2_x + 3'd1;
                        state   <= T_POOL2_R0;
                    end
                end

                // ---------------------------------------------
                // Fully connected and argmax
                // ---------------------------------------------
                T_FC: begin
                    if (fc_done)
                        state <= T_ARGMAX;
                end

                T_ARGMAX: begin
                    pred_r <= pred_wire;
                    state  <= T_DONE;
                end

                T_DONE: begin
                    done_o <= 1'b1;
                    busy_o <= 1'b0;
                    state  <= T_IDLE;
                end

                default: begin
                    state <= T_IDLE;
                end
            endcase
        end
    end

endmodule

`default_nettype wire
