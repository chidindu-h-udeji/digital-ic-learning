module top_module (input a, input b, input c, output out);//
    
    wire i;
    assign out = ~i;

    andgate inst1 (.a(a), .b(b), .c(c), .out(i), .d(1'b1), .e(1'b1) );

endmodule
