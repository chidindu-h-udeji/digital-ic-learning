module top_module();
    
    reg [1:0] in;
    reg out;
    andgate inst1 (.in(in), .out(out));
    
    initial begin   
        in = 0;
        #10;
        in[0] = 1;
        #10;
        in[0] = 0; in[1] = 1;
        #10;
        in[0] = 1;
    end
        

endmodule
