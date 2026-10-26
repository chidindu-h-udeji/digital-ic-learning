// sb_concat.sv - StmConcat(s0, s1) as a single sbuild, Fig. 10 lowering
// (Hildebrand & Dubach, LCTES '26):
//   sbuild(n + m)(if i == n then sdata(p1) else sdata(p0), true)
//     {i: init 0, next if i == n then i else 1 + i}
//     {p0: ready i != n, p1: ready i == n}
// Hardware structure follows Algorithm 1; [A1:n] = Algorithm 1, line n.
module sb_concat #(parameter int W = 16, parameter int N = 4) (
    input  logic         clk,
    input  logic         rst,        // synchronous, active high
    input  logic [W-1:0] p0_data,
    input  logic         p0_valid,
    output logic         p0_ready,
    input  logic [W-1:0] p1_data,
    input  logic         p1_valid,
    output logic         p1_ready,
    output logic [W-1:0] out_data,
    output logic         out_valid,
    input  logic         out_ready
);
    localparam int   IW = $clog2(N + 1);                     // u[log2(n+1)]
    localparam logic VALID_EXPR = 1'b1;

    logic send, arpv, can_step;
    logic [IW-1:0] i;
    logic second, ready_expr_p0, ready_expr_p1;

    assign second        = (i == N);
    assign ready_expr_p0 = !second;                          // p0: ready i != n
    assign ready_expr_p1 = second;                           // p1: ready i == n

    assign send     = out_valid & out_ready;                 // [A1:3]
    assign arpv     = (!ready_expr_p0 || p0_valid)
                   && (!ready_expr_p1 || p1_valid);          // [A1:4-6]
    assign can_step = arpv & (send | ~out_valid);            // [A1:7]

    // Output registers [A1:9-14]. Data has no reset (init = None).
    always_ff @(posedge clk) begin
        if (rst)
            out_valid <= 1'b0;
        else if (can_step | send) begin
            out_data  <= second ? p1_data : p0_data;
            out_valid <= VALID_EXPR & arpv;
        end
    end

    // Accumulator [A1:16-18]: updated on can_step only.
    always_ff @(posedge clk) begin
        if (rst)
            i <= '0;
        else if (can_step)
            i <= second ? i : i + 1'b1;
    end

    assign p0_ready = ready_expr_p0 & can_step;              // [A1:21-22]
    assign p1_ready = ready_expr_p1 & can_step;
endmodule