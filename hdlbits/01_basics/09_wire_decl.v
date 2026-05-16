`default_nettype none
module top_module(
    input a,
    input b,
    input c,
    input d,
    output out,
    output out_n   ); 
    wire ab,cd;
    assign {ab,cd} = {a&b,c&d};
    assign out = ab|cd;
    assign out_n = ~out;

endmodule
