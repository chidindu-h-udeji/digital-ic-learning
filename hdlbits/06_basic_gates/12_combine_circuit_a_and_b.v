module top_module (input x, input y, output z);
    wire a1,b1,a2,b2,one,two;
    A IA1 (.x(x),.y(y),.z(a1));
    B IB1 (.x(x),.y(y),.z(b1));
    A IA2 (.x(x),.y(y),.z(a2));
    B IB2 (.x(x),.y(y),.z(b2));
    assign one = a1|b1;
    assign two = a2&b2;
    assign z = one^two;
    

endmodule

module A (input x, input y, output z);
    assign z = (x^y) & x;

endmodule

module B ( input x, input y, output z );
    assign z = x ~^ y;

endmodule
