`timescale 1ns/1ps

module if_id_register (
  input  logic        clk,
  input  logic        reset,
  input  logic        stall,
  input  logic        flush,
  input  logic [31:0] instruction_in,
  input  logic [31:0] pc_in,
  input  logic [31:0] pc_plus4_in,
  output logic [31:0] instruction_out,
  output logic [31:0] pc_out,
  output logic [31:0] pc_plus4_out
);

  always_ff @(posedge clk) begin
    if (reset) begin
      // Priority 1: Reset forces a bubble state
      instruction_out <= 32'h00000013; // NOP (addi x0, x0, 0)
      pc_out          <= 32'h0;
      pc_plus4_out    <= 32'h0;
    end else if (flush) begin
      // Priority 2: Flush discards current instruction (wrong branch path)
      instruction_out <= 32'h00000013; // NOP
      pc_out          <= 32'h0;
      pc_plus4_out    <= 32'h0;
    end else if (stall) begin
      // Priority 3: Stall freezes the pipeline (hazard detected)
      instruction_out <= instruction_out;
      pc_out          <= pc_out;
      pc_plus4_out    <= pc_plus4_out;
    end else begin
      // Default: Normal latch (take a snapshot for the Decode stage)
      instruction_out <= instruction_in;
      pc_out          <= pc_in;
      pc_plus4_out    <= pc_plus4_in;
    end
  end

endmodule