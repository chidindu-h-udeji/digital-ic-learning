module top_module(
    input clk,
    input areset,
    input in,
    output out);  

    parameter A=0, B=1; 
    reg state, next_state;

    always @(posedge clk or posedge areset) begin
        if (areset)
            state <= B;
        else
            state <= next_state;
    end

    always @(*) begin
        case (state)
            A: if (in)
                next_state = A;
            else
                next_state = B;
            B: if (in)
                next_state = B;
            else
                next_state = A;
            default: next_state = B;
        endcase
    end
    
    assign out = (state == B);

endmodule
