module top_module(
    input clk,
    input areset,
    input bump_left,
    input bump_right,
    input ground,
    input dig,
    output walk_left,
    output walk_right,
    output aaah,
    output digging );
    
    parameter LEFT=0, RIGHT=1, FALL_L=2, FALL_R=3,DIG_L=4, DIG_R=5, SPLAT=6; 
    reg [2:0] state, next_state;
    reg [5:0] count;

    always @(posedge clk, posedge areset) begin
        if (areset)
            state <= LEFT;
        else
            state <= next_state;
    end
    
    always @(posedge clk or posedge areset) begin
        if (areset)
            count <= 6'd0;
        else if (state == FALL_L | state == FALL_R) begin
            if (count < 20)
                count <= count + 1;
            else
                count <= 20;
        end
        else if (state == LEFT | state == DIG_L | state == RIGHT | state == DIG_R)
            count <= 0;
    end
            
            

    always @(*) begin
        next_state = state;
        case (state)
            LEFT: next_state = (ground==0) ? FALL_L : (dig ? DIG_L : (bump_left ? RIGHT : LEFT));
            RIGHT: next_state = (ground==0) ? FALL_R : (dig ? DIG_R : (bump_right ? LEFT : RIGHT));
            FALL_L: next_state = ground ? ((count>19) ? SPLAT : LEFT) : FALL_L;
            FALL_R: next_state = ground ? ((count>19) ? SPLAT : RIGHT) : FALL_R;
            DIG_L: next_state = (ground==0) ? FALL_L : DIG_L;
            DIG_R: next_state = (ground==0) ? FALL_R : DIG_R;
            SPLAT: next_state = SPLAT;
            default: next_state = LEFT;
        endcase
    end

    assign walk_left = (state == LEFT);
    assign walk_right = (state == RIGHT);
    assign aaah = (state == FALL_L | state == FALL_R);
    assign digging = (state == DIG_L | state == DIG_R);

endmodule
