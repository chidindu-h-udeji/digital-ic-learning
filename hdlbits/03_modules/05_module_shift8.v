module top_module ( 
    input clk, 
    input [7:0] d, 
    input [1:0] sel, 
    output [7:0] q 
);
    wire [7:0] jump1,jump2,jump3;
    my_dff8 ff1 (.clk(clk),.d(d),.q(jump1));
    my_dff8 ff2 (.clk(clk),.d(jump1),.q(jump2));
    my_dff8 ff3 (.clk(clk),.d(jump2),.q(jump3));
                 assign q = (sel == 2'b00) ? d : 
                     (sel == 2'b01) ? jump1 : 
                     (sel == 2'b10) ? jump2 : 
                     jump3;

endmodule