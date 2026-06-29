module top_module ();
    reg clk=0, reset, t, q;
    tff inst1 (.clk(clk), .reset(reset), .t(t), .q(q));
    
    always #5 clk = ~clk;
    initial begin
        t = 0; reset = 0;
        @(negedge clk);
        reset = 1;
        @(negedge clk);
        reset = 0; t = 1;
        @(negedge clk);
        t = 0;
    end
        
        
    

endmodule
