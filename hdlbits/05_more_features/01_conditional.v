module top_module (
    input [7:0] a, b, c, d,
    output [7:0] min);
    wire [7:0] i, ii;
   
    assign i = (a<b) ? a: b;
    assign ii = (c<d) ? c: d;
    assign min = (i<ii) ? i: ii;

endmodule