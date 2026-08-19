`timescale 1ns/1ps

module forwarding_unit (
  input  logic [4:0] ex_rs1_addr,
  input  logic [4:0] ex_rs2_addr,
  input  logic [4:0] ex_mem_rd_addr,
  input  logic       ex_mem_reg_write,
  input  logic [4:0] mem_wb_rd_addr,
  input  logic       mem_wb_reg_write,
  output logic [1:0] forward_a,
  output logic [1:0] forward_b
);
  
  // Forward A Logic (Operand 1 / rs1)
  assign forward_a = (ex_mem_reg_write && (ex_mem_rd_addr != 0) && (ex_mem_rd_addr == ex_rs1_addr)) ? 2'b10 : ((mem_wb_reg_write && (mem_wb_rd_addr != 0) && (mem_wb_rd_addr == ex_rs1_addr)) ? 2'b01 : 2'b00);
  // Forward B Logic (Operand 2 / rs2)
  assign forward_b = (ex_mem_reg_write && (ex_mem_rd_addr != 0) && (ex_mem_rd_addr == ex_rs2_addr)) ? 2'b10 : ((mem_wb_reg_write && (mem_wb_rd_addr != 0) && (mem_wb_rd_addr == ex_rs2_addr)) ? 2'b01 : 2'b00);
  
endmodule
  