module top_module (
    input clk,
    input reset,      // Synchronous reset
    output shift_ena);
    
    parameter A = 0, B = 1;
    reg state, next_state;
    reg [2:0] count;
    
    always @ (posedge clk) begin
        if (reset)
            state <= A;
        else
            state <= next_state;
    end
    
    always @ (posedge clk) begin
        if (reset | count == 4)
            count <= 0;
        else
            count <= count + 1;
    end
    
    always @ (*) begin
        next_state = state;
        case (state)
            A: next_state = (count==3) ? B : A;
            B: next_state = B;
            default: next_state = A;
        endcase
    end
    
    assign shift_ena = ~(state==B);
    
endmodule
