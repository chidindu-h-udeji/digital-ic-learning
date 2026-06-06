module top_module (
    input clk,
    input d,
    output q
);
    reg pos, neg;
    
    always @ (posedge clk) begin
        pos <= d;
    end
    
    always @ (negedge clk) begin
        neg <= d;
    end
    
    assign q = clk ? pos : neg;
    

endmodule