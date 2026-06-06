module top_module (
    input clk,
    input [7:0] in,
    output [7:0] anyedge
);
    reg [7:0] check;
    
    always @ (posedge clk) begin
        check <= in;
        anyedge <= check ^ in;
    end

endmodule