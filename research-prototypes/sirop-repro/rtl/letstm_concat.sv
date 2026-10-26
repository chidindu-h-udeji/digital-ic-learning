// letstm_concat.sv - letstm[K] x = s in StmConcat(x, x) (Sec. 3 example).
// The paper states this gets stuck for K = 1 and works for K = n.
module letstm_concat #(parameter int W = 16, parameter int N = 4, parameter int K = 1) (
    input  logic         clk,
    input  logic         rst,
    input  logic [W-1:0] s_data,
    input  logic         s_valid,
    output logic         s_ready,
    output logic [W-1:0] out_data,
    output logic         out_valid,
    input  logic         out_ready
);
    logic [W-1:0] x0_data, x1_data;
    logic x0_valid, x0_ready, x1_valid, x1_ready;

    letstm2 #(.W(W), .K(K)) u_buf (
        .clk(clk), .rst(rst),
        .in_data(s_data), .in_valid(s_valid), .in_ready(s_ready),
        .c0_data(x0_data), .c0_valid(x0_valid), .c0_ready(x0_ready),
        .c1_data(x1_data), .c1_valid(x1_valid), .c1_ready(x1_ready)
    );

    sb_concat #(.W(W), .N(N)) u_concat (
        .clk(clk), .rst(rst),
        .p0_data(x0_data), .p0_valid(x0_valid), .p0_ready(x0_ready),
        .p1_data(x1_data), .p1_valid(x1_valid), .p1_ready(x1_ready),
        .out_data(out_data), .out_valid(out_valid), .out_ready(out_ready)
    );
endmodule