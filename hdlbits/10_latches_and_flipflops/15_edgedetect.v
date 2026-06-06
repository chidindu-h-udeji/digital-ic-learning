module top_module (
    input clk,
    input [7:0] in,
    output reg [7:0] pedge
);
    reg [7:0] check;
    
    always @ (posedge clk) begin
        check <= in;
        pedge <= ~check & in;
    end

endmodule