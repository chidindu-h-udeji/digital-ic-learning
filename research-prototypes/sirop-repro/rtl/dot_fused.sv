// dot_fused.sv - Fig. 7 dot product after zip+map fusion (Fig. 14, right):
// I0, I1 -> zipmap -> reduce -> out. Same ports as dot_unfused.
// Each consumer's p_ready drives its producer's out_ready [A1:23].
module dot_fused #(parameter int W = 16, parameter int N = 4) (
    input  logic         clk,
    input  logic         rst,
    input  logic [W-1:0] i0_data,
    input  logic         i0_valid,
    output logic         i0_ready,
    input  logic [W-1:0] i1_data,
    input  logic         i1_valid,
    output logic         i1_ready,
    output logic [W-1:0] out_data,
    output logic         out_valid,
    input  logic         out_ready
);
    logic [W-1:0] zm_data;  logic zm_valid, zm_ready;

    sb_zipmap #(.W(W)) u_zipmap (
        .clk(clk), .rst(rst),
        .p0_data(i0_data), .p0_valid(i0_valid), .p0_ready(i0_ready),
        .p1_data(i1_data), .p1_valid(i1_valid), .p1_ready(i1_ready),
        .out_data(zm_data), .out_valid(zm_valid), .out_ready(zm_ready)
    );

    sb_reduce #(.W(W), .N(N)) u_reduce (
        .clk(clk), .rst(rst),
        .p_data(zm_data), .p_valid(zm_valid), .p_ready(zm_ready),
        .out_data(out_data), .out_valid(out_valid), .out_ready(out_ready)
    );
endmodule