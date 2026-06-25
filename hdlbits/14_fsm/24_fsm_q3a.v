module top_module (
    input clk,
    input reset,   // Synchronous reset
    input s,
    input w,
    output reg z
);
    
    parameter A=0, B=1; 
    reg state, next_state;
    reg [1:0] count, sum;
    
    always @ (posedge clk) begin
        if (reset)
            state <= A;
        else
            state <= next_state;
    end
    
    always @ (posedge clk) begin
        if (reset)
        {count, sum, z} <= 0;
        else if (state==B) begin
            if (count==2) begin
                {count, sum} <= 0;
                z <= (sum + w == 2);
            end
            else begin
                count <= count + 1;
                sum <= sum +  w;
                z <= 0;
            end
        end
    end
            
    
    always @ (*) begin
        next_state = state;
        case (state)
            A: next_state = s ? B : 0;
            B: next_state = B;
            default: next_state = A;
        endcase
    end
            

endmodule
