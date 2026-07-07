`timescale 1ns/1ps

module tb_safety_monitor;
    reg        clk=0, reset; 
    reg        a_warn, a_alarm, b_warn, b_alarm; 
    wire [1:0] alert_level; 
    wire       shutoff, buzzer, fault_detected;
    
    safety_monitor dut (
        .clk(clk), .reset(reset), 
        .a_warn(a_warn), .a_alarm(a_alarm), .b_warn(b_warn), .b_alarm(b_alarm), 
        .alert_level(alert_level), 
        .shutoff(shutoff), 
        .buzzer(buzzer), 
        .fault_detected(fault_detected)
    );
    
    always #5 clk = ~clk;  
    initial begin
        $dumpfile("tb_safety_monitor.vcd");
        $dumpvars(0, tb_safety_monitor);
        
        // --- Batch 1: Normal Ops & Warnings ---
        reset=1; a_warn=0; a_alarm=0; b_warn=0; b_alarm=0;
        @(posedge clk);
        reset = 0;
        
        @(negedge clk); a_warn = 1;
        @(negedge clk); a_warn = 0;
        @(negedge clk); b_warn = 1;

        // --- Batch 2: Alarms & Lockout ---
        
        // Trigger Alarm
        @(negedge clk); 
        a_alarm = 1;
        
        // Trigger Critical Fault (Both Alarms)
        @(negedge clk);
        b_alarm = 1;
        repeat (12) @(negedge clk); // Wait for 10-cycle counter

        // Verify Lockout persists when sensors clear
        @(negedge clk);
        a_alarm = 0; b_alarm = 0; a_warn = 0; b_warn = 0;
        repeat (3) @(negedge clk);

        // Manual Reset
        @(negedge clk);
        reset = 1;
        @(negedge clk);
        reset = 0;

        // --- Batch 3: Edge Cases & Priority ---
        
        // Simultaneous Warning & Alarm
        @(negedge clk);
        a_warn = 1; a_alarm = 1; // Expect jump to ALARM
        
        // Glitch Immunity
        @(negedge clk);
        a_warn = 0; a_alarm = 0; b_alarm = 1; 
        #2 a_alarm = 1; // Glitch high
        #2 a_alarm = 0; // Glitch drops before clock edge
        
        // Lockout Priority over Warnings
        @(negedge clk);
        a_alarm = 1; 
        repeat (12) @(negedge clk); // Enter LOCKOUT
        
        // Downgrade to warnings
        @(negedge clk);
        a_alarm = 0; b_alarm = 0;
        a_warn = 1; b_warn = 1;
        repeat (3) @(negedge clk); // Must remain in LOCKOUT

        @(negedge clk);
        $finish;
    end
    
endmodule