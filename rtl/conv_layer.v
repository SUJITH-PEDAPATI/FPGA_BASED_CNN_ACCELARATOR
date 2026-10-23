`timescale 1ns/1ps
// conv_layer.v -- QUANTA_2  (Verilog-2001 synthesizable)
// Sequential 3x3 convolution: one MAC per clock.
// Output activations via write-port interface.
//
// FSM: IDLE -> ACCUM -> WRITE -> [next pixel or DONE]
// ACCUM: accumulate 9*IN_CH products for one output pixel.
// WRITE: quantize, write output, reset counters for next pixel.
//
// in_rd_addr is set at end of each ACCUM/WRITE cycle so data is
// valid on the NEXT posedge (one-cycle read latency model).

`default_nettype none

module conv_layer #(
    parameter integer IN_CH        = 1,
    parameter integer IN_H         = 28,
    parameter integer IN_W         = 28,
    parameter integer OUT_CH       = 16,
    parameter         WEIGHT_FILE  = "conv1_weights_int.mem",
    parameter         BIAS_FILE    = "params/conv1_bias_acc.mem",
    parameter integer BIAS_WIDTH   = 20,
    parameter integer RQUANT_MULT  = 201,
    parameter integer RQUANT_SHIFT = 18,
    parameter integer FIRST_LAYER  = 1
) (
    input  wire clk,
    input  wire rst_n,
    input  wire start_i,

    output reg  [$clog2(IN_CH*IN_H*IN_W+1)-1:0] in_rd_addr,
    input  wire [7:0]                             in_rd_data,

    output reg  [$clog2(OUT_CH*(IN_H-2)*(IN_W-2)+1)-1:0] out_wr_addr,
    output reg  signed [7:0]                               out_wr_data,
    output reg                                             out_wr_en,

    output reg done_o,
    output reg busy_o
);

    localparam integer OUT_H   = IN_H - 2;
    localparam integer OUT_W   = IN_W - 2;
    localparam integer W_COUNT = OUT_CH * IN_CH * 9;

    reg signed [7:0]            weights [0:W_COUNT-1];
    reg signed [BIAS_WIDTH-1:0] bias_a  [0:OUT_CH-1];

    initial begin
        $readmemh(WEIGHT_FILE, weights);
        $readmemh(BIAS_FILE,   bias_a);
    end

    localparam [1:0] S_IDLE  = 2'd0,
                     S_ACCUM = 2'd1,
                     S_WRITE = 2'd2,
                     S_DONE  = 2'd3;
    reg [1:0] state;

    reg [$clog2(OUT_CH+1)-1:0] r_oc;
    reg [$clog2(OUT_H+1)-1:0]  r_oy;
    reg [$clog2(OUT_W+1)-1:0]  r_ox;
    reg [$clog2(IN_CH+1)-1:0]  r_ic;
    reg [1:0]                   r_ky;
    reg [1:0]                   r_kx;
    reg signed [31:0]           acc;

    // Weight index: must use registered counters
    wire [$clog2(W_COUNT+1)-1:0] widx;
    assign widx = (r_oc * IN_CH + r_ic) * 9 + r_ky * 3 + r_kx;

    // Input sign/zero extension
    wire signed [8:0]  in_ext;
    assign in_ext = FIRST_LAYER ? {1'b0, in_rd_data} : {in_rd_data[7], in_rd_data};

    wire signed [16:0] mac_term;
    assign mac_term = in_ext * $signed(weights[widx]);

    wire last_tap;
    assign last_tap = (r_ic == IN_CH-1) && (r_ky == 2'd2) && (r_kx == 2'd2);

    // Bias sign extension helper
    wire signed [31:0] bias_cur;
    assign bias_cur = {{(32-BIAS_WIDTH){bias_a[r_oc][BIAS_WIDTH-1]}}, bias_a[r_oc]};

    // Requantization on current acc
    wire signed [7:0] q_out;
    quantization #(
        .MULT(RQUANT_MULT), .SHIFT(RQUANT_SHIFT), .ACC_WIDTH(32), .RELU(1)
    ) u_quant (.acc_in(acc), .q_out(q_out));

    // Next output index (combinational from registered counters)
    wire [$clog2(OUT_CH*(IN_H-2)*(IN_W-2)+1)-1:0] oaddr;
    assign oaddr = (r_oc * OUT_H + r_oy) * OUT_W + r_ox;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state      <= S_IDLE;
            done_o     <= 1'b0; busy_o <= 1'b0; out_wr_en <= 1'b0;
            r_oc<=0; r_oy<=0; r_ox<=0; r_ic<=0; r_ky<=0; r_kx<=0;
            acc        <= 32'sd0;
            in_rd_addr <= 0;
            out_wr_addr<= 0; out_wr_data <= 8'sd0;
        end else begin
            done_o    <= 1'b0;
            out_wr_en <= 1'b0;

            case (state)

            S_IDLE: begin
                busy_o <= 1'b0;
                if (start_i) begin
                    r_oc<=0; r_oy<=0; r_ox<=0; r_ic<=0; r_ky<=2'd0; r_kx<=2'd0;
                    // NOTE: r_oc<=0 is non-blocking; bias_cur still reads OLD r_oc.
                    // Explicitly load bias_a[0] for the first output channel.
                    acc <= {{(32-BIAS_WIDTH){bias_a[0][BIAS_WIDTH-1]}}, bias_a[0]};
                    in_rd_addr <= 0;
                    state  <= S_ACCUM;
                    busy_o <= 1'b1;
                end
            end

            S_ACCUM: begin
                // in_rd_data valid this cycle (addr was set prev cycle)
                acc <= acc + mac_term;

                if (last_tap) begin
                    state <= S_WRITE;
                    // Don't need to update in_rd_addr here; S_WRITE will set for next pixel
                end else begin
                    // Advance tap counters
                    if (r_kx == 2'd2) begin
                        r_kx <= 2'd0;
                        if (r_ky == 2'd2) begin
                            r_ky <= 2'd0;
                            r_ic <= r_ic + 1;
                            // in_rd_addr for next: ic+1, ky=0, kx=0
                            in_rd_addr <= (r_ic+1)*(IN_H*IN_W) + r_oy*IN_W + r_ox;
                        end else begin
                            r_ky <= r_ky + 1;
                            // in_rd_addr for next: same ic, ky+1, kx=0
                            in_rd_addr <= r_ic*(IN_H*IN_W) + (r_oy+r_ky+1)*IN_W + r_ox;
                        end
                    end else begin
                        r_kx <= r_kx + 1;
                        // in_rd_addr for next: same ic,ky, kx+1
                        in_rd_addr <= r_ic*(IN_H*IN_W) + (r_oy+r_ky)*IN_W + (r_ox+r_kx+1);
                    end
                end
            end

            S_WRITE: begin
                // acc has final value; write output
                out_wr_addr <= oaddr;
                out_wr_data <= q_out;
                out_wr_en   <= 1'b1;

                // Advance output counters and reset tap counters
                if (r_ox < OUT_W - 1) begin
                    r_ox <= r_ox + 1;
                    r_ic <= 0; r_ky <= 2'd0; r_kx <= 2'd0;
                    acc  <= bias_cur;
                    // Next pixel: oy same, ox+1, ic=0, ky=0, kx=0
                    in_rd_addr <= r_oy*IN_W + (r_ox+1);
                    state <= S_ACCUM;
                end else if (r_oy < OUT_H - 1) begin
                    r_ox <= 0;
                    r_oy <= r_oy + 1;
                    r_ic <= 0; r_ky <= 2'd0; r_kx <= 2'd0;
                    acc  <= bias_cur;
                    // Next pixel: oy+1, ox=0, ic=0, ky=0, kx=0
                    in_rd_addr <= (r_oy+1)*IN_W;
                    state <= S_ACCUM;
                end else if (r_oc < OUT_CH - 1) begin
                    r_ox <= 0; r_oy <= 0;
                    r_oc <= r_oc + 1;
                    r_ic <= 0; r_ky <= 2'd0; r_kx <= 2'd0;
                    // bias for oc+1 -- use blocking read trick: delay 1 cycle via S_IDLE?
                    // Non-blocking: bias_a[r_oc+1] reads r_oc's OLD value, which is correct
                    acc  <= {{(32-BIAS_WIDTH){bias_a[r_oc+1][BIAS_WIDTH-1]}}, bias_a[r_oc+1]};
                    // Next pixel: oc+1, oy=0, ox=0, ic=0, ky=0, kx=0
                    in_rd_addr <= 0;
                    state <= S_ACCUM;
                end else begin
                    state <= S_DONE;
                end
            end

            S_DONE: begin
                done_o <= 1'b1;
                busy_o <= 1'b0;
                state  <= S_IDLE;
            end

            default: state <= S_IDLE;
            endcase
        end
    end

endmodule

`default_nettype wire