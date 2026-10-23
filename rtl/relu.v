`timescale 1ns/1ps
// relu.v -- QUANTA_2. Signed ReLU, parameterised width.
`default_nettype none
module relu #(parameter integer WIDTH = 8) (
    input  wire signed [WIDTH-1:0] in,
    output wire signed [WIDTH-1:0] out
);
    assign out = in[WIDTH-1] ? {WIDTH{1'b0}} : in;
endmodule
`default_nettype wire