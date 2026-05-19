module top_module ( input clk, input d, output q );
    wire jump1,jump2;
    my_dff dff1 (.clk(clk),.d(d),.q(jump1));
    my_dff dff2 (.clk(clk),.d(jump1),.q(jump2));
    my_dff dff3 (.clk(clk),.d(jump2),.q(q));
    

endmodule