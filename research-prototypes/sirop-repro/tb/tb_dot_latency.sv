`timescale 1ns/1ps
// tb_dot_latency.sv - one dot product of length N without stalls; checks value and latency.
// For comparison with the authors' generated testbench (LATENCY: 841 cycles at N = 840).
// Inputs a[k] = k mod 7 + 1, b[k] = k mod 5 + 1; EXPECT is computed by golden.py.
// Expected latency from a hand trace of Algorithm 1: N + 2 unfused, N + 1 fused.
// Latency: the edge accepting the first input pair is edge 1;
//          L is the edge after which out_valid first reads 1.
module tb_dot_latency #(parameter int N = 840, parameter int EXPECT = 0);
    localparam int W = 16;
`ifdef FUSED
    localparam string NAME = "fused";
    localparam int    LAT_EXP = N + 1;
`else
    localparam string NAME = "unfused";
    localparam int    LAT_EXP = N + 2;
`endif

    logic clk = 0, rst = 1;
    always #5 clk = ~clk;

    logic [W-1:0] i0_data, i1_data, out_data;
    logic i0_valid = 0, i1_valid = 0, out_ready = 1;
    logic i0_ready, i1_ready, out_valid;

`ifdef FUSED
    dot_fused   #(.W(W), .N(N)) dut (
`else
    dot_unfused #(.W(W), .N(N)) dut (
`endif
        .clk(clk), .rst(rst),
        .i0_data(i0_data), .i0_valid(i0_valid), .i0_ready(i0_ready),
        .i1_data(i1_data), .i1_valid(i1_valid), .i1_ready(i1_ready),
        .out_data(out_data), .out_valid(out_valid), .out_ready(out_ready));

    logic [W-1:0] got;
    int ia = 0, ib = 0, tick = 0, first_acc = -1, out_edge = -1, lat;

    // Stimulus: driven on negedge to avoid races with the DUT.
    always @(negedge clk) begin
        i0_valid <= (ia < N);
        i0_data  <= ia % 7 + 1;
        i1_valid <= (ib < N);
        i1_data  <= ib % 5 + 1;
    end

    // Monitor: first accepted input and first valid output.
    always @(posedge clk) if (!rst) begin
        if (i0_valid && i0_ready) begin
            ia <= ia + 1;
            if (first_acc < 0) first_acc <= tick + 1;
        end
        if (i1_valid && i1_ready) ib <= ib + 1;
        if (out_valid && out_edge < 0) begin out_edge <= tick; got <= out_data; end
        tick <= tick + 1;
    end

    initial begin
        repeat (2) @(posedge clk);
        @(negedge clk) rst = 0;
        while (out_edge < 0 && tick < 10 * N) @(posedge clk);
        @(posedge clk);
        lat = out_edge - first_acc + 1;
        $display("%s N=%0d %s: value %0d (golden %0d), latency %0d (expected %0d)",
                 (got === EXPECT && lat == LAT_EXP) ? "PASS" : "FAIL",
                 N, NAME, got, EXPECT, lat, LAT_EXP);
        $finish;
    end
endmodule