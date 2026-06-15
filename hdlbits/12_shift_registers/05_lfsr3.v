module top_module (
	input [2:0] SW,      // R
	input [1:0] KEY,     // L and clk
	output [2:0] LEDR);  // Q
    
    wire q0,q1,q2;
    assign q0 = LEDR[2];
    assign q1 = LEDR[0];
    assign q2 = LEDR[1] ^ LEDR[2];
    
    muxdff d1 (.clk(KEY[0]),.L(KEY[1]), .Q(LEDR[0]), .r_in(SW[0]), .q_in(q0));
    muxdff d2 (.clk(KEY[0]),.L(KEY[1]), .Q(LEDR[1]), .r_in(SW[1]), .q_in(q1));
    muxdff d3 (.clk(KEY[0]),.L(KEY[1]), .Q(LEDR[2]), .r_in(SW[2]), .q_in(q2));


endmodule

module muxdff (
	input clk,
	input L,
	input r_in,
	input q_in,
    output reg Q);
    always @ (posedge clk) begin
        if (L==0) begin
            Q <= q_in;
        end
        else begin
            Q <= r_in;
        end
    end

endmodule