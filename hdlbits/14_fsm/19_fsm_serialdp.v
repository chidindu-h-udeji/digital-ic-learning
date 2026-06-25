module top_module(
    input clk,
    input in,
    input reset,
    output reg [7:0] out_byte,
    output done
);

    parameter START = 0, DATA = 1, WAIT = 2, STOP = 3;
    reg [1:0] state, next_state;
    reg [3:0] store;
    wire parity_check, parity_rst;
    
    assign parity_rst = reset | (state == START);
    
    parity instance1 (.clk(clk), .reset(parity_rst), .in(in), .odd(parity_check));
    
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
            if (store < 9)
                store <= store + 1;
            else
                store <= 9;
        end
        else if (state == START | state == WAIT | state == STOP)
            store <= 0;
    end
    
    always @ (posedge clk) begin
        if (state == DATA && store <8)
            out_byte <= {in, out_byte[7:1]};
    end
            

    always @ (*) begin
        next_state = state;
        case (state)
            START: next_state = (in == 0) ? DATA : START;
            DATA: next_state = (store>8) ? (in ? ((parity_check) ? STOP : START) : WAIT) : DATA;
            WAIT: next_state = in ? START : WAIT;
            STOP: next_state = (in == 0) ? DATA : START;
            default: next_state = START;
        endcase
    end
            
    assign done = (state==STOP);

endmodule
