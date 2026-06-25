module top_module (
    input clk,
    input aresetn,    // Asynchronous active-low reset
    input x,
    output z );
    
    parameter IDLE = 0, G1= 1, G10 = 2;
    reg [1:0] state, next_state;
    
    always @ (posedge clk or negedge aresetn) begin
        if (aresetn==0)
            state <= IDLE;
        else
            state <= next_state;
    end
    
    always @ (*) begin
        next_state = state;
        case (state)
            IDLE: next_state = x ? G1 : IDLE;
            G1: next_state = x ? G1 : G10;
            G10: next_state = x ? G1 : IDLE;
            default: next_state = IDLE;
        endcase
    end
    
    assign z = (state == G10) & x;    

endmodule
