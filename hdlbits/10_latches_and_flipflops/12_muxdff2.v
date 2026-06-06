module top_module (
    input clk,
    input w, R, E, L,
    output reg Q
);
    always @ (posedge clk) begin
        if (L==1) begin
            Q <= R;
        end
        else if (E==1) begin
            Q <= w;
        end
        else begin
            Q <= Q;
        end
    end
        

endmodule