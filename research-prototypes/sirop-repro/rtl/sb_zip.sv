// sb_zip.sv - StmZip as a single sbuild (Hildebrand & Dubach, LCTES '26).
// Implements: sbuild(n)((sdata(p0), sdata(p1)), true) {} {p0: ready true, p1: ready true}
// Hardware structure follows Algorithm 1; [A1:n] = Algorithm 1, line n.
module sb_zip #(parameter int W = 16) (
    input  logic           clk,
    input  logic           rst,        // synchronous, active high
    input  logic [W-1:0]   p0_data,
    input  logic           p0_valid,
    output logic           p0_ready,
    input  logic [W-1:0]   p1_data,
    input  logic           p1_valid,
    output logic           p1_ready,
    output logic [2*W-1:0] out_data,   // {x.0, x.1}
    output logic           out_valid,
    input  logic           out_ready
);
    localparam logic READY_EXPR_P0 = 1'b1;
    localparam logic READY_EXPR_P1 = 1'b1;
    localparam logic VALID_EXPR    = 1'b1;

    logic send, arpv, can_step;

    assign send     = out_valid & out_ready;                         // [A1:3]
    assign arpv     = (!READY_EXPR_P0 || p0_valid)
                   && (!READY_EXPR_P1 || p1_valid);                  // [A1:4-6]
    assign can_step = arpv & (send | ~out_valid);                    // [A1:7]

    // Output registers [A1:9-14]. Data has no reset (init = None).
    always_ff @(posedge clk) begin
        if (rst)
            out_valid <= 1'b0;
        else if (can_step | send) begin
            out_data  <= {p0_data, p1_data};
            out_valid <= VALID_EXPR & arpv;
        end
    end

    assign p0_ready = READY_EXPR_P0 & can_step;                      // [A1:21-22]
    assign p1_ready = READY_EXPR_P1 & can_step;
endmodule