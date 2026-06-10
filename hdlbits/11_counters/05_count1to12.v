module top_module (
    input clk,
    input reset,
    input enable,
    output [3:0] Q,
    output c_enable,
    output c_load,
    output [3:0] c_d
); //
    wire load;
    assign c_enable = enable;
    assign c_load = load;
    assign c_d = 4'd1;
    assign load = reset | ((Q == 12) & enable);

    count4 the_counter (.clk(clk), .enable(c_enable), .load(c_load), .d(c_d), .Q(Q));

endmodule