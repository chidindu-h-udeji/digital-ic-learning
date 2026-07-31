`timescale 1ns/1ps

module pc_logic (
  input  logic        clk,
  input  logic        reset,
  input  logic        stall,
  input  logic        branch_taken,
  input  logic [31:0] branch_target,
  output logic [31:0] pc_out
);

  // Internal wire for next sequential PC
  logic [31:0] pc_plus_4;

  // Synchronous PC register with priority multiplexer
  always_ff @(posedge clk) begin
    if (reset) begin
      pc_out <= 32'h0;
    end else if (branch_taken) begin
      pc_out <= branch_target;  // Branch overrides stall
    end else if (stall) begin
      pc_out <= pc_out;         // Hold current value
    end else begin
      pc_out <= pc_plus_4;      // Default: advance by 4 bytes
    end
  end

  // Combinational adder: physically separate from the sequential register
  assign pc_plus_4 = pc_out + 4; 

endmodule