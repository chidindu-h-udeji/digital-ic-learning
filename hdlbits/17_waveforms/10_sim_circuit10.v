module top_module (
    input clk,
    input a,
    input b,
    output q,
    output reg state  );
    
    assign q = ^{a,b,state};
    
    always @ (posedge clk)
        state <= (b&~q) | (a&~q) | (a&b);
    

endmodule