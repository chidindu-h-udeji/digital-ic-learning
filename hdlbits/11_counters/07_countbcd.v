module top_module (
    input clk,
    input reset,   // Synchronous active-high reset
    output [3:1] ena,
    output [15:0] q);
    
    assign ena[1] = (q[3:0]==9);
    assign ena[2] = (q[3:0]==9) & (q[7:4]==9);
    assign ena[3] = (q[3:0]==9) & (q[7:4]==9) & (q[11:8]==9);
    
    bcdcount4 counter0 (.clk(clk), .reset(reset), .enable(1'b1), .q(q[3:0]));
    bcdcount4 counter1 (.clk(clk), .reset(reset), .enable(ena[1]), .q(q[7:4]));
    bcdcount4 counter2 (.clk(clk), .reset(reset), .enable(ena[2]), .q(q[11:8]));
    bcdcount4 counter3 (.clk(clk), .reset(reset), .enable(ena[3]), .q(q[15:12]));

endmodule

module bcdcount4 (
    input clk,
    input reset,
    input enable,
    output reg [3:0] q);
    
    always @ (posedge clk) begin
        if (reset) begin
            q <= 4'd0;
        end
        else if (enable) begin
            if (q == 9) begin
            q <= 4'd0;
            end
            else begin
            q <= q + 1;
            end
        end
    end

endmodule