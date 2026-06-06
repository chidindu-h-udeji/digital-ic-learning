module top_module (
    input clk,
    input reset,
    input [31:0] in,
    output reg [31:0] out
);
    reg [31:0] check;
    
    always @ (posedge clk) begin
        check <= in;
        if (reset) begin
            out <= 32'b0;
        end
        else begin
            out <= out | (check & ~in);
        end
    end

endmodule
