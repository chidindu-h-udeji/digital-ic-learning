module top_module (
    input in1,
    input in2,
    input in3,
    output out);
    wire i;
    assign i = ~(in1^in2);
    assign out = i^in3;
    

endmodule