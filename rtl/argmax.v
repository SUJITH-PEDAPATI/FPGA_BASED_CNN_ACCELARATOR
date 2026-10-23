`timescale 1ns/1ps
// argmax.v -- QUANTA_2. 10-class signed argmax, lowest index wins ties.
`default_nettype none
module argmax (
    input  wire signed [31:0] logit0,logit1,logit2,logit3,logit4,
    input  wire signed [31:0] logit5,logit6,logit7,logit8,logit9,
    output wire [3:0] prediction
);
    wire signed [31:0] L[0:9];
    assign L[0]=logit0; assign L[1]=logit1; assign L[2]=logit2;
    assign L[3]=logit3; assign L[4]=logit4; assign L[5]=logit5;
    assign L[6]=logit6; assign L[7]=logit7; assign L[8]=logit8;
    assign L[9]=logit9;
    wire signed [31:0] mx[0:9];
    wire [3:0]          id[0:9];
    assign mx[0]=L[0]; assign id[0]=4'd0;
    genvar i;
    generate
        for (i=1;i<10;i=i+1) begin : FOLD
            assign mx[i] = (L[i] > mx[i-1]) ? L[i]    : mx[i-1];
            assign id[i] = (L[i] > mx[i-1]) ? i[3:0]  : id[i-1];
        end
    endgenerate
    assign prediction = id[9];
endmodule
`default_nettype wire