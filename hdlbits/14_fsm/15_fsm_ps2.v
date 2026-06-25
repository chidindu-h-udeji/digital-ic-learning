module top_module(
    input clk,
    input [7:0] in,
    input reset,
    output done);
    
    parameter BYTE1 = 0, BYTE2 = 1, BYTE3 = 2, DONE = 3;
    reg [1:0] state, next_state;
    
    always @ (posedge clk) begin
        if (reset)
            state <= BYTE1;
        else
            state <= next_state;
    end

    always @ (*) begin
        next_state = state;
        case (state)
            BYTE1: next_state = in[3] ? BYTE2 : BYTE1;
            BYTE2: next_state = BYTE3;
            BYTE3: next_state = DONE;
            DONE: next_state = in[3] ? BYTE2 : BYTE1;
            default: next_state = BYTE1;
        endcase
    end
            
    assign done = (state==DONE);

endmodule
