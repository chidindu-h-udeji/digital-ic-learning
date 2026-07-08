module safety_monitor (
    input clk,
    input reset,
    input a_warn,
    input a_alarm,
    input b_warn,
    input b_alarm,
    output wire [1:0] alert_level,
    output shutoff,
    output buzzer,
    output fault_detected
);

    parameter [1:0] Normal = 2'b00, Warning = 2'b01, Alarm = 2'b10, Lockout = 2'b11;
    parameter Threshold = 9;

    reg [1:0] state, next_state;
    reg [4:0] fault_counter;

    // State Register
    always @ (posedge clk) begin
        if (reset)
            state <= Normal;
        else
            state <= next_state;
    end
    
    // Fault Counter Integration
    always @ (posedge clk) begin
        if (reset | ~(state == Alarm))
            fault_counter <= 0;
        else if (a_alarm & b_alarm)
            fault_counter <= fault_counter + 1;
    end
    
    // Next-State Logic
    always @ (*) begin
        next_state = state;
        case (state)
            Normal: begin
                if (a_alarm | b_alarm)
                    next_state = Alarm;
                else if (a_warn | b_warn)
                    next_state = Warning;
                else
                    next_state = Normal;
            end
            Warning: begin
                if ((a_alarm | b_alarm) | (a_warn & b_warn))
                    next_state = Alarm;
                else if (a_warn ^ b_warn)
                    next_state = Warning;
                else
                    next_state = Normal;
            end
            Alarm: begin
                if (fault_counter >= Threshold)
                    next_state = Lockout;
                else
                    next_state = Alarm;
            end
            Lockout: begin
                next_state = Lockout; 
            end
            default: next_state = Normal;
        endcase
    end
    
    // Output Logic
    assign alert_level = state;
    assign shutoff = (state == Lockout);
    assign buzzer = (state == Warning) | (state == Alarm) | (state == Lockout);
    assign fault_detected = (state == Lockout);
  
endmodule