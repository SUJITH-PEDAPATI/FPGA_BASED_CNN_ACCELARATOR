// fully_connected.v -- QUANTA_2
// Sequential Linear(800, 10). No saturation, no ReLU on output.
// Output logits written via a write-port interface (addr/data/we)
// to avoid unpacked-array ports (Verilog-2001 compatible).
// Each logit is 32-bit signed.

`timescale 1ns/1ps
`default_nettype none

module fully_connected #(
    parameter integer IN_FEATURES  = 800,
    parameter integer OUT_FEATURES = 10,
    parameter         WEIGHT_FILE  = "fc1_weights_int.mem",
    parameter         BIAS_FILE    = "params/fc_bias_acc.mem",
    parameter integer BIAS_WIDTH   = 12,
    parameter integer RQUANT_MULT  = 1965,
    parameter integer RQUANT_SHIFT = 21
) (
    input  wire clk,
    input  wire rst_n,
    input  wire start_i,

    // Input activation read port
    output reg [$clog2(IN_FEATURES+1)-1:0] in_rd_addr,
    input  wire signed [7:0]                in_rd_data,

    // Output logit write port (32-bit signed, no saturation)
    output reg [3:0]             out_wr_addr,   // 0..9
    output reg signed [31:0]     out_wr_data,
    output reg                   out_wr_en,

    output reg done_o,
    output reg busy_o
);

    localparam integer W_COUNT = OUT_FEATURES * IN_FEATURES;

    reg signed [7:0]            weights [0:W_COUNT-1];
    reg signed [BIAS_WIDTH-1:0] bias_a  [0:OUT_FEATURES-1];

    initial begin
        $readmemh(WEIGHT_FILE, weights);
        $readmemh(BIAS_FILE,   bias_a);
    end

    // FSM
    localparam [1:0] S_IDLE  = 2'd0,
                     S_ACCUM = 2'd1,
                     S_WRITE = 2'd2,
                     S_DONE  = 2'd3;
    reg [1:0] state;

    reg [3:0]                              r_oc;
    reg [$clog2(IN_FEATURES+1)-1:0]        r_i;
    reg signed [31:0]                      acc;

    wire [$clog2(W_COUNT+1)-1:0] widx;
    assign widx = {r_oc, {$clog2(IN_FEATURES){1'b0}}} + r_i;
    // Explicit: widx = r_oc * IN_FEATURES + r_i (use multiply for generality)
    // For Verilog-2001 with parameters, use arithmetic:
    // widx = r_oc * IN_FEATURES + r_i  -- simulator handles this

    wire signed [15:0] mac_term;
    assign mac_term = in_rd_data * $signed(weights[r_oc * IN_FEATURES + r_i]);

    wire last_i;
    assign last_i = (r_i == IN_FEATURES - 1);

    wire signed [31:0] bias_ext;
    assign bias_ext = {{(32-BIAS_WIDTH){bias_a[r_oc][BIAS_WIDTH-1]}}, bias_a[r_oc]};

    // Requantization for logit output (no saturation, no relu)
    // logit = round_away(acc * RQUANT_MULT >> RQUANT_SHIFT)
    localparam integer PROD_W = 49;
    wire signed [PROD_W-1:0] prod_r;
    wire signed [PROD_W-1:0] prod_round;
    wire signed [31:0]        logit_val;
    assign prod_r     = $signed(acc) * $signed({1'b0, RQUANT_MULT[15:0]});
    assign prod_round = prod_r + ($signed({{(PROD_W-1){1'b0}}, 1'b1}) << (RQUANT_SHIFT-1));
    assign logit_val  = $signed(prod_round) >>> RQUANT_SHIFT;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state      <= S_IDLE;
            done_o     <= 1'b0;
            busy_o     <= 1'b0;
            out_wr_en  <= 1'b0;
            r_oc <= 0; r_i <= 0;
            acc        <= 32'sd0;
            in_rd_addr <= 0;
            out_wr_addr<= 0;
            out_wr_data<= 32'sd0;
        end else begin
            done_o    <= 1'b0;
            out_wr_en <= 1'b0;
            case (state)

            S_IDLE: begin
                busy_o <= 1'b0;
                if (start_i) begin
                    r_oc <= 0; r_i <= 0;
                    // bias_ext reads bias_a[r_oc] with OLD r_oc; explicitly load bias_a[0]
                    acc  <= {{(32-BIAS_WIDTH){bias_a[0][BIAS_WIDTH-1]}}, bias_a[0]};
                    in_rd_addr <= 0;
                    state  <= S_ACCUM;
                    busy_o <= 1'b1;
                end
            end

            S_ACCUM: begin
                acc <= acc + mac_term;
                if (last_i) begin
                    state <= S_WRITE;
                end else begin
                    r_i <= r_i + 1;
                    in_rd_addr <= r_i + 1;
                end
            end

            S_WRITE: begin
                out_wr_addr <= r_oc;
                out_wr_data <= logit_val;
                out_wr_en   <= 1'b1;
                if (r_oc == OUT_FEATURES - 1) begin
                    state <= S_DONE;
                end else begin
                    r_oc <= r_oc + 1;
                    r_i  <= 0;
                    acc  <= {{(32-BIAS_WIDTH){bias_a[r_oc+1][BIAS_WIDTH-1]}},
                              bias_a[r_oc+1]};
                    in_rd_addr <= 0;
                    state <= S_ACCUM;
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
