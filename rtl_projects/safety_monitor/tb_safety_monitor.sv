`timescale 1ns/1ps

module tb_safety_monitor;
    reg        clk=0, reset; 
    reg        a_warn, a_alarm, b_warn, b_alarm; 
    wire [1:0] alert_level; 
    wire       shutoff, buzzer, fault_detected;
    
    integer errors = 0; // Error counter
    
    safety_monitor dut (
        .clk(clk), .reset(reset), 
        .a_warn(a_warn), .a_alarm(a_alarm), .b_warn(b_warn), .b_alarm(b_alarm), 
        .alert_level(alert_level), 
        .shutoff(shutoff), 
        .buzzer(buzzer), 
        .fault_detected(fault_detected)
    );
    
    always #5 clk = ~clk; // 10ns clock
    
    // Self-checking function
    task check;
        input [1:0] exp_alert;
        input       exp_shutoff;
        input       exp_buzzer;
        input       exp_fault;
        input [8*45:1] scenario_name; 
        begin
            #1; // Wait for logic to settle
            if (alert_level !== exp_alert || shutoff !== exp_shutoff || buzzer !== exp_buzzer || fault_detected !== exp_fault) begin
                $display("FAIL: %s", scenario_name);
                $display("  Expected: alert=%b, shutoff=%b, buzzer=%b, fault=%b", exp_alert, exp_shutoff, exp_buzzer, exp_fault);
                $display("  Got:      alert=%b, shutoff=%b, buzzer=%b, fault=%b", alert_level, shutoff, buzzer, fault_detected);
                errors = errors + 1;
            end else begin
                $display("PASS: %s", scenario_name);
            end
        end
    endtask

    initial begin
        $dumpfile("tb_safety_monitor.vcd");
        $dumpvars(0, tb_safety_monitor);
        
        $display("\nStarting FSM Verification...\n");

        // --- 1. Normal & Warnings ---
        reset=1; a_warn=0; a_alarm=0; b_warn=0; b_alarm=0;
        @(posedge clk);
        reset = 0;
        @(negedge clk);
        check(2'b00, 0, 0, 0, "Normal state after reset");
        
        @(negedge clk); a_warn = 1;
        @(negedge clk);
        check(2'b01, 0, 1, 0, "Warning A active");

        @(negedge clk); a_warn = 0; b_warn = 1;
        @(negedge clk);
        check(2'b01, 0, 1, 0, "Warning B active");

        // --- 2. Alarm & Lockout ---
        @(negedge clk); a_alarm = 1;
        @(negedge clk);
        check(2'b10, 0, 1, 0, "Alarm A active - No lockout yet");
        
        @(negedge clk); b_alarm = 1; // Trigger both alarms
        repeat (10) @(negedge clk); // Wait 10 cycles
        check(2'b11, 1, 1, 1, "Lockout engaged after 10 cycles");

        @(negedge clk); // Gas clears
        a_alarm = 0; b_alarm = 0; a_warn = 0; b_warn = 0;
        repeat (3) @(negedge clk);
        check(2'b11, 1, 1, 1, "Lockout persists without gas");

        @(negedge clk); reset = 1; // Manual reset
        @(negedge clk); reset = 0;
        check(2'b00, 0, 0, 0, "Recovered after reset");

        // --- 3. Alarm Latch & Fault Pause ---
        @(negedge clk); a_alarm = 1; 
        @(negedge clk);
        check(2'b10, 0, 1, 0, "Spike enters ALARM state");
        
        @(negedge clk); a_alarm = 0; // Gas clears early
        repeat (15) @(negedge clk); // Wait past threshold
        check(2'b10, 0, 1, 0, "ALARM latches but avoids LOCKOUT");
        
        @(negedge clk); reset = 1; // Manual reset
        @(negedge clk); reset = 0;

        // --- 4. Edge Cases ---
        @(negedge clk); a_warn = 1; a_alarm = 1; 
        @(negedge clk);
        check(2'b10, 0, 1, 0, "Simultaneous Warn/Alarm prioritizes Alarm");
        
        @(negedge clk); a_warn = 0; a_alarm = 0; b_alarm = 1; 
        #2 a_alarm = 1; // Glitch high
        #2 a_alarm = 0; // Glitch low before clock edge
        @(negedge clk);
        check(2'b10, 0, 1, 0, "Ignored between-clock glitches");
        
        @(negedge clk); a_alarm = 1; 
        repeat (11) @(negedge clk); // Enter Lockout
        
        @(negedge clk); // Downgrade to warnings
        a_alarm = 0; b_alarm = 0; a_warn = 1; b_warn = 1;
        repeat (3) @(negedge clk); 
        check(2'b11, 1, 1, 1, "Lockout overrides warning downgrade");

        $display("\n========================================");
        if (errors == 0)
            $display("VERIFICATION PASSED! Errors: 0");
        else
            $display("VERIFICATION FAILED! Errors: %0d", errors);
        $display("========================================\n");

        @(negedge clk);
        $finish;
    end
    
endmodule