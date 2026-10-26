// dot_unfused.sv - Fig. 7 dot product as the three-stage pipeline of Fig. 8
// (Hildebrand & Dubach, LCTES '26): I0, I1 -> zip -> map -> reduce -> out.
// Each consumer's p_ready drives its producer's out_ready [A1:23].
module dot_unfused #(parameter int W = 16, parameter int N = 4) (
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
    logic [2*W-1:0] zip_data;  logic zip_valid, zip_ready;
    logic [W-1:0]   map_data;  logic map_valid, map_ready;

    sb_zip #(.W(W)) u_zip (
        .clk(clk), .rst(rst),
        .p0_data(i0_data), .p0_valid(i0_valid), .p0_ready(i0_ready),
        .p1_data(i1_data), .p1_valid(i1_valid), .p1_ready(i1_ready),
        .out_data(zip_data), .out_valid(zip_valid), .out_ready(zip_ready)
    );

    sb_map #(.W(W)) u_map (
        .clk(clk), .rst(rst),
        .p_data(zip_data), .p_valid(zip_valid), .p_ready(zip_ready),
        .out_data(map_data), .out_valid(map_valid), .out_ready(map_ready)
    );

    sb_reduce #(.W(W), .N(N)) u_reduce (
        .clk(clk), .rst(rst),
        .p_data(map_data), .p_valid(map_valid), .p_ready(map_ready),
        .out_data(out_data), .out_valid(out_valid), .out_ready(out_ready)
    );
endmodule