module top_module();
    
    reg clk = 0, in, out;
    reg [2:0] s;
    q7 inst1 (.clk(clk), .in(in), .s(s), .out(out));
    
    always #5 clk = ~clk;
    initial begin
        in = 0; s = 2;
        @(negedge clk);
        s = 6;
        @(negedge clk);
        in = 1; s = 2;
        @(negedge clk);
        in = 0; s = 7;
        @(negedge clk);
        in = 1; s = 0;        
        @(negedge clk);
        in = 1;
        @(negedge clk);
        in = 1;
        @(negedge clk);
        in = 0;
    end 

endmodule
