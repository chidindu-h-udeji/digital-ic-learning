`timescale 1ns/1ps
// tb_letstm.sv - letstm[K] x = s in StmConcat(x, x), with s = 10, 20, 30, 40.
// Expected output by definition of concat: s then s (8 values).
// Reports PASS if all 8 arrive in order, STUCK if no output for 100 ticks.
// Run once per buffer size: iverilog -Ptb_letstm.K=<k> ...
module tb_letstm #(parameter int K = 1);
    localparam int W = 16, N = 4;

    logic clk = 0, rst = 1;
    always #5 clk = ~clk;

    logic [W-1:0] s_data, out_data;
    logic s_valid = 0, out_ready = 1;
    logic s_ready, out_valid;

    letstm_concat #(.W(W), .N(N), .K(K)) dut (
        .clk(clk), .rst(rst),
        .s_data(s_data), .s_valid(s_valid), .s_ready(s_ready),
        .out_data(out_data), .out_valid(out_valid), .out_ready(out_ready));

    logic [W-1:0] s [N];
    int is = 0, nout = 0, idle = 0, errors = 0;

    always @(negedge clk) begin
        s_valid <= (is < N);
        s_data  <= (is < N) ? s[is] : 'x;
    end

    always @(posedge clk) if (!rst) begin
        if (s_valid && s_ready) is <= is + 1;
        if (out_valid && out_ready) begin
            if (out_data !== s[nout % N]) begin
                errors++;
                $display("  FAIL: output %0d is %0d, want %0d", nout, out_data, s[nout % N]);
            end
            nout <= nout + 1;
            idle <= 0;
        end else
            idle <= idle + 1;
    end

    initial begin
        for (int k = 0; k < N; k++) s[k] = 10 * (k + 1);
        repeat (2) @(posedge clk);
        @(negedge clk) rst = 0;
        while (nout < 2 * N && idle < 100) @(posedge clk);
        if (nout == 2 * N && errors == 0)
            $display("K=%0d: PASS, all %0d outputs in order (s then s)", K, 2 * N);
        else if (idle >= 100)
            $display("K=%0d: STUCK after %0d output(s)", K, nout);
        else
            $display("K=%0d: FAIL, %0d error(s)", K, errors);
        $finish;
    end
endmodule