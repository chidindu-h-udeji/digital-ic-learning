`timescale 1ns/1ps

module wb_stage (
  input  logic [31:0] read_data_in,
  input  logic [31:0] alu_result_in,
  input  logic [4:0]  rd_addr_in,
  input  logic        mem_to_reg_in,
  input  logic        reg_write_in,
  output logic [31:0] write_back_data,
  output logic [4:0]  rd_addr_out,
  output logic        reg_write_out
);
  
  assign write_back_data = mem_to_reg_in ? read_data_in : alu_result_in;
  assign rd_addr_out     = rd_addr_in;
  assign reg_write_out   = reg_write_in;
  
endmodule