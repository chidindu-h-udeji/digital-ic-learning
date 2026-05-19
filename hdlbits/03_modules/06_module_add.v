module top_module(
    input [31:0] a,
    input [31:0] b,
    output [31:0] sum
);
    wire i;
    add16 low (.a(a[15:0]),.b(b[15:0]),.sum(sum[15:0]),.cin(1'b0),.cout(i));
    add16 up (.a(a[31:16]),.b(b[31:16]),.sum(sum[31:16]),.cin(i),.cout());

endmodule