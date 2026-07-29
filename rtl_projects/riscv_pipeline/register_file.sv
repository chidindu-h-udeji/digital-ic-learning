module register_file (
  input  logic        i_clk,
  input  logic        reg_write,
  input  logic [4:0]  rs1_addr,
  input  logic [4:0]  rs2_addr,
  input  logic [4:0]  rd_addr,
  input  logic [31:0] rd_data,
  output logic [31:0] rs1_data,
  output logic [31:0] rs2_data
);

  // 32 registers, each 32 bits wide
  logic [31:0] registers [0:31];

  // Synchronous write: only update if reg_write is high AND not writing to x0
  always_ff @(posedge i_clk) begin
    if (reg_write && (rd_addr != 0))      
      registers[rd_addr] <= rd_data;
  end

  // Combinational read: x0 is always 0. If reading a register during a write to that same register, forward the new data directly.
  assign rs1_data = (rs1_addr == 0) ? 0 : ((reg_write && (rd_addr == rs1_addr)) ? rd_data : registers[rs1_addr]);
  assign rs2_data = (rs2_addr == 0) ? 0 : ((reg_write && (rd_addr == rs2_addr)) ? rd_data : registers[rs2_addr]);

endmodule
			