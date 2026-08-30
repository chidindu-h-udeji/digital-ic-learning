`timescale 1ns/1ps

module ex_mem_reg (
  input  logic        clk,
  input  logic        reset,
  
  // Data Inputs (from EX)
  input  logic [31:0] alu_result_in,
  input  logic [31:0] rs2_data_in,
  input  logic [4:0]  rd_addr_in,

  // Control Inputs (from EX)
  input  logic        mem_read_in,
  input  logic        mem_write_in,
  input  logic        mem_to_reg_in,
  input  logic        reg_write_in,

  // Data Outputs (to MEM)
  output logic [31:0] alu_result_out,
  output logic [31:0] rs2_data_out,
  output logic [4:0]  rd_addr_out,

  // Control Outputs (to MEM)
  output logic        mem_read_out,
  output logic        mem_write_out,
  output logic        mem_to_reg_out,
  output logic        reg_write_out
);
  
  always_ff @(posedge clk) begin
    if (reset) begin
      {alu_result_out, rs2_data_out, rd_addr_out, mem_read_out, mem_write_out, mem_to_reg_out, reg_write_out} <= 0;
    end else begin
      alu_result_out <= alu_result_in; 
      rs2_data_out   <= rs2_data_in; 
      rd_addr_out    <= rd_addr_in;
      mem_read_out   <= mem_read_in;
      mem_write_out  <= mem_write_in; 
      mem_to_reg_out <= mem_to_reg_in; 
      reg_write_out  <= reg_write_in;
    end
  end
  
endmodule
      
