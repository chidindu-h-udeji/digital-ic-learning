`timescale 1ns/1ps

module id_stage (
  input  logic [31:0] instruction,
  input  logic [31:0] pc,
  input  logic [31:0] rs1_data,
  input  logic [31:0] rs2_data,
  
  output logic [4:0]  rs1_addr,
  output logic [4:0]  rs2_addr,
  output logic [4:0]  rd_addr,
  output logic [31:0] imm_ext,
  output logic [2:0]  funct3,
  output logic [6:0]  funct7,
  output logic [31:0] pc_out,
  output logic [31:0] rs1_data_out,
  output logic [31:0] rs2_data_out,
  
  // Control Signals
  output logic        reg_write,
  output logic        alu_src,
  output logic        mem_read,
  output logic        mem_write,
  output logic        mem_to_reg,
  output logic        branch
);
  
  logic [6:0] opcode;
  
  // 1. Slice the instruction
  assign rs1_addr = instruction[19:15];
  assign rs2_addr = instruction[24:20];
  assign rd_addr  = instruction[11:7];
  assign funct3   = instruction[14:12];
  assign funct7   = instruction[31:25];
  assign opcode   = instruction[6:0];
  
  // 2. Pass-through signals
  assign pc_out       = pc;
  assign rs1_data_out = rs1_data;
  assign rs2_data_out = rs2_data;
  
  // 3. Instantiate Immediate Generator
  imm_gen imm_gen_inst (
    .instruction(instruction), 
    .imm_ext(imm_ext)
  );
  
  // 4. Instantiate Control Unit
  control_unit control_unit_inst (
    .opcode(opcode), 
    .reg_write(reg_write), 
    .alu_src(alu_src), 
    .mem_read(mem_read), 
    .mem_write(mem_write), 
    .mem_to_reg(mem_to_reg), 
    .branch(branch) 
  );

endmodule