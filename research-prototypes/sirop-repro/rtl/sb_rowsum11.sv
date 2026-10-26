// sb_rowsum11.sv - row sum of expression (1) as first lowered (Fig. 11),
// before the Sec. 6.2 simplification removes in_cnt and out_cnt
// (Hildebrand & Dubach, LCTES '26).
// RESET = (i != 2 && in_cnt == 2 && out_cnt == 1)
//      || (in_cnt == 2 && out_cnt == 0 && i == 2)            (Fig. 11, lines 1-3)
// Hardware structure follows Algorithm 1; [A1:n] = Algorithm 1, line n.
module sb_rowsum11 #(parameter int W = 16, parameter int R = 3) (
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
    localparam int   LAST = R - 1;                           // "2" in Fig. 11 (rows of 3)

    logic send, arpv, can_step;
    logic [W-1:0]  sum, data_expr;                           // sum: u16
    logic [3:0]    i;                                        // i: u4
    logic [31:0]   in_cnt, out_cnt;                          // u32
    logic          first, reset_c;

    assign reset_c   = (i != LAST && in_cnt == LAST && out_cnt == 1)
                    || (in_cnt == LAST && out_cnt == 0 && i == LAST);
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
            out_valid <= (i == LAST) & arpv;                 // valid = i == 2
        end
    end

    // Accumulators [A1:16-18]: updated on can_step only.
    always_ff @(posedge clk) begin
        if (rst) begin
            sum <= '0; first <= 1'b1; i <= '0; in_cnt <= '0; out_cnt <= '0;
        end else if (can_step) begin
            sum     <= reset_c ? '0 : data_expr;
            first   <= reset_c;
            i       <= reset_c ? '0 : i + 1'b1;
            in_cnt  <= reset_c ? '0 : in_cnt + 1'b1;
            out_cnt <= reset_c ? '0 : (i == LAST ? out_cnt + 1'b1 : out_cnt);
        end
    end

    assign p_ready = READY_EXPR_P & can_step;                // [A1:21-22]
endmodule