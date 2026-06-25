module top_module (
    input clk,
    input resetn,    // active-low synchronous reset
    input [3:1] r,   // request
    output [3:1] g   // grant
); 
    
    parameter A = 0, B = 1, C = 2, D = 3;
    reg [1:0] state, next_state;
    
    always @ (posedge clk) begin
        if (~resetn)
            state <= A;
        else
            state <= next_state;
    end
    
    always @ (*) begin
        next_state = state;
        case (state)
            A: next_state = r[1] ? B : (r[2] ? C : (r[3] ? D : A));
            B: next_state = r[1] ? B : A;
            C: next_state = r[2] ? C : A;
            D: next_state = r[3] ? D : A;
            default: next_state = A;
        endcase
    end
    
    assign g[1] = (state==B);
    assign g[2] = (state==C);
    assign g[3] = (state==D);

endmodule
