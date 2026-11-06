`timescale 1ns/1ps
// argmax.v -- QUANTA_2. 10-class signed argmax, lowest index wins ties.
// Balanced binary comparison tree (4 comparator levels instead of 9 serial ripples).
`default_nettype none
module argmax (
    input  wire                   clk,
    input  wire signed [31:0]     logit0,logit1,logit2,logit3,logit4,
    input  wire signed [31:0]     logit5,logit6,logit7,logit8,logit9,
    output wire [3:0]             prediction
);
    wire signed [31:0] L[0:9];
    assign L[0]=logit0; assign L[1]=logit1; assign L[2]=logit2;
    assign L[3]=logit3; assign L[4]=logit4; assign L[5]=logit5;
    assign L[6]=logit6; assign L[7]=logit7; assign L[8]=logit8;
    assign L[9]=logit9;

    // Level 1: 5 parallel 32-bit signed comparisons
    wire signed [31:0] m1_0 = (L[1] > L[0]) ? L[1] : L[0];
    wire [3:0]         id1_0 = (L[1] > L[0]) ? 4'd1 : 4'd0;

    wire signed [31:0] m1_1 = (L[3] > L[2]) ? L[3] : L[2];
    wire [3:0]         id1_1 = (L[3] > L[2]) ? 4'd3 : 4'd2;

    wire signed [31:0] m1_2 = (L[5] > L[4]) ? L[5] : L[4];
    wire [3:0]         id1_2 = (L[5] > L[4]) ? 4'd5 : 4'd4;

    wire signed [31:0] m1_3 = (L[7] > L[6]) ? L[7] : L[6];
    wire [3:0]         id1_3 = (L[7] > L[6]) ? 4'd7 : 4'd6;

    wire signed [31:0] m1_4 = (L[9] > L[8]) ? L[9] : L[8];
    wire [3:0]         id1_4 = (L[9] > L[8]) ? 4'd9 : 4'd8;

    // Level 2: 2 parallel comparisons + 1 pass-through
    wire signed [31:0] m2_0 = (m1_1 > m1_0) ? m1_1 : m1_0;
    wire [3:0]         id2_0 = (m1_1 > m1_0) ? id1_1 : id1_0;

    wire signed [31:0] m2_1 = (m1_3 > m1_2) ? m1_3 : m1_2;
    wire [3:0]         id2_1 = (m1_3 > m1_2) ? id1_3 : id1_2;

    wire signed [31:0] m2_2 = m1_4;
    wire [3:0]         id2_2 = id1_4;

    // Pipeline register between Level 2 and Level 3 to break 13.1 ns path into two 6.5 ns stages
    reg signed [31:0] r_m2_0, r_m2_1, r_m2_2;
    reg [3:0]         r_id2_0, r_id2_1, r_id2_2;

    always @(posedge clk) begin
        r_m2_0  <= m2_0;
        r_id2_0 <= id2_0;
        r_m2_1  <= m2_1;
        r_id2_1 <= id2_1;
        r_m2_2  <= m2_2;
        r_id2_2 <= id2_2;
    end

    // Level 3: 1 comparison + 1 pass-through
    wire signed [31:0] m3_0 = (r_m2_1 > r_m2_0) ? r_m2_1 : r_m2_0;
    wire [3:0]         id3_0 = (r_m2_1 > r_m2_0) ? r_id2_1 : r_id2_0;

    wire signed [31:0] m3_1 = r_m2_2;
    wire [3:0]         id3_1 = r_id2_2;

    // Level 4: Final comparison
    wire [3:0]         id_final = (m3_1 > m3_0) ? id3_1 : id3_0;

    assign prediction = id_final;
endmodule
`default_nettype wire