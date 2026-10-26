`timescale 1ns/1ps
// tb_stream.sv - row-wise dot products: zip -> map -> rowsum12 (default) or
// zipmap -> rowsum12 (-DFUSED), rows of R = 3.
// The row sum emits a result every R inputs, so with random sink back-pressure its
// output fills mid-stream and the upstream stages must stall. This exercises the
// (send | ~out_valid) path that the single-output dot tests never reach.
// Expected results come from golden.py (build/rowdot_in.mem, build/rowdot_out.mem).
// Every link is checked each edge: data and valid held while valid = 1 and ready = 0.

// Counts stalls on one link and checks that nothing changes during them.
module stall_check #(parameter int W = 16) (
    input logic         clk, rst, valid, ready,
    input logic [W-1:0] data
);
    logic         held = 1'b0;
    logic [W-1:0] prev;
    int checks = 0, errors = 0;
    always @(posedge clk) if (!rst) begin
        if (held) begin
            checks++;
            if (!valid || data !== prev) begin
                errors++;
                $display("  FAIL: %m saw a change while stalled");
            end
        end
        held <= valid && !ready;
        prev <= data;
    end
endmodule

module tb_stream;
    localparam int W = 16, R = 3, ROWS = 100, NIN = R * ROWS;
    localparam int P_OFFER = 70, P_READY = 40;   // percent chance per tick

    logic clk = 0, rst = 1;
    always #5 clk = ~clk;

    logic [W-1:0] i0_data, i1_data, prod_data, out_data;
    logic i0_valid = 0, i1_valid = 0, out_ready = 0;
    logic i0_ready, i1_ready, prod_valid, prod_ready, out_valid;

`ifdef FUSED
    sb_zipmap #(.W(W)) u_zm (
        .clk(clk), .rst(rst),
        .p0_data(i0_data), .p0_valid(i0_valid), .p0_ready(i0_ready),
        .p1_data(i1_data), .p1_valid(i1_valid), .p1_ready(i1_ready),
        .out_data(prod_data), .out_valid(prod_valid), .out_ready(prod_ready));
`else
    logic [2*W-1:0] zip_data;
    logic zip_valid, zip_ready;
    sb_zip #(.W(W)) u_zip (
        .clk(clk), .rst(rst),
        .p0_data(i0_data), .p0_valid(i0_valid), .p0_ready(i0_ready),
        .p1_data(i1_data), .p1_valid(i1_valid), .p1_ready(i1_ready),
        .out_data(zip_data), .out_valid(zip_valid), .out_ready(zip_ready));
    sb_map #(.W(W)) u_map (
        .clk(clk), .rst(rst),
        .p_data(zip_data), .p_valid(zip_valid), .p_ready(zip_ready),
        .out_data(prod_data), .out_valid(prod_valid), .out_ready(prod_ready));
    stall_check #(.W(2*W)) sc_zip (.clk(clk), .rst(rst), .valid(zip_valid),
                                   .ready(zip_ready), .data(zip_data));
`endif
    sb_rowsum12 #(.W(W), .R(R)) u_rs (
        .clk(clk), .rst(rst),
        .p_data(prod_data), .p_valid(prod_valid), .p_ready(prod_ready),
        .out_data(out_data), .out_valid(out_valid), .out_ready(out_ready));
    stall_check #(.W(W)) sc_prod (.clk(clk), .rst(rst), .valid(prod_valid),
                                  .ready(prod_ready), .data(prod_data));
    stall_check #(.W(W)) sc_out (.clk(clk), .rst(rst), .valid(out_valid),
                                 .ready(out_ready), .data(out_data));

    logic [2*W-1:0] vin [NIN];
    logic [W-1:0]   vout [ROWS];
    logic acc0 = 0, acc1 = 0;
    int ia = 0, ib = 0, io = 0, t, errors = 0, total_err, seed = 3;

    function automatic bit chance(input int pct);
        return ($unsigned($random(seed)) % 100) < pct;
    endfunction

    // Stimulus and sink ready: driven on negedge; sources hold valid until accepted.
    always @(negedge clk) begin
        i0_valid  <= (ia < NIN) && ((i0_valid && !acc0) || chance(P_OFFER));
        i0_data   <= (ia < NIN) ? vin[ia][2*W-1:W] : 'x;
        i1_valid  <= (ib < NIN) && ((i1_valid && !acc1) || chance(P_OFFER));
        i1_data   <= (ib < NIN) ? vin[ib][W-1:0] : 'x;
        out_ready <= chance(P_READY);
    end

    // Monitor: handshakes and results against golden.py.
    always @(posedge clk) if (!rst) begin
        acc0 <= i0_valid && i0_ready;
        acc1 <= i1_valid && i1_ready;
        if (i0_valid && i0_ready) ia <= ia + 1;
        if (i1_valid && i1_ready) ib <= ib + 1;
        if (out_valid && out_ready) begin
            if (io >= ROWS) begin
                errors++;
                $display("  FAIL: extra output %0d", out_data);
            end else if (out_data !== vout[io]) begin
                errors++;
                $display("  FAIL: row %0d got %0d, want %0d", io, out_data, vout[io]);
            end
            io <= io + 1;
        end
    end

    initial begin
        $readmemh("build/rowdot_in.mem", vin);
        $readmemh("build/rowdot_out.mem", vout);
        repeat (2) @(posedge clk);
        @(negedge clk) rst = 0;
        t = 0;
        while (io < ROWS && t < 20000) begin @(posedge clk); t++; end
        repeat (5) @(posedge clk);
        if (io != ROWS) begin
            errors++;
            $display("  FAIL: %0d of %0d rows came out", io, ROWS);
        end
`ifdef FUSED
        total_err = errors + sc_prod.errors + sc_out.errors;
        $display("%s: %0d rows; stalls checked: zipmap->rowsum %0d, rowsum->sink %0d",
                 total_err == 0 ? "PASS" : "FAIL", ROWS, sc_prod.checks, sc_out.checks);
`else
        total_err = errors + sc_zip.errors + sc_prod.errors + sc_out.errors;
        $display("%s: %0d rows; stalls checked: zip->map %0d, map->rowsum %0d, rowsum->sink %0d",
                 total_err == 0 ? "PASS" : "FAIL", ROWS, sc_zip.checks, sc_prod.checks, sc_out.checks);
`endif
        $finish;
    end
endmodule