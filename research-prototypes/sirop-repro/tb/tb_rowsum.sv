`timescale 1ns/1ps
// tb_rowsum.sv - Fig. 11 vs Fig. 12 row sum, run side by side on one stream.
// Expected sums come from golden.py (build/rowsum_in.mem, build/rowsum_out.mem);
// the first three rows are the paper's example (6, 36, 66).
// Every edge: both designs show identical ready, valid and (when valid) data,
// and inside the Fig. 11 design in_cnt == i and out_cnt == 0 (the Sec. 6.2 claim).
// Random input gaps and random output back-pressure, as in tb_dot_random.
module tb_rowsum;
    localparam int W = 16, R = 3, ROWS = 100, NIN = R * ROWS;
    localparam int P_OFFER = 70, P_READY = 70;   // percent chance per tick

    logic clk = 0, rst = 1;
    always #5 clk = ~clk;

    logic [W-1:0] in_data, out11, out12;
    logic in_valid = 0, out_ready = 0;
    logic rdy11, rdy12, v11, v12;

    sb_rowsum11 #(.W(W), .R(R)) d11 (
        .clk(clk), .rst(rst),
        .p_data(in_data), .p_valid(in_valid), .p_ready(rdy11),
        .out_data(out11), .out_valid(v11), .out_ready(out_ready));

    sb_rowsum12 #(.W(W), .R(R)) d12 (
        .clk(clk), .rst(rst),
        .p_data(in_data), .p_valid(in_valid), .p_ready(rdy12),
        .out_data(out12), .out_valid(v12), .out_ready(out_ready));

    logic [W-1:0] vin [NIN], vout [ROWS];
    logic acc = 0;
    int ii = 0, io = 0, t, errors = 0, checks = 0, seed = 2;

    function automatic bit chance(input int pct);
        return ($unsigned($random(seed)) % 100) < pct;
    endfunction

    // Stimulus and sink ready: driven on negedge to avoid races with the DUTs.
    always @(negedge clk) begin
        in_valid  <= (ii < NIN) && ((in_valid && !acc) || chance(P_OFFER));
        in_data   <= (ii < NIN) ? vin[ii] : 'x;
        out_ready <= chance(P_READY);
    end

    // Monitor: lockstep comparison, Sec. 6.2 invariants, and golden values.
    always @(posedge clk) if (!rst) begin
        checks++;
        if (rdy11 !== rdy12 || v11 !== v12 || (v12 && out11 !== out12)) begin
            errors++;
            $display("FAIL: Fig. 11 and Fig. 12 differ at check %0d", checks);
        end
        if (d11.in_cnt != d11.i || d11.out_cnt != 0) begin
            errors++;
            $display("FAIL: in_cnt=%0d i=%0d out_cnt=%0d", d11.in_cnt, d11.i, d11.out_cnt);
        end
        acc <= in_valid && rdy12;
        if (in_valid && rdy12) ii <= ii + 1;
        if (v12 && out_ready) begin
            if (io >= ROWS) begin
                errors++;
                $display("FAIL: extra output %0d", out12);
            end else if (out12 !== vout[io]) begin
                errors++;
                $display("FAIL: row %0d got %0d, want %0d", io, out12, vout[io]);
            end else if (io < 3)
                $display("row %0d: %0d", io, out12);
            io <= io + 1;
        end
    end

    initial begin
        $readmemh("build/rowsum_in.mem", vin);
        $readmemh("build/rowsum_out.mem", vout);
        repeat (2) @(posedge clk);
        @(negedge clk) rst = 0;
        t = 0;
        while (io < ROWS && t < 5000) begin @(posedge clk); t++; end
        repeat (5) @(posedge clk);
        if (io != ROWS) begin
            errors++;
            $display("FAIL: %0d of %0d rows came out", io, ROWS);
        end
        if (errors == 0)
            $display("PASS: %0d rows, %0d lockstep checks, Fig. 11 == Fig. 12, in_cnt == i, out_cnt == 0",
                     ROWS, checks);
        else
            $display("FAIL: %0d error(s)", errors);
        $finish;
    end
endmodule