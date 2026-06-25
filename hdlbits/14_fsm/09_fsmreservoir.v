module top_module (
    input clk,
    input reset,
    input [3:1] s,
    output fr3,
    output fr2,
    output fr1,
    output dfr
);
    
    parameter BS1 = 6'b000001;
    parameter RS1 = 6'b000010;
    parameter FS1 = 6'b000100;
    parameter RS2 = 6'b001000;
    parameter FS2 = 6'b010000;
    parameter AS3 = 6'b100000;
    
    reg [5:0] state, next_state;
    
    always @(posedge clk) begin
        if (reset)
            state <= BS1;
        else
            state <= next_state;
    end
    
    always @(*) begin
        next_state = state;
        
        case (state)
            BS1: begin
                case (s)
                    3'b000: next_state = BS1;
                    3'b001: next_state = RS1;
                    default: next_state = BS1;
                endcase
            end
            RS1: begin
                case (s)
                    3'b000: next_state = BS1;
                    3'b001: next_state = RS1;
                    3'b011: next_state = RS2;
                    default: next_state = RS1;
                endcase
            end
            FS1: begin
                case (s)
                    3'b000: next_state = BS1;
                    3'b001: next_state = FS1;
                    3'b011: next_state = RS2;
                    default: next_state = FS1;
                endcase
            end
            RS2: begin
                case (s)
                    3'b001: next_state = FS1;
                    3'b011: next_state = RS2;
                    3'b111: next_state = AS3;
                    default: next_state = RS2;
                endcase
            end
            FS2: begin
                case (s)
                    3'b001: next_state = FS1;
                    3'b011: next_state = FS2;
                    3'b111: next_state = AS3;
                    default: next_state = FS2;
                endcase
            end
            AS3: begin
                case (s)
                    3'b011: next_state = FS2;
                    3'b111: next_state = AS3;
                    default: next_state = AS3;
                endcase
            end
            default: next_state = BS1;
        endcase
    end
    
    assign fr3 = state[0];
    assign fr2 = state[1] | state[2] | state[0];
    assign fr1 = state[3] | state[4] | state[1] | state[2] | state[0];
    assign dfr = state[4] | state[2] | state[0]; 
    
endmodule
