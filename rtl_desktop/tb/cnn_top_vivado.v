// cnn_top_vivado.v -- QUANTA_2 rtl_desktop copy
// CNN logic preserved; only six memory-file paths updated.
// Project root: E:/FGPA_BASED_CNN_ACCELERATOR_43_09/FPGA_BASED_CNN_ACCELARATOR-main/rtl_desktop
`timescale 1ns/1ps
`default_nettype none

module cnn_top (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       start_i,
    input  wire [7:0] pixel_i,
    output reg        load_o,
    output reg  [9:0] pixel_idx_o,
    output reg        busy_o,
    output reg        done_o,
    output wire [3:0] prediction_o,
    output wire signed [31:0] logit0_o, logit1_o, logit2_o, logit3_o, logit4_o,
    output wire signed [31:0] logit5_o, logit6_o, logit7_o, logit8_o, logit9_o
);

    reg [7:0] img_buf [0:783];
    reg signed [7:0] c1_act [0:10815];
    reg signed [7:0] p1_act [0:2703];
    reg signed [7:0] c2_act [0:3871];
    reg signed [7:0] p2_act [0:799];
    reg signed [31:0] logits [0:9];

    localparam [3:0]
        T_IDLE=4'd0, T_LOAD=4'd1, T_CONV1=4'd2, T_POOL1=4'd3,
        T_CONV2=4'd4, T_POOL2=4'd5, T_FC=4'd6, T_ARGMAX=4'd7, T_DONE=4'd8;
    reg [3:0] state;
    reg [9:0] pix_cnt;

    wire [9:0] c1_in_rd_addr;
    wire [13:0] c1_out_wr_addr;
    wire signed [7:0] c1_out_wr_data;
    wire c1_out_wr_en, c1_done, c1_busy;
    reg c1_start_r;

    conv_layer #(
        .IN_CH(1), .IN_H(28), .IN_W(28), .OUT_CH(16),
        .WEIGHT_FILE("E:/FGPA_BASED_CNN_ACCELERATOR_43_09/FPGA_BASED_CNN_ACCELARATOR-main/rtl_desktop/params/conv1_weights_int.mem"),
        .BIAS_FILE("E:/FGPA_BASED_CNN_ACCELERATOR_43_09/FPGA_BASED_CNN_ACCELARATOR-main/rtl_desktop/params/conv1_bias_acc.mem"),
        .BIAS_WIDTH(20), .RQUANT_MULT(201), .RQUANT_SHIFT(18), .FIRST_LAYER(1)
    ) u_conv1 (
        .clk(clk), .rst_n(rst_n), .start_i(c1_start_r),
        .in_rd_addr(c1_in_rd_addr), .in_rd_data(img_buf[c1_in_rd_addr]),
        .out_wr_addr(c1_out_wr_addr), .out_wr_data(c1_out_wr_data),
        .out_wr_en(c1_out_wr_en), .done_o(c1_done), .busy_o(c1_busy)
    );
    always @(posedge clk)
        if (c1_out_wr_en) c1_act[c1_out_wr_addr] <= c1_out_wr_data;

    wire [11:0] c2_in_rd_addr;
    wire [11:0] c2_out_wr_addr;
    wire signed [7:0] c2_out_wr_data;
    wire c2_out_wr_en, c2_done, c2_busy;
    reg c2_start_r;

    conv_layer #(
        .IN_CH(16), .IN_H(13), .IN_W(13), .OUT_CH(32),
        .WEIGHT_FILE("E:/FGPA_BASED_CNN_ACCELERATOR_43_09/FPGA_BASED_CNN_ACCELARATOR-main/rtl_desktop/params/conv2_weights_int.mem"),
        .BIAS_FILE("E:/FGPA_BASED_CNN_ACCELERATOR_43_09/FPGA_BASED_CNN_ACCELARATOR-main/rtl_desktop/params/conv2_bias_acc.mem"),
        .BIAS_WIDTH(16), .RQUANT_MULT(2637), .RQUANT_SHIFT(21), .FIRST_LAYER(0)
    ) u_conv2 (
        .clk(clk), .rst_n(rst_n), .start_i(c2_start_r),
        .in_rd_addr(c2_in_rd_addr), .in_rd_data(p1_act[c2_in_rd_addr]),
        .out_wr_addr(c2_out_wr_addr), .out_wr_data(c2_out_wr_data),
        .out_wr_en(c2_out_wr_en), .done_o(c2_done), .busy_o(c2_busy)
    );
    always @(posedge clk)
        if (c2_out_wr_en) c2_act[c2_out_wr_addr] <= c2_out_wr_data;

    wire [9:0] fc_in_rd_addr;
    wire [3:0] fc_out_wr_addr;
    wire signed [31:0] fc_out_wr_data;
    wire fc_out_wr_en, fc_done, fc_busy;
    reg fc_start_r;

    fully_connected #(
        .IN_FEATURES(800), .OUT_FEATURES(10),
        .WEIGHT_FILE("E:/FGPA_BASED_CNN_ACCELERATOR_43_09/FPGA_BASED_CNN_ACCELARATOR-main/rtl_desktop/params/fc1_weights_int.mem"),
        .BIAS_FILE("E:/FGPA_BASED_CNN_ACCELERATOR_43_09/FPGA_BASED_CNN_ACCELARATOR-main/rtl_desktop/params/fc_bias_acc.mem"),
        .BIAS_WIDTH(12), .RQUANT_MULT(1965), .RQUANT_SHIFT(21)
    ) u_fc (
        .clk(clk), .rst_n(rst_n), .start_i(fc_start_r),
        .in_rd_addr(fc_in_rd_addr), .in_rd_data(p2_act[fc_in_rd_addr]),
        .out_wr_addr(fc_out_wr_addr), .out_wr_data(fc_out_wr_data),
        .out_wr_en(fc_out_wr_en), .done_o(fc_done), .busy_o(fc_busy)
    );
    always @(posedge clk)
        if (fc_out_wr_en) logits[fc_out_wr_addr] <= fc_out_wr_data;

    wire [3:0] pred_wire;
    argmax u_argmax (
        .logit0(logits[0]), .logit1(logits[1]), .logit2(logits[2]),
        .logit3(logits[3]), .logit4(logits[4]), .logit5(logits[5]),
        .logit6(logits[6]), .logit7(logits[7]), .logit8(logits[8]),
        .logit9(logits[9]), .prediction(pred_wire)
    );
    reg [3:0] pred_r;
    assign prediction_o=pred_r;
    assign logit0_o=logits[0]; assign logit1_o=logits[1];
    assign logit2_o=logits[2]; assign logit3_o=logits[3];
    assign logit4_o=logits[4]; assign logit5_o=logits[5];
    assign logit6_o=logits[6]; assign logit7_o=logits[7];
    assign logit8_o=logits[8]; assign logit9_o=logits[9];

    integer pc, py, px;
    integer b0i, b1i, b2i, b3i, bmi;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state<=T_IDLE;
            done_o<=1'b0; busy_o<=1'b0; load_o<=1'b0;
            pixel_idx_o<=10'd0; pix_cnt<=10'd0;
            c1_start_r<=1'b0; c2_start_r<=1'b0; fc_start_r<=1'b0;
            pred_r<=4'd0;
        end else begin
            done_o<=1'b0;
            c1_start_r<=1'b0; c2_start_r<=1'b0; fc_start_r<=1'b0;
            case (state)
                T_IDLE: begin
                    busy_o<=1'b0; load_o<=1'b0;
                    if (start_i) begin
                        pix_cnt<=10'd0; pixel_idx_o<=10'd0;
                        img_buf[0]<=pixel_i;
                        load_o<=1'b1; busy_o<=1'b1; state<=T_LOAD;
                    end
                end
                T_LOAD: begin
                    if (pix_cnt==10'd782) begin
                        img_buf[783]<=pixel_i;
                        load_o<=1'b0; c1_start_r<=1'b1; state<=T_CONV1;
                    end else begin
                        pix_cnt<=pix_cnt+10'd1;
                        img_buf[pix_cnt+1]<=pixel_i;
                        pixel_idx_o<=pix_cnt+10'd1;
                    end
                end
                T_CONV1: if (c1_done) state<=T_POOL1;
                T_POOL1: begin
                    for (pc=0; pc<16; pc=pc+1)
                        for (py=0; py<13; py=py+1)
                            for (px=0; px<13; px=px+1) begin
                                b0i=$signed(c1_act[(pc*26+py*2)*26+px*2]);
                                b1i=$signed(c1_act[(pc*26+py*2)*26+px*2+1]);
                                b2i=$signed(c1_act[(pc*26+py*2+1)*26+px*2]);
                                b3i=$signed(c1_act[(pc*26+py*2+1)*26+px*2+1]);
                                bmi=b0i;
                                if (b1i>bmi) bmi=b1i;
                                if (b2i>bmi) bmi=b2i;
                                if (b3i>bmi) bmi=b3i;
                                p1_act[(pc*13+py)*13+px]<=bmi[7:0];
                            end
                    c2_start_r<=1'b1; state<=T_CONV2;
                end
                T_CONV2: if (c2_done) state<=T_POOL2;
                T_POOL2: begin
                    for (pc=0; pc<32; pc=pc+1)
                        for (py=0; py<5; py=py+1)
                            for (px=0; px<5; px=px+1) begin
                                b0i=$signed(c2_act[(pc*11+py*2)*11+px*2]);
                                b1i=$signed(c2_act[(pc*11+py*2)*11+px*2+1]);
                                b2i=$signed(c2_act[(pc*11+py*2+1)*11+px*2]);
                                b3i=$signed(c2_act[(pc*11+py*2+1)*11+px*2+1]);
                                bmi=b0i;
                                if (b1i>bmi) bmi=b1i;
                                if (b2i>bmi) bmi=b2i;
                                if (b3i>bmi) bmi=b3i;
                                p2_act[(pc*5+py)*5+px]<=bmi[7:0];
                            end
                    fc_start_r<=1'b1; state<=T_FC;
                end
                T_FC: if (fc_done) state<=T_ARGMAX;
                T_ARGMAX: begin pred_r<=pred_wire; state<=T_DONE; end
                T_DONE: begin done_o<=1'b1; busy_o<=1'b0; state<=T_IDLE; end
                default: state<=T_IDLE;
            endcase
        end
    end
endmodule
`default_nettype wire
