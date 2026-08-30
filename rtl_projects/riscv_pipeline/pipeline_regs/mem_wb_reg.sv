`timescale 1ns/1ps

module mem_wb_reg (
  input  logic        clk,
  input  logic        reset,
  input  logic [31:0] read_data_in,
  input  logic [31:0] alu_result_in,
  input  logic [4:0]  rd_addr_in,
  input  logic        mem_to_reg_in,
  input  logic        reg_write_in,
  output logic [31:0] read_data_out,
  output logic [31:0] alu_result_out,
  output logic [4:0]  rd_addr_out,
  output logic        mem_to_reg_out,
  output logic        reg_write_out
);

  always_ff @(posedge clk) begin
    if (reset) begin
      {read_data_out, alu_result_out, rd_addr_out, mem_to_reg_out, reg_write_out} <= 0;
    end else begin
      read_data_out  <= read_data_in;
      alu_result_out <= alu_result_in;
      rd_addr_out    <= rd_addr_in;
      mem_to_reg_out <= mem_to_reg_in;
      reg_write_out  <= reg_write_in;
    end
  end

endmodule