`timescale 1ns/1ps
// quantization.v -- QUANTA_2
// Round-nearest ties-away-zero requantization to signed INT8 [-127,127].
// Operation (combinational):
//   product_round = acc_in * MULT + (1 << (SHIFT-1))
//   shifted       = product_round >>> SHIFT   (arithmetic)
//   sat           = clamp(shifted, -127, 127)
//   q_out         = RELU ? max(sat, 0) : sat
`default_nettype none

module quantization #(
    parameter integer MULT      = 201,
    parameter integer SHIFT     = 18,
    parameter integer ACC_WIDTH = 32,
    parameter integer RELU      = 0
) (
    input  wire signed [ACC_WIDTH-1:0] acc_in,
    output wire signed [7:0]           q_out
);
    localparam integer PROD_W = ACC_WIDTH + 18;

    (* use_dsp = "yes" *) wire signed [PROD_W-1:0] product;
    wire signed [PROD_W-1:0] product_rounded;
    wire signed [PROD_W-1:0] shifted;

    assign product         = $signed(acc_in) * $signed({{1{1'b0}}, MULT[16:0]});
    assign product_rounded = product + ($signed({{(PROD_W-1){1'b0}}, 1'b1}) <<< (SHIFT-1));
    assign shifted         = $signed(product_rounded) >>> SHIFT;

    wire signed [7:0] sat_val;
    assign sat_val = (shifted > $signed({{(PROD_W-8){1'b0}}, 8'd127}))  ?  8'sd127 :
                     (shifted < $signed({{(PROD_W-7){1'b1}}, 7'h01}))   ? -8'sd127 :
                     shifted[7:0];

    assign q_out = (RELU && sat_val[7]) ? 8'sd0 : sat_val;
endmodule

`default_nettype wire