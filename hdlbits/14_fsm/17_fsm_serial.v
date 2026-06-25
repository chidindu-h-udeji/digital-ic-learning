module top_module(
    input clk,
    input in,
    input reset,
    output done
);
    
    parameter START = 0, DATA = 1, WAIT = 2, STOP = 3;
    reg [1:0] state, next_state;
    reg [3:0] store;
    
    always @ (posedge clk) begin
        if (reset)
            state <= START;
        else
            state <= next_state;
    end
    
    always @(posedge clk) begin
        if (reset)
            store <= 4'b0;
        else if (state == DATA) begin
            if (store < 8)
                store <= store + 1;
            else
                store <= 8;
        end
        else if (state == START | state == WAIT | state == STOP)
            store <= 0;
    end
            

    always @ (*) begin
        next_state = state;
        case (state)
            START: next_state = (in == 0) ? DATA : START;
            DATA: next_state = (store>7) ? (in ? STOP : WAIT) : DATA;
            WAIT: next_state = in ? START : WAIT;
            STOP: next_state = (in == 0) ? DATA : START;
            default: next_state = START;
        endcase
    end
            
    assign done = (state==STOP);

endmodule
