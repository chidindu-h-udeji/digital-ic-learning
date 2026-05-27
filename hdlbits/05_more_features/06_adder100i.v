module top_module( 
    input [99:0] a, b,
    input cin,
    output [99:0] cout,
    output [99:0] sum );
    
    genvar i;

generate
    for (i = 0; i < 100; i = i + 1) begin : adder_instances
        if (i == 0) begin
            add100 (.a(a[i]),.b(b[i]),.sum(sum[i]),.cin(cin),.cout(cout[i]));
        end
            else begin
                add100 (.a(a[i]),.b(b[i]),.sum(sum[i]),.cin(cout[i-1]),.cout(cout[i]));
            end
    end
endgenerate

endmodule

module add100(input a, b, cin, output cout, sum);
    assign sum = a^b^cin;
    assign cout = a&b|a&cin|b&cin;
    
endmodule