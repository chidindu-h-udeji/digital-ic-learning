module top_module(
    input [31:0] a,
    input [31:0] b,
    input sub,
    output [31:0] sum
);
    wire i;
    wire [31:0] b_xor;
    assign b_xor = b^{32{sub}};
    add16 low (.a(a[15:0]),.b(b_xor[15:0]),.cin(sub),.cout(i),.sum(sum[15:0]));
    add16 up (.a(a[31:16]),.b(b_xor[31:16]),.cin(i),.cout(),.sum(sum[31:16]));

endmodule