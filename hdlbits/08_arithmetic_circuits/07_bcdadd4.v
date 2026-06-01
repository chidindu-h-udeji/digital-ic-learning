module top_module ( 
    input [15:0] a, b,
    input cin,
    output cout,
    output [15:0] sum );
    wire [3:0] bridge;
    
    genvar i;
    
generate
    for (i = 0; i < 4; i = i + 1) begin: adder_instances
        if (i==0) begin
            bcd_fadd adder (.a(a[i*4 +: 4]),.b(b[i*4 +: 4]),.cin(cin),.sum(sum[i*4 +: 4]),.cout(bridge[i]));
        end
        else begin
            bcd_fadd adder (.a(a[i*4 +: 4]),.b(b[i*4 +: 4]),.cin(bridge[i-1]),.sum(sum[i*4 +: 4]),.cout(bridge[i]));
        end
    end
endgenerate
        
    assign cout = bridge[3];
            
            
endmodule