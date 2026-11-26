`timescale 1ns/1ps
// maxpool.v -- QUANTA_2. 2x2 signed max-pool window.
`default_nettype none
module maxpool (
    input  wire signed [7:0] a00, a01, a10, a11,
    output wire signed [7:0] y
);
    wire signed [7:0] m0 = (a00 >= a01) ? a00 : a01;
    wire signed [7:0] m1 = (a10 >= a11) ? a10 : a11;
    assign y = (m0 >= m1) ? m0 : m1;
endmodule
`default_nettype wire