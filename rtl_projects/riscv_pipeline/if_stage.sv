`timescale 1ns/1ps

module if_stage (
  input  logic        clk,
  input  logic        reset,
  input  logic        stall,
  input  logic        branch_taken,
  input  logic [31:0] branch_target,
  output logic [31:0] pc_out,
  output logic [31:0] instruction
);

  // Instantiate PC Logic
  pc_logic pc_inst (
    .clk(clk), 
    .reset(reset), 
    .stall(stall), 
    .branch_taken(branch_taken), 
    .branch_target(branch_target), 
    .pc_out(pc_out)
  );

  // Instantiate Instruction Memory
  instruction_memory imem_inst (
    .addr(pc_out),
    .instruction(instruction)
  );

endmodule