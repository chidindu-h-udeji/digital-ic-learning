`timescale 1ns/1ps
// tb_dot_random.sv - random handshake test for dot_unfused (default)
// or dot_fused (-DFUSED).
// Cases and expected results come from golden.py (build/dot_vectors.mem).
// Each case runs with random input gaps and random output back-pressure.
// Sources hold valid until accepted, as an sbuild producer does.
// Per case: result equals golden.py, exactly one output, all inputs consumed.
// Every edge: output held while out_valid = 1 and out_ready = 0.
module tb_dot_random;
    localparam int W = 16, N = 4, NV = 200, T = 2 * N + 1;
    localparam int P_OFFER = 70, P_READY = 70;   // percent chance per tick

    logic clk = 0, rst = 1;
    always #5 clk = ~clk;

    logic [W-1:0] i0_data, i1_data, out_data;
    logic i0_valid = 0, i1_valid = 0, out_ready = 0;
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

    logic [W*T-1:0] vec [NV];
    logic [W-1:0] a [N], b [N], expected, got, prev_data;
    logic acc0, acc1, stalled;
    int ia, ib, n_out, errors = 0, stall_checks = 0, seed = 1;

    function automatic bit chance(input int pct);
        return ($unsigned($random(seed)) % 100) < pct;
    endfunction

    // Stimulus and sink ready: driven on negedge to avoid races with the DUT.
    always @(negedge clk) begin
        i0_valid  <= (ia < N) && ((i0_valid && !acc0) || chance(P_OFFER));
        i0_data   <= (ia < N) ? a[ia] : 'x;
        i1_valid  <= (ib < N) && ((i1_valid && !acc1) || chance(P_OFFER));
        i1_data   <= (ib < N) ? b[ib] : 'x;
        out_ready <= chance(P_READY);
    end

    // Monitor: handshakes and output stability under back-pressure.
    always @(posedge clk) if (!rst) begin
        acc0 <= i0_valid && i0_ready;
        acc1 <= i1_valid && i1_ready;
        if (i0_valid && i0_ready) ia <= ia + 1;
        if (i1_valid && i1_ready) ib <= ib + 1;
        if (out_valid && out_ready) begin n_out <= n_out + 1; got <= out_data; end
        if (stalled) begin
            stall_checks++;
            if (!out_valid || out_data !== prev_data) begin
                errors++;
                $display("  FAIL: output changed during back-pressure");
            end
        end
        stalled   <= out_valid && !out_ready;
        prev_data <= out_data;
    end

    task automatic run_case(input int k);
        int t;
        rst = 1;
        @(negedge clk);
        for (int j = 0; j < N; j++) begin
            a[j] = vec[k][W*(T-j)-1 -: W];
            b[j] = vec[k][W*(T-N-j)-1 -: W];
        end
        expected = vec[k][W-1:0];
        ia = 0; ib = 0; n_out = 0; acc0 = 0; acc1 = 0; stalled = 0;
        repeat (2) @(posedge clk);
        @(negedge clk) rst = 0;
        t = 0;
        while (n_out == 0 && t < 200) begin @(posedge clk); t++; end
        repeat (5) @(posedge clk);                   // give a duplicate time to appear
        if (n_out != 1 || got !== expected || ia != N || ib != N) begin
            errors++;
            $display("FAIL case %0d: got %0d, want %0d, outputs %0d, consumed %0d/%0d",
                     k, got, expected, n_out, ia, ib);
        end
    endtask

    initial begin
        $readmemh("build/dot_vectors.mem", vec);
        for (int k = 0; k < NV; k++) run_case(k);
        if (errors == 0)
            $display("PASS: %0d random cases, %0d stall checks, 0 errors", NV, stall_checks);
        else
            $display("FAIL: %0d error(s)", errors);
        $finish;
    end
endmodule