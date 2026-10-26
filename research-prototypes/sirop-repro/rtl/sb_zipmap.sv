// sb_zipmap.sv - zip and map fused into a single sbuild by the Fig. 13 rule
// (Hildebrand & Dubach, LCTES '26).
// Implements: sbuild(4)(sdata(p0) * sdata(p1), true) {} {p0: ready true, p1: ready true}
// Both fusion guards (r_c => v_p, v_p => r_c) evaluate to true here and reduce away.
// Hardware structure follows Algorithm 1; [A1:n] = Algorithm 1, line n.
module sb_zipmap #(parameter int W = 16) (
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
    localparam logic READY_EXPR_P0 = 1'b1;
    localparam logic READY_EXPR_P1 = 1'b1;
    localparam logic VALID_EXPR    = 1'b1;

    logic send, arpv, can_step;
    logic [2*W-1:0] product;

    assign product = p0_data * p1_data;

    assign send     = out_valid & out_ready;                         // [A1:3]
    assign arpv     = (!READY_EXPR_P0 || p0_valid)
                   && (!READY_EXPR_P1 || p1_valid);                  // [A1:4-6]
    assign can_step = arpv & (send | ~out_valid);                    // [A1:7]

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

    assign p0_ready = READY_EXPR_P0 & can_step;                      // [A1:21-22]
    assign p1_ready = READY_EXPR_P1 & can_step;
endmodule