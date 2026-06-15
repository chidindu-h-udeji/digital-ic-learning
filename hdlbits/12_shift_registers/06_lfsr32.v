module top_module(
    input clk,
    input reset,    // Active-high synchronous reset to 32'h1
    output reg [31:0] q
);  
    
    always @ (posedge clk) begin
        if (reset)
            q <= 32'h1;
        else begin
            if (q[0] == 1'b0)
                q <= {1'b0, q[31:1]};
            else if (q[0] == 1'b1)
                q <= {1'b0, q[31:1]} ^ 32'h80200003;
        end
    end

endmodule