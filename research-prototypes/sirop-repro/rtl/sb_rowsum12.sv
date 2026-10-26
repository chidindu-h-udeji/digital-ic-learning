// sb_rowsum12.sv - row sum of expression (1), simplified form (Fig. 12)
// (Hildebrand & Dubach, LCTES '26).
// Implements: sbuild(10)(if first then sdata(p) else sum + sdata(p), i == 2)
//   {sum:   init 0,    next if i == 2 then 0 else if first then sdata(p) else sum + sdata(p);
//    first: init true, next i == 2;
//    i:     init 0,    next if i == 2 then 0 else 1 + i}
//   {p: ready true}
// Fig. 12 writes sdata(s) in places; read here as sdata(p), the producer's name.
// Hardware structure follows Algorithm 1; [A1:n] = Algorithm 1, line n.
module sb_rowsum12 #(parameter int W = 16, parameter int R = 3) (
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
    localparam int   LAST = R - 1;                           // "2" in Fig. 12 (rows of 3)

    logic send, arpv, can_step;
    logic [W-1:0] sum, data_expr;                            // sum: u16
    logic [3:0]   i;                                         // i: u4
    logic         first, at_end;

    assign at_end    = (i == LAST);
    assign data_expr = first ? p_data : sum + p_data;

    assign send     = out_valid & out_ready;                 // [A1:3]
    assign arpv     = !READY_EXPR_P || p_valid;              // [A1:4-6]
    assign can_step = arpv & (send | ~out_valid);            // [A1:7]

    // Output registers [A1:9-14]. Data has no reset (init = None).
    always_ff @(posedge clk) begin
        if (rst)
            out_valid <= 1'b0;
        else if (can_step | send) begin
            out_data  <= data_expr;
            out_valid <= at_end & arpv;                      // valid = i == 2
        end
    end

    // Accumulators [A1:16-18]: updated on can_step only.
    always_ff @(posedge clk) begin
        if (rst) begin
            sum <= '0; first <= 1'b1; i <= '0;
        end else if (can_step) begin
            sum   <= at_end ? '0 : data_expr;
            first <= at_end;
            i     <= at_end ? '0 : i + 1'b1;
        end
    end

    assign p_ready = READY_EXPR_P & can_step;                // [A1:21-22]
endmodule