module top_module(
    input clk,
    input load,
    input [255:0] data,
    output reg [255:0] q );

    logic [15:0][15:0] grid, ngrid;
    assign grid = q;
    
    integer r, c, sum, up, down, left, right;

    always @(*) begin
        for (r = 0; r < 16; r = r + 1) begin
            for (c = 0; c < 16; c = c + 1) begin
                up    = (r == 0)  ? 15 : r - 1;
                down  = (r == 15) ? 0  : r + 1;
                left  = (c == 0)  ? 15 : c - 1;
                right = (c == 15) ? 0  : c + 1;

                sum = grid[up][left] + grid[up][c] + grid[up][right] + grid[r][left] + grid[r][right] + grid[down][left] + grid[down][c] + grid[down][right];
                
                if (sum == 2)
                    ngrid[r][c] = grid[r][c];
                else if (sum == 3)
                    ngrid[r][c] = 1'b1;
                else
                    ngrid[r][c] = 1'b0;
            end
        end
    end
    
    
    always @(posedge clk) begin
        if (load)
            q <= data;         
        else
            q <= ngrid;    
    end

endmodule