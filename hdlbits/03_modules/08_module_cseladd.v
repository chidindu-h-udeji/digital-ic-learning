module top_module(
    input [31:0] a,
    input [31:0] b,
    output [31:0] sum
);
    wire i;
    wire [15:0] jump1,jump2;
    add16 low (.a(a[15:0]),.b(b[15:0]),.sum(sum[15:0]),.cin(1'b0),.cout(i));
    add16 up0 (.a(a[31:16]),.b(b[31:16]),.sum(jump1),.cin(1'b0),.cout());
    add16 up1 (.a(a[31:16]),.b(b[31:16]),.sum(jump2),.cin(1'b1),.cout());
    assign sum[31:16] = i ? jump2 : jump1;

endmodule