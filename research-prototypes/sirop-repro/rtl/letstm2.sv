// letstm2.sv - letstm buffer with two consumers (Hildebrand & Dubach, LCTES '26, Sec. 3-4):
// a circular buffer of capacity K with one read pointer per consumer.
// A new element is accepted only if no consumer is K elements behind,
// so no consumer can read element i + K before all have read element i.
// Not the authors' VHDL entity; written from the paper's description.
module letstm2 #(parameter int W = 16, parameter int K = 1, parameter int PW = 8) (
    input  logic         clk,
    input  logic         rst,
    input  logic [W-1:0] in_data,
    input  logic         in_valid,
    output logic         in_ready,
    output logic [W-1:0] c0_data,
    output logic         c0_valid,
    input  logic         c0_ready,
    output logic [W-1:0] c1_data,
    output logic         c1_valid,
    input  logic         c1_ready
);
    logic [W-1:0]  mem [K];
    logic [PW-1:0] wp, rp0, rp1, rmin;    // element counts, not wrapped

    assign rmin     = (rp0 < rp1) ? rp0 : rp1;
    assign in_ready = (wp - rmin) < K;
    assign c0_valid = (rp0 != wp);
    assign c1_valid = (rp1 != wp);
    assign c0_data  = mem[rp0 % K];
    assign c1_data  = mem[rp1 % K];

    always_ff @(posedge clk) begin
        if (rst) begin
            wp <= '0; rp0 <= '0; rp1 <= '0;
        end else begin
            if (in_valid && in_ready) begin
                mem[wp % K] <= in_data;
                wp <= wp + 1'b1;
            end
            if (c0_valid && c0_ready) rp0 <= rp0 + 1'b1;
            if (c1_valid && c1_ready) rp1 <= rp1 + 1'b1;
        end
    end
endmodule