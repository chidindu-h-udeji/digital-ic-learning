`timescale 1ns/1ps

module id_ex_reg (
  // Hardware Control Inputs
  input  logic        clk,
  input  logic        reset,
  input  logic        flush,
  input  logic        stall,

  // Data Payload (Inputs from Decode)
  input  logic [31:0] pc_in,
  input  logic [31:0] rs1_data_in,
  input  logic [31:0] rs2_data_in,
  input  logic [31:0] imm_ext_in,
  input  logic [4:0]  rs1_addr_in,
  input  logic [4:0]  rs2_addr_in,
  input  logic [4:0]  rd_addr_in,
  input  logic [2:0]  funct3_in,
  input  logic [6:0]  funct7_in,
  input  logic [6:0]  opcode_in,

  // Control Payload (Inputs from Decode)
  input  logic        reg_write_in,
  input  logic        alu_src_in,
  input  logic        mem_read_in,
  input  logic        mem_write_in,
  input  logic        mem_to_reg_in,
  input  logic        branch_in,

  // Data Payload (Outputs to Execute)
  output logic [31:0] pc_out,
  output logic [31:0] rs1_data_out,
  output logic [31:0] rs2_data_out,
  output logic [31:0] imm_ext_out,
  output logic [4:0]  rs1_addr_out,
  output logic [4:0]  rs2_addr_out,
  output logic [4:0]  rd_addr_out,
  output logic [2:0]  funct3_out,
  output logic [6:0]  funct7_out,
  output logic [6:0]  opcode_out,

  // 5. Control Payload (Outputs to Execute)
  output logic        reg_write_out,
  output logic        alu_src_out,
  output logic        mem_read_out,
  output logic        mem_write_out,
  output logic        mem_to_reg_out,
  output logic        branch_out
);

  always @(posedge clk) begin
    if (reset) begin
      {pc_out, rs1_data_out, rs2_data_out, imm_ext_out, rs1_addr_out, rs2_addr_out, rd_addr_out, funct3_out, funct7_out, opcode_out} <= 0;
      {reg_write_out, alu_src_out, mem_read_out, mem_write_out, mem_to_reg_out, branch_out} <= 0;
    
    end else if (flush) begin
      // Zeroing controls to neutralize instruction
      {reg_write_out, alu_src_out, mem_read_out, mem_write_out, mem_to_reg_out, branch_out} <= 0;
    
    end else if (stall) begin
      // Do nothing to implicitly hold
    
    end else begin
      // Pass data payload forward
      pc_out       <= pc_in;
      rs1_data_out <= rs1_data_in;
      rs2_data_out <= rs2_data_in;
      imm_ext_out  <= imm_ext_in; 
      rs1_addr_out <= rs1_addr_in;
      rs2_addr_out <= rs2_addr_in;
      rd_addr_out  <= rd_addr_in;
      funct3_out   <= funct3_in;
      funct7_out   <= funct7_in;
      opcode_out   <= opcode_in;
      
      // Pass control payload forward
      reg_write_out  <= reg_write_in;
      alu_src_out    <= alu_src_in;
      mem_read_out   <= mem_read_in;
      mem_write_out  <= mem_write_in;
      mem_to_reg_out <= mem_to_reg_in;
      branch_out     <= branch_in;
    end
  end

endmodule