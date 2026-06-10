module top_module(
    input clk,
    input reset,
    input ena,
    output reg pm,
    output reg [7:0] hh,
    output reg [7:0] mm,
    output reg [7:0] ss);
    
    always @ (posedge clk) begin
        if (reset) begin
            ss <= 8'h00;
        end
        else if (ena) begin
            if (ss == 8'h59) begin
                ss <= 8'h00;
            end
            else if (ss[3:0] == 4'h9) begin
                ss <= ss + 8'h07;
            end
            else begin
                ss <= ss + 8'h01;
            end
        end
    end
    
    always @ (posedge clk) begin
        if (reset) begin
            mm <= 8'h00;
        end
        else if (ena && ss == 8'h59) begin
            if (mm == 8'h59) begin
                mm <= 8'h00;
            end
            else if (mm[3:0] == 4'h9) begin
                mm <= mm + 8'h07;
            end
            else begin
                mm <= mm + 1;
            end
        end
    end
    
    always @ (posedge clk) begin
        if (reset) begin
            hh <= 8'h12;
        end
        else if (ena && mm == 8'h59 && ss == 8'h59) begin
            if (hh == 8'h12) begin
                hh <= 8'h01;
            end
            else if (hh[3:0] == 4'h9) begin
                hh <= hh + 8'h07;
            end
            else begin
                hh <= hh + 8'h01;
            end
        end
    end
    
    always @ (posedge clk) begin
        if (reset) begin
            pm <= 1'b0;
        end
        else if (ena && hh == 8'h11 && mm == 8'h59 && ss == 8'h59 ) begin
            pm <= ~pm;
        end
    end

endmodule