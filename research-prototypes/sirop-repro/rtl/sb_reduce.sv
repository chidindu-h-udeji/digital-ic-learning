// sb_reduce.sv - StmReduce stage of the Fig. 7 dot product as a single sbuild
// (Hildebrand & Dubach, LCTES '26).
// Implements: sbuild(1)(sum + sdata(p), i + 1 == N)
//             {i: init 0, next i + 1; sum: init 0, next sum + sdata(p)} {p: ready true}
// Follows the Fig. 7 lowering (init 0, no 'first' flag), not Fig. 10.
// One result per reset: i is not cleared after the output (length-1 stream).
// Hardware structure follows Algorithm 1; [A1:n] = Algorithm 1, line n.
module sb_reduce #(parameter int W = 16, parameter int N = 4) (
    input  logic         clk,
    input  logic         rst,        // synchronous, active high
    input  logic [W-1:0] p_data,
    input  logic         p_valid,
    output logic         p_ready,
    output logic [W-1:0] out_data,
    output logic         out_valid,
    input  logic         out_ready
);
    localparam logic READY_EXPR_P = 1'b1;

    logic send, arpv, can_step;
    logic [W-1:0] sum, i;                                    // accumulators (u16 in Fig. 7)
    logic [W-1:0] data_expr;
    logic         valid_expr;

    assign data_expr  = sum + p_data;
    assign valid_expr = (i + 1'b1 == W'(N));

    assign send     = out_valid & out_ready;                 // [A1:3]
    assign arpv     = !READY_EXPR_P || p_valid;              // [A1:4-6]
    assign can_step = arpv & (send | ~out_valid);            // [A1:7]

    // Output registers [A1:9-14]. Data has no reset (init = None).
    always_ff @(posedge clk) begin
        if (rst)
            out_valid <= 1'b0;
        else if (can_step | send) begin
            out_data  <= data_expr;
            out_valid <= valid_expr & arpv;
        end
    end

    // Accumulators [A1:16-18]: updated on can_step only.
    always_ff @(posedge clk) begin
        if (rst) begin
            i   <= '0;
            sum <= '0;
        end else if (can_step) begin
            i   <= i + 1'b1;
            sum <= sum + p_data;
        end
    end

    assign p_ready = READY_EXPR_P & can_step;                // [A1:21-22]
endmodule