module top_module( 
    input [399:0] a, b,
    input cin,
    output cout,
    output [399:0] sum );
    wire [99:0] bridge;
    
    genvar i;
    
generate
    for(i=0; i < 100; i = i + 1) begin: adder_instances
        if (i==0) begin
            bcd_fadd (.a(a[(4*i)+3 : 4*i]),.b(b[(4*i)+3 : 4*i]),.sum(sum[(4*i)+3 : 4*i]),.cin(cin),.cout(bridge[0]));
        end
        else begin
            bcd_fadd (.a(a[(4*i)+3 : 4*i]),.b(b[(4*i)+3 : 4*i]),.sum(sum[(4*i)+3 : 4*i]),.cin(bridge[i-1]),.cout(bridge[i]));
        end
    end
endgenerate
    
    assign cout = bridge[99];

endmodule