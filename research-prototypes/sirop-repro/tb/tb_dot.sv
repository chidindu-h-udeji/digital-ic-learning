`timescale 1ns/1ps
// tb_dot.sv - directed tests for dot_unfused (default) or dot_fused (-DFUSED).
// Expected values:
//   - result 70, products 5, 12, 21, 32 and running sums 0, 5, 17, 38 (Fig. 7);
//   - latency L0 without stalls and L0 + 1 with a one-tick I0 gap, from a hand trace
//     of Algorithm 1 (L0 = 6 unfused; 5 fused, one register stage fewer);
//   - output held constant while out_ready = 0 (Algorithm 1: send = can_step = 0).
// Latency: the edge accepting the first input pair is edge 1;
//          L is the edge after which out_valid first reads 1.
module tb_dot;
    localparam int W = 16, N = 4;
`ifdef FUSED
    localparam int L0 = 5;
`else
    localparam int L0 = 6;
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

    // The product link into reduce, and reduce's running sum.
`ifdef FUSED
    wire         pv = dut.zm_valid, pr = dut.zm_ready;
    wire [W-1:0] pd = dut.zm_data;
`else
    wire         pv = dut.map_valid, pr = dut.map_ready;
    wire [W-1:0] pd = dut.map_data;
`endif
    wire [W-1:0] sum_now = dut.u_reduce.sum;

    // Fig. 7: map/data, and reduce/sum just before each product is added.
    function automatic int p_exp(input int k);
        case (k) 0: return 5;  1: return 12; 2: return 21; 3: return 32; default: return -1; endcase
    endfunction
    function automatic int s_exp(input int k);
        case (k) 0: return 0;  1: return 5;  2: return 17; 3: return 38; default: return -1; endcase
    endfunction

    logic [W-1:0] a [N], b [N];
    logic [W-1:0] got, held;
    int ia, ib, tick, gap0, hold, first_acc, out_edge, n_out, kp, errors = 0;

    // Stimulus and sink ready: driven on negedge to avoid races with the DUT.
    always @(negedge clk) begin
        i0_valid  <= (ia < N) && (tick != gap0);
        i0_data   <= (ia < N) ? a[ia] : 'x;
        i1_valid  <= (ib < N);
        i1_data   <= (ib < N) ? b[ib] : 'x;
        out_ready <= (hold == 0) || (out_edge >= 0 && tick >= out_edge + hold);
    end

    // Monitor: handshakes, Fig. 7 intermediate values, latency, back-pressure.
    always @(posedge clk) if (!rst) begin
        if (i0_valid && i0_ready) begin
            ia <= ia + 1;
            if (first_acc < 0) first_acc <= tick + 1;
        end
        if (i1_valid && i1_ready) ib <= ib + 1;
        if (pv && pr) begin
            if (pd !== p_exp(kp) || sum_now !== s_exp(kp)) begin
                errors++;
                $display("  FAIL: product %0d is %0d with sum %0d (want %0d with sum %0d)",
                         kp, pd, sum_now, p_exp(kp), s_exp(kp));
            end
            kp <= kp + 1;
        end
        if (out_valid && out_ready) begin n_out <= n_out + 1; got <= out_data; end
        if (out_valid && out_edge < 0) begin out_edge <= tick; held <= out_data; end
        if (out_edge >= 0 && !out_ready && (!out_valid || out_data !== held)) begin
            errors++;
            $display("  FAIL: output changed during back-pressure at tick %0d", tick);
        end
        tick <= tick + 1;
    end

    // One dot product: g = tick with no I0 offer (-1: none),
    // h = ticks of back-pressure after the result appears.
    task automatic run(input string name, input int g, input int h, input int exp_lat);
        int lat;
        rst = 1;
        @(negedge clk);
        for (int k = 0; k < N; k++) begin a[k] = k + 1; b[k] = k + 5; end  // Fig. 7 inputs
        gap0 = g; hold = h;
        ia = 0; ib = 0; tick = 0; first_acc = -1; out_edge = -1; n_out = 0; kp = 0;
        repeat (2) @(posedge clk);
        @(negedge clk) rst = 0;
        repeat (30) @(posedge clk);
        lat = out_edge - first_acc + 1;
        if (n_out == 1 && got === 16'd70 && lat == exp_lat && kp == N)
            $display("PASS %s: products 5 12 21 32, sums 0 5 17 38, value %0d, latency %0d",
                     name, got, lat);
        else begin
            errors++;
            $display("FAIL %s: value %0d (want 70), latency %0d (want %0d), outputs %0d, products %0d",
                     name, got, lat, exp_lat, n_out, kp);
        end
    endtask

    initial begin
        run("T1 Fig. 7, no stalls",          -1, 0, L0);
        run("T2 Fig. 7, I0 gap at tick 2",    2, 0, L0 + 1);
        run("T3 back-pressure, 5-tick hold", -1, 5, L0);
        if (errors == 0) $display("ALL PASS");
        else             $display("%0d FAILURE(S)", errors);
        $finish;
    end
endmodule