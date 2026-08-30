`timescale 1ns/1ps

module mem_stage (
  input  logic        clk,

  // Inputs from EX/MEM Register
  input  logic [31:0] alu_result_in,
  input  logic [31:0] rs2_data_in,
  input  logic [4:0]  rd_addr_in,
  input  logic        mem_read_in,
  input  logic        mem_write_in,
  input  logic        mem_to_reg_in,
  input  logic        reg_write_in,

  // Outputs to MEM/WB Register
  output logic [31:0] read_data_out,
  output logic [31:0] alu_result_out,
  output logic [4:0]  rd_addr_out,
  output logic        mem_to_reg_out,
  output logic        reg_write_out
);

  // Instantiate the Data Memory
  data_memory dmem (
    .clk(clk),
    .mem_read(mem_read_in),
    .mem_write(mem_write_in),
    .addr(alu_result_in),
    .write_data(rs2_data_in),
    .read_data(read_data_out)
  );

  assign alu_result_out = alu_result_in;
  assign rd_addr_out    = rd_addr_in;
  assign mem_to_reg_out = mem_to_reg_in;
  assign reg_write_out  = reg_write_in;

endmodule