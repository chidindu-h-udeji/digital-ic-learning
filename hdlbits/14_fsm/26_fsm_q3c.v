module top_module (
    input clk,
    input [2:0] y,
    input x,
    output Y0,
    output z
);
    
    assign z = (&{~y[2],y[1],y[0]}) | (&{y[2],~y[1],~y[0]});
    assign Y0 = (&{~y[2],~y[1],~y[0],x}) | (&{~y[2],~y[1],y[0],~x}) | (&{~y[2],y[1],~y[0],x}) | (&{~y[2],y[1],y[0],~x}) | (&{y[2],~y[1],~y[0],~x});

endmodule