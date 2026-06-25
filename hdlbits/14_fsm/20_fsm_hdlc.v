module top_module(
    input clk,
    input reset,
    input in,
    output disc,
    output flag,
    output err);
    
    parameter NONE=0, I=1, II=2,III=3, IV=4, V=5, VI=6, ERROR=7, DISCARD=8, FLAG=10;
    reg [3:0] state, next_state;
    
    always @ (posedge clk) begin
        if (reset)
            state <= NONE;
        else
            state <= next_state;
    end
    
    always @ (*) begin
        next_state = state;
        case (state) 
            NONE: next_state = in ? I : NONE;
            I: next_state = in ? II : NONE;
            II: next_state = in ? III : NONE;
            III: next_state = in ? IV : NONE;
            IV: next_state = in ? V : NONE;
            V: next_state = in ? VI : DISCARD;
            VI: next_state = in ? ERROR : FLAG;
            ERROR: next_state = in ? ERROR : NONE;
            DISCARD: next_state = in ? I : NONE;
            FLAG: next_state = in ? I : NONE;
            default: next_state = NONE;
        endcase
    end
            
    assign disc = (state==DISCARD);
    assign flag = (state==FLAG);
    assign err = (state==ERROR);

endmodule
