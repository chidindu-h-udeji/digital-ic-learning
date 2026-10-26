// sb_map.sv - StmMap stage of the Fig. 7 dot product as a single sbuild
// (Hildebrand & Dubach, LCTES '26).
// Implements: sbuild(4)(sdata(p).0 * sdata(p).1, true) {} {p: ready true}
// Hardware structure follows Algorithm 1; [A1:n] = Algorithm 1, line n.
module sb_map #(parameter int W = 16) (
    input  logic           clk,
    input  logic           rst,        // synchronous, active high
    input  logic [2*W-1:0] p_data,     // {x.0, x.1}
    input  logic           p_valid,
    output logic           p_ready,
    output logic [W-1:0]   out_data,
    output logic           out_valid,
    input  logic           out_ready
);
    localparam logic READY_EXPR_P = 1'b1;
    localparam logic VALID_EXPR   = 1'b1;

    logic send, arpv, can_step;
    logic [W-1:0]   x0, x1;
    logic [2*W-1:0] product;

    assign x0      = p_data[2*W-1:W];
    assign x1      = p_data[W-1:0];
    assign product = x0 * x1;

    assign send     = out_valid & out_ready;                 // [A1:3]
    assign arpv     = !READY_EXPR_P || p_valid;              // [A1:4-6]
    assign can_step = arpv & (send | ~out_valid);            // [A1:7]

    // Output registers [A1:9-14]. Data has no reset (init = None).
    // u16 result: the low W bits of the product are kept.
    always_ff @(posedge clk) begin
        if (rst)
            out_valid <= 1'b0;
        else if (can_step | send) begin
            out_data  <= product[W-1:0];
            out_valid <= VALID_EXPR & arpv;
        end
    end

    assign p_ready = READY_EXPR_P & can_step;                // [A1:21-22]
endmodule